import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(onlineDevices) { device in
                    DeviceRowView(device: device, status: .online, onTap: {
                        appState.setActiveDevice(device)
                    }, onDelete: { appState.removeDevice(device) }, onRename: { name in
                        if let i = appState.devices.firstIndex(where: { $0.id == device.id }) {
                            appState.devices[i].name = name; appState.saveDevices()
                        }
                    })
                }
                ForEach(offlineDevices) { device in
                    DeviceRowView(device: device, status: .offline, onTap: {
                        appState.setActiveDevice(device)
                    }, onDelete: { appState.removeDevice(device) }, onRename: { name in
                        if let i = appState.devices.firstIndex(where: { $0.id == device.id }) {
                            appState.devices[i].name = name; appState.saveDevices()
                        }
                    })
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showAdd) { AddDeviceView() }
        }
    }

    private var onlineDevices: [PlainDevice] { appState.devices.filter { $0.isOnline } }
    private var offlineDevices: [PlainDevice] { appState.devices.filter { !$0.isOnline } }
}
