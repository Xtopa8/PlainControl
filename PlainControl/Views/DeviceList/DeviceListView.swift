import SwiftUI
struct DeviceListView: View {
    @EnvironmentObject var s: AppState; @State private var showAdd=false
    var body: some View {
        NavigationStack{
            List{ForEach(s.devices){d in DeviceRowView(device:d,onTap:{s.activeDevice=d},onDelete:{s.remove(d)})}}
            .navigationTitle("Devices")
            .toolbar{Button{showAdd=true}label:{Image(systemName:"plus")}}
            .sheet(isPresented:$showAdd){AddDeviceView()}
        }
    }
}
struct DeviceRowView: View {
    let device: PlainDevice; let onTap: ()->Void; let onDelete: ()->Void
    var body: some View {
        Button(action:onTap){
            HStack{
                VStack(alignment:.leading){
                    Text(device.name).font(.body).fontWeight(.medium)
                    Text("\(device.ip):\(device.port)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Circle().fill(device.isOnline ? Color.green:Color.gray).frame(width:10,height:10)
            }
        }
        .buttonStyle(.plain)
        .contextMenu{Button(role:.destructive){onDelete()}label:{Label("Delete",systemImage:"trash")}}
    }
}
