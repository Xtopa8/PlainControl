import SwiftUI
struct DeviceControlView: View {
    @EnvironmentObject var a: AppState
    var body: some View {
        VStack(spacing: 20) {
            if let d = a.activeDevice {
                Image(systemName: "display").font(.system(size: 48))
                Text(d.name).font(.title2)
                Text(d.primaryIP ?? "No IP").font(.caption).foregroundStyle(.secondary)
                Button("Disconnect") { a.activeDevice = nil; a.connectionState = .disconnected }
            } else {
                Image(systemName: "display").font(.system(size: 48)).foregroundStyle(.secondary)
                Text("No Active Device").font(.title2)
                Text("Select a device from the Devices tab.").foregroundStyle(.secondary)
            }
        }
    }
}
