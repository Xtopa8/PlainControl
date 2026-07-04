import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.devices) { device in
                    DeviceRowView(device: device, status: device.isOnline ? .online : .offline,
                        onTap: { appState.setActiveDevice(device) },
                        onDelete: { appState.removeDevice(device) },
                        onRename: { name in
                            if let i = appState.devices.firstIndex(where: {$0.id == device.id}) {
                                appState.devices[i].name = name; appState.saveDevices()
                            }
                        })
                }
            }
            .navigationTitle("Devices")
        }
    }
}
