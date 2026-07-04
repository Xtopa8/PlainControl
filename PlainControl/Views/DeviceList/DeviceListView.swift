import SwiftUI
import SwiftData

struct DeviceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlainDevice.lastSeen, order: .reverse) private var devices: [PlainDevice]
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(devices, id: \.id) { device in
                    DeviceRowView(
                        device: device,
                        status: device.isOnline ? .online : .offline,
                        onTap: {},
                        onDelete: {},
                        onRename: { _ in }
                    )
                }
            }
            .navigationTitle("Devices")
            .toolbar { Button { showAdd = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showAdd) { AddDeviceView() }
        }
    }
}
