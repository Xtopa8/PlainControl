import Foundation
import SwiftUI
import WebKit

/// View model for the device control screen.
///
/// Manages the WKWebView state, device connection URL, and toolbar actions.
@MainActor
final class DeviceControlViewModel: ObservableObject {
    // MARK: - Published

    /// The URL to load in the WKWebView.
    @Published var deviceURL: URL?

    /// Connection state for the active device.
    @Published var connectionState: ConnectionState = .disconnected

    /// Whether the web page is currently loading.
    @Published var isLoading: Bool = false

    /// Estimated loading progress (0.0 to 1.0).
    @Published var loadingProgress: Double = 0.0

    /// Page title from the active device's web UI.
    @Published var pageTitle: String = ""

    /// Whether to show the device picker sheet.
    @Published var showDevicePicker: Bool = false

    /// Error message to display.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let connectionManager: ConnectionManager
    private let appState: AppState

    // MARK: - Init

    init(connectionManager: ConnectionManager, appState: AppState) {
        self.connectionManager = connectionManager
        self.appState = appState
        updateDeviceURL()
    }

    // MARK: - Actions

    /// Update the WebView URL from the active device.
    func updateDeviceURL() {
        guard let device = appState.activeDevice else {
            deviceURL = nil
            return
        }

        // Try the connection URL
        if let url = device.connectionURL {
            deviceURL = url
        } else if let ip = device.getIPs().first {
            // Fallback: construct URL from first IP
            let scheme = device.httpsPort > 0 ? "https" : "http"
            let port = device.httpsPort > 0 ? device.httpsPort : device.httpPort
            deviceURL = URL(string: "\(scheme)://\(ip):\(port)/")
        }
    }

    /// Reload the current page.
    func reload() {
        // The WebView coordinator will handle this via the reload action
        connectionState = .connected
        errorMessage = nil
    }

    /// Switch to a different device.
    func switchToDevice(_ device: PlainDevice) {
        Task {
            do {
                try await connectionManager.connect(to: device)
                appState.activeDevice = device
                updateDeviceURL()
                connectionState = .connected
                errorMessage = nil
            } catch {
                connectionState = .error(.unknown(error.localizedDescription))
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Disconnect from the current device.
    func disconnect() {
        connectionManager.disconnect()
        connectionState = .disconnected
        deviceURL = nil
        pageTitle = ""
    }

    /// Called when the WebView starts loading.
    func didStartLoading() {
        isLoading = true
        loadingProgress = 0.0
    }

    /// Called when WebView loading progress updates.
    func didUpdateProgress(_ progress: Double) {
        loadingProgress = min(progress, 1.0)
    }

    /// Called when the WebView finishes loading.
    func didFinishLoading() {
        isLoading = false
        loadingProgress = 1.0
        connectionState = .connected
    }

    /// Called when the WebView fails to load.
    func didFailLoading(with error: Error) {
        isLoading = false
        loadingProgress = 0.0
        connectionState = .error(.unknown(error.localizedDescription))
        errorMessage = error.localizedDescription
    }
}
