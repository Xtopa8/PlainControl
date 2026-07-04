import Foundation
import SwiftUI

/// View model for the device list screen.
@MainActor
final class DeviceListViewModel: ObservableObject {
    // MARK: - Published

    /// All saved devices.
    @Published var devices: [PlainDevice] = []

    /// Whether to show the add device sheet.
    @Published var showAddDevice: Bool = false

    /// Device pending deletion confirmation.
    @Published var deviceToDelete: PlainDevice?

    /// Error message.
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let deviceRepository: DeviceRepository
    private let connectionManager: ConnectionManager
    private let appState: AppState

    // MARK: - Init

    init(
        deviceRepository: DeviceRepository,
        connectionManager: ConnectionManager,
        appState: AppState
    ) {
        self.deviceRepository = deviceRepository
        self.connectionManager = connectionManager
        self.appState = appState
    }

    // MARK: - Actions

    /// Load devices from the repository.
    func loadDevices() {
        do {
            devices = try deviceRepository.fetchAll()
            // Sync online status from app state
            for device in devices {
                device.isOnline = appState.onlineDeviceIDs.contains(device.id)
            }
        } catch {
            errorMessage = "Failed to load devices: \(error.localizedDescription)"
        }
    }

    /// Select and connect to a device.
    func selectDevice(_ device: PlainDevice) async {
        do {
            try deviceRepository.setActive(device)
            try await connectionManager.connect(to: device)
            appState.activeDevice = device
            appState.connectionState = .connected
        } catch {
            appState.connectionState = .error(.unknown(error.localizedDescription))
            errorMessage = error.localizedDescription
        }
    }

    /// Disconnect from the active device.
    func disconnectActiveDevice() {
        connectionManager.disconnect()
        appState.activeDevice = nil
        appState.connectionState = .disconnected
    }

    /// Delete a device (with confirmation).
    func confirmDelete(_ device: PlainDevice) {
        deviceToDelete = device
    }

    /// Execute the confirmed deletion.
    func deleteDevice() {
        guard let device = deviceToDelete else { return }
        do {
            if device.isActive {
                disconnectActiveDevice()
            }
            try deviceRepository.delete(device)
            deviceToDelete = nil
            loadDevices()
        } catch {
            errorMessage = "Failed to delete device: \(error.localizedDescription)"
        }
    }

    /// Cancel deletion.
    func cancelDelete() {
        deviceToDelete = nil
    }

    /// Rename a device.
    func renameDevice(_ device: PlainDevice, to newName: String) {
        do {
            try deviceRepository.rename(device, to: newName)
            loadDevices()
        } catch {
            errorMessage = "Failed to rename device: \(error.localizedDescription)"
        }
    }

    /// Get the status for a device.
    func status(for device: PlainDevice) -> DeviceStatus {
        if device.isActive {
            switch appState.connectionState {
            case .connected: return .online
            case .connecting: return .connecting
            case .error: return .error
            case .disconnected: return .offline
            }
        }
        return device.isOnline ? .online : .offline
    }
}
