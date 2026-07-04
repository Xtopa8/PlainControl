import SwiftUI

/// A single device row in the device list.
struct DeviceRowView: View {
    let device: PlainDevice
    let status: DeviceStatus
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var showRenameAlert: Bool = false
    @State private var newName: String = ""

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                DeviceIconView(deviceType: device.deviceType)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(device.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if device.isActive {
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(.accent)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        StatusBadge(status: status)

                        if let ip = device.primaryIP {
                            Text(ip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(device.platform.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let lastSeen = device.lastConnectedAt {
                        Text(lastSeen, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                newName = device.name
                showRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Rename Device", isPresented: $showRenameAlert) {
            TextField("Device Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                onRename(newName)
            }
        } message: {
            Text("Enter a new name for \(device.name).")
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        DeviceRowView(
            device: PlainDevice(
                id: "preview-1",
                name: "My Phone",
                ips: ["192.168.1.100"],
                httpsPort: 8443,
                deviceType: "phone",
                platform: "android",
                version: "1.8.0",
                isOnline: true,
                isActive: true
            ),
            status: .online,
            onTap: {},
            onDelete: {},
            onRename: { _ in }
        )
        DeviceRowView(
            device: PlainDevice(
                id: "preview-2",
                name: "Test Tablet",
                ips: ["192.168.1.101"],
                httpsPort: 8443,
                deviceType: "tablet",
                platform: "android",
                version: "1.7.5",
                isOnline: false
            ),
            status: .offline,
            onTap: {},
            onDelete: {},
            onRename: { _ in }
        )
    }
}
