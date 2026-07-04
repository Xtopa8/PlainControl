import Foundation
import SwiftUI

/// View model for the Add Device flow.
///
/// Manages discovery scan state, manual entry, and QR scanning.
@MainActor
final class AddDeviceViewModel: ObservableObject {
    // MARK: - Published

    /// Available tabs in the add device flow.
    @Published var selectedTab: AddDeviceTab = .scan

    /// Devices discovered during the current scan.
    @Published var discoveredDevices: [DiscoverReply] = []

    /// Whether a scan is in progress.
    @Published var isScanning: Bool = false

    /// Manual entry fields.
    @Published var manualHost: String = ""
    @Published var manualPort: String = "8443"

    /// Error message.
    @Published var errorMessage: String?

    /// Loading state (probing device).
    @Published var isLoading: Bool = false

    /// Whether to show the QR scanner.
    @Published var showQRScanner: Bool = false

    /// The device selected to connect to.
    @Published var selectedDevice: DiscoverReply?

    // MARK: - Dependencies

    private let discoveryService = DiscoveryService()
    private let deviceRepository: DeviceRepository
    private let connectionManager: ConnectionManager

    // MARK: - Init

    init(deviceRepository: DeviceRepository, connectionManager: ConnectionManager) {
        self.deviceRepository = deviceRepository
        self.connectionManager = connectionManager
    }

    // MARK: - Actions

    /// Start scanning for devices.
    func startScan() {
        errorMessage = nil
        discoveredDevices = discoveryService.discoveredDevices
        discoveryService.onDeviceSelected = { [weak self] reply in
            Task { @MainActor in
                self?.selectedDevice = reply
            }
        }
        discoveryService.startScan()
        isScanning = true

        // Observe changes
        Task {
            // Poll for discovered devices while scanning
            while discoveryService.isScanning {
                discoveredDevices = discoveryService.discoveredDevices
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            isScanning = discoveryService.isScanning
            discoveredDevices = discoveryService.discoveredDevices
        }
    }

    /// Stop scanning.
    func stopScan() {
        discoveryService.stopScan()
        isScanning = false
    }

    /// Connect to a discovered device.
    func connectToDevice(_ reply: DiscoverReply) async {
        isLoading = true
        errorMessage = nil

        do {
            // Save the device to the repository
            let device = try deviceRepository.upsert(from: reply)

            // Set as active and connect
            try deviceRepository.setActive(device)
            try await connectionManager.connect(to: device)

            selectedDevice = reply
        } catch {
            errorMessage = "Failed to connect: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Add a device via manual IP:port entry.
    func addManualDevice() async {
        guard !manualHost.isEmpty else {
            errorMessage = "Please enter an IP address or hostname."
            return
        }
        guard let port = Int(manualPort), port > 0, port <= 65535 else {
            errorMessage = "Please enter a valid port (1-65535)."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let reply = try await discoveryService.addManualDevice(ip: manualHost, port: port)
            await connectToDevice(reply)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Handle a scanned QR code value.
    func handleQRCode(_ value: String) {
        // Try to parse as URL
        if let url = URL(string: value),
           let host = url.host,
           let port = url.port {
            manualHost = host
            manualPort = "\(port)"
            selectedTab = .manual
        } else if value.hasPrefix("plainapp://") {
            // Handle custom scheme
            let stripped = value.replacingOccurrences(of: "plainapp://", with: "")
            let parts = stripped.components(separatedBy: ":")
            if parts.count == 2 {
                manualHost = parts[0]
                manualPort = parts[1]
                selectedTab = .manual
            } else {
                errorMessage = "Invalid QR code format."
            }
        } else {
            errorMessage = "Could not parse QR code as a device URL."
        }
    }
}

// MARK: - Types

enum AddDeviceTab: String, CaseIterable {
    case scan = "Scan"
    case manual = "Manual"
    case qr = "QR Code"

    var icon: String {
        switch self {
        case .scan: return "antenna.radiowaves.left.and.right"
        case .manual: return "keyboard"
        case .qr: return "qrcode.viewfinder"
        }
    }
}
