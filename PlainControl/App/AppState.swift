import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var activeDevice: PlainDevice?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var devices: [PlainDevice] = []
    @Published var errorMessage: String?

    private let key = "pc_devices"

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([PlainDevice].self, from: d) { devices = arr }
    }

    func save() {
        if let d = try? JSONEncoder().encode(devices) { UserDefaults.standard.set(d, forKey: key) }
    }

    func addDevice(_ d: PlainDevice) { devices.append(d); save() }
    func removeDevice(id: String) { devices.removeAll{$0.id==id}; if activeDevice?.id==id {activeDevice=nil}; save() }
    func setActive(_ d: PlainDevice) {
        for i in devices.indices { devices[i].isActive = (devices[i].id == d.id) }
        activeDevice = d; save()
    }
}
