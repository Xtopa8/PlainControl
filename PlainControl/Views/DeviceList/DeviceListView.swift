import SwiftUI
struct DeviceListView: View {
    @EnvironmentObject var a: AppState; @State private var showAdd = false
    var body: some View {
        NavigationStack {
            List { ForEach(a.devices) { d in DeviceRowView(device: d, status: d.isOnline ? .online : .offline,
                onTap: { a.setActive(d) }, onDelete: { a.removeDevice(id: d.id) },
                onRename: { n in if let i = a.devices.firstIndex(where: {$0.id==d.id}) {a.devices[i].name=n; a.save()} }))
            }
            .navigationTitle("Devices")
            .toolbar { Button { showAdd=true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showAdd) { AddDeviceView() }
        }
    }
}
