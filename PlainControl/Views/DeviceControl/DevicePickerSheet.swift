import SwiftUI
import SwiftData

/// A bottom sheet that displays all saved devices for quick switching.
///
/// The user can tap a device to switch the active control target.
/// The currently active device is highlighted.
struct DevicePickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var devices: [PlainDevice] = []
    @State private var isSwitching: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if devices.isEmpty {
                    emptyView
                } else {
                    deviceList
                }
            }
            .navigationTitle("Switch Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadDevices()
            }
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "iphone.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Saved Devices")
                .font(.title3)
            Text("Add devices from the Devices tab first.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Device List

    private var deviceList: some View {
        List {
            // Online devices
            Section("Online") {
                ForEach(onlineDevices, id: \.id) { device in
                    deviceRow(device)
                }
            }

            // Offline devices
            if offlineDevices.isNotEmpty {
                Section("Offline") {
                    ForEach(offlineDevices, id: \.id) { device in
                        deviceRow(device)
                    }
                }
            }
        }
    }

    private func deviceRow(_ device: PlainDevice) -> some View {
        Button {
            switchToDevice(device)
        } label: {
            HStack(spacing: 14) {
                DeviceIconView(deviceType: device.deviceType, size: 36)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(device.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if device.id == appState.activeDevice?.id {
                            Text("Current")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(.accent)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        StatusBadge(status: device.isOnline ? .online : .offline)

                        if let ip = device.primaryIP {
                            Text(ip)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if isSwitching && device.id == appState.activeDevice?.id {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .disabled(isSwitching)
    }

    // MARK: - Computed

    private var onlineDevices: [PlainDevice] {
        devices.filter { $0.isOnline }
    }

    private var offlineDevices: [PlainDevice] {
        devices.filter { !$0.isOnline }
    }

    // MARK: - Actions

    private func loadDevices() {
        do {
            let descriptor = FetchDescriptor<PlainDevice>(
                sortBy: [SortDescriptor(\.lastSeen, order: .reverse)]
            )
            devices = try modelContext.fetch(descriptor)
        } catch {
            devices = []
        }
    }

    private func switchToDevice(_ device: PlainDevice) {
        guard device.id != appState.activeDevice?.id else {
            dismiss()
            return
        }

        isSwitching = true

        Task {
            let connMgr = ConnectionManager(appState: appState)
            do {
                try await connMgr.connect(to: device)
                appState.activeDevice = device
            } catch {
                appState.setError("Failed to switch: \(error.localizedDescription)")
            }
            isSwitching = false
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    DevicePickerSheet()
        .environmentObject(AppState())
}
