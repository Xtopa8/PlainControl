import SwiftUI

struct DeviceRowView: View {
    let device: PlainDevice
    let status: DeviceStatus
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var showRename = false
    @State private var newName = ""

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                DeviceIconView(deviceType: device.deviceType)
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name).font(.body).fontWeight(.medium).lineLimit(1)
                    HStack(spacing: 8) {
                        StatusBadge(status: status)
                        if let ip = device.primaryIP {
                            Text(ip).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(device.platform.capitalized).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { newName = device.name; showRename = true } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Rename Device", isPresented: $showRename) {
            TextField("Device Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") { onRename(newName) }
        } message: {
            Text("Enter a new name for \(device.name).")
        }
    }
}
