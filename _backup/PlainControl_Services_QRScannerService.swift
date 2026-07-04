import Foundation
import AVFoundation
import SwiftUI

/// Service for scanning QR codes using the device camera.
///
/// Used to scan PlainApp pairing QR codes which contain the device URL:
/// `https://<ip>:<port>/` or a custom `plainapp://` scheme URL.
final class QRScannerService: NSObject, ObservableObject {
    // MARK: - Published State

    /// The scanned QR code value (device URL).
    @Published var scannedValue: String?

    /// Whether the camera is currently scanning.
    @Published var isScanning: Bool = false

    /// Error message if camera access is denied.
    @Published var errorMessage: String?

    /// The capture session (exposed for preview layer).
    let captureSession = AVCaptureSession()

    // MARK: - Private

    private var metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "com.plaincontrol.qrscan")

    // MARK: - Public API

    /// Request camera permission and start scanning.
    func startScanning() {
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }

    /// Stop scanning and release camera resources.
    func stopScanning() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            Task { @MainActor in
                self.isScanning = false
            }
        }
    }

    /// Reset the scanned value (e.g., after handling the result).
    func resetScannedValue() {
        scannedValue = nil
    }

    // MARK: - Setup

    private func setupCaptureSession() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.sessionQueue.async { self?.configureSession() }
                } else {
                    Task { @MainActor in
                        self?.errorMessage = "Camera access is required to scan QR codes."
                    }
                }
            }
            return
        case .denied, .restricted:
            Task { @MainActor in
                errorMessage = "Camera access denied. Enable it in Settings > Privacy > Camera."
            }
            return
        @unknown default:
            return
        }

        configureSession()
    }

    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Find the back camera
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            Task { @MainActor in
                errorMessage = "No camera available."
            }
            captureSession.commitConfiguration()
            return
        }

        // Add input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession.canAddInput(input) else {
                throw NSError(domain: "QRScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
            }
            captureSession.addInput(input)
        } catch {
            Task { @MainActor in
                errorMessage = "Camera setup failed: \(error.localizedDescription)"
            }
            captureSession.commitConfiguration()
            return
        }

        // Add metadata output for QR codes
        guard captureSession.canAddOutput(metadataOutput) else {
            Task { @MainActor in
                errorMessage = "Cannot add metadata output."
            }
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        metadataOutput.metadataObjectTypes = [.qr]

        captureSession.commitConfiguration()

        // Start running
        captureSession.startRunning()

        Task { @MainActor in
            isScanning = true
            errorMessage = nil
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let value = metadataObject.stringValue,
              !value.isEmpty else {
            return
        }

        // Found a QR code — publish and stop scanning
        Task { @MainActor in
            scannedValue = value
            stopScanning()
        }
    }
}
