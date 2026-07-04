import SwiftUI
final class AppState: ObservableObject {
    @Published var devices: [PlainDevice] = []
    @Published var activeDevice: PlainDevice?
    @Published var connectionState: String = "disconnected"
    private let k = "pc_devs"
    init() { load() }
    func load() { if let d=UserDefaults.standard.data(forKey:k),let a=try?JSONDecoder().decode([PlainDevice].self,from:d){devices=a} }
    func save() { if let d=try?JSONEncoder().encode(devices){UserDefaults.standard.set(d,forKey:k)} }
    func add(_ d:PlainDevice){devices.append(d);save()}
    func remove(_ d:PlainDevice){devices.removeAll{$0.id==d.id};if activeDevice?.id==d.id{activeDevice=nil};save()}
}
