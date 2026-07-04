import Foundation
import SwiftUI

/// Global application state, observable across all views.
///
/// Tracks the currently active device, discovery status, and
/// global connection state for the entire app.
@MainActor
final class AppState: ObservableObject {
    /// The currently selected/active device being controlled.
    @Published var activeDevice: PlainDevice?

    /// Whether UDP discovery scan is currently running.
    @Published var isScanning: Bool = false

    /// Global connection state for the active device.
    @Published var connectionState: ConnectionState = .disconnected

    /// Error message to display globally (e.g., as a banner).
    @Published var globalErrorMessage: String?

    /// The set of online device IDs (updated by ConnectionManager health checks).
    @Published var onlineDeviceIDs: Set<String> = []

    /// Currently discovered devices during a scan session (not persisted).
    @Published var discoveredDevices: [DiscoverReply] = []

    // MARK: - Computed

    /// Whether there is an active device currently connected.
    var isConnected: Bool {
        connectionState == .connected
    }

    /// Whether the active device is in a transitional state.
    var isTransitioning: Bool {
        connectionState == .connecting
    }

    // MARK: - Actions

    /// Clear the global error message.
    func clearError() {
        globalErrorMessage = nil
    }

    /// Set a global error with auto-dismiss.
    func setError(_ message: String, dismissAfter seconds: TimeInterval = 5) {
        globalErrorMessage = message
        Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if globalErrorMessage == message {
                globalErrorMessage = nil
            }
        }
    }

    /// Add discovered devices to the current scan session.
    func addDiscoveredDevices(_ replies: [DiscoverReply]) {
        for reply in replies {
            if !discoveredDevices.contains(where: { $0.id == reply.id }) {
                discoveredDevices.append(reply)
            }
        }
    }

    /// Clear the current scan session results.
    func clearDiscoveredDevices() {
        discoveredDevices.removeAll()
    }

    /// Update online status for a device.
    func setDeviceOnline(_ deviceId: String, online: Bool) {
        if online {
            onlineDeviceIDs.insert(deviceId)
        } else {
            onlineDeviceIDs.remove(deviceId)
        }
    }
}
