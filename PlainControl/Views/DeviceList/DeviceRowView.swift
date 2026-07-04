import SwiftUI
struct DeviceRowView: View {
    let device: PlainDevice; let status: DeviceStatus
    let onTap: () -> Void; let onDelete: () -> Void; let onRename: (String) -> Void
    @State private var showRename = false; @State private var name = ""
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(device.name).font(.body).fontWeight(.medium)
                    if let ip = device.primaryIP { Text(ip).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                Circle().fill(status == .online ? Color.green : Color.gray).frame(width: 10, height: 10)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { name=device.name; showRename=true } label: { Label("Rename", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
        }
        .alert("Rename", isPresented: $showRename) {
            TextField("Name", text: $name)
            Button("Cancel", role: .cancel) {}; Button("Save") { onRename(name) }
        }
    }
}
