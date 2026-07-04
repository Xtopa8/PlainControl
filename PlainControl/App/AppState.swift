import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var activeDevice: PlainDevice?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var globalErrorMessage: String?
    @Published var devices: [PlainDevice] = []
    @Published var discoveredDevices: [DiscoverReply] = []

    private let storageKey = "plaincontrol_devices"

    init() { loadDevices() }

    func loadDevices() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let d = try? JSONDecoder().decode([PlainDevice].self, from: data) else { devices = []; return }
        devices = d
    }

    func saveDevices() {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addOrUpdateDevice(_ device: PlainDevice) {
        if let i = devices.firstIndex(where: { $0.id == device.id }) { devices[i] = device }
        else { devices.append(device) }
        saveDevices()
    }

    func upsertDevice(from reply: DiscoverReply) -> PlainDevice {
        if let i = devices.firstIndex(where: { $0.id == reply.id }) {
            var d = devices[i]; d.name = reply.name
            if !reply.ips.isEmpty { d.ips = reply.ips }
            d.httpsPort = reply.port; d.lastSeen = .now; d.isOnline = true
            devices[i] = d; saveDevices(); return d
        }
        let d = PlainDevice(from: reply); devices.append(d); saveDevices(); return d
    }

    func removeDevice(_ device: PlainDevice) {
        devices.removeAll { $0.id == device.id }
        if activeDevice?.id == device.id { activeDevice = nil }
        saveDevices()
    }

    func removeDevice(id: String) {
        devices.removeAll { $0.id == id }
        if activeDevice?.id == id { activeDevice = nil }
        saveDevices()
    }

    func setActiveDevice(_ device: PlainDevice) {
        for i in devices.indices { devices[i].isActive = (devices[i].id == device.id) }
        activeDevice = device; saveDevices()
    }

    func clearError() { globalErrorMessage = nil }
    func setError(_ msg: String) { globalErrorMessage = msg }
    func setDeviceOnline(_ id: String, online: Bool) {
        if let i = devices.firstIndex(where: { $0.id == id }) {
            devices[i].isOnline = online
            if online { devices[i].lastSeen = .now }
            saveDevices()
        }
    }
}
