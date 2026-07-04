import SwiftUI
import SwiftData

/// Main device list screen — displays all saved PlainApp devices.
///
/// Users can add, delete, rename devices and select one to control.
/// Online/offline status is shown per device.
struct DeviceListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\PlainDevice.sortOrder, order: .forward),
                  SortDescriptor(\PlainDevice.lastSeen, order: .reverse)])
    private var devices: [PlainDevice]

    @State private var showAddDevice = false
    @State private var deviceToDelete: PlainDevice?
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if devices.isEmpty {
                    emptyStateView
                } else {
                    deviceListView
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddDevice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDevice) {
                AddDeviceView()
            }
            .alert("Delete Device?", isPresented: .constant(deviceToDelete != nil)) {
                Button("Cancel", role: .cancel) {
                    deviceToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteConfirmedDevice()
                }
            } message: {
                Text("Are you sure you want to remove \(deviceToDelete?.name ?? "this device")?")
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Devices")
                .font(.title2).fontWeight(.semibold)
            Text("Add a PlainApp device to start controlling it.\nDevices are discovered automatically on your local network.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
            Button { showAddDevice = true } label: {
                Label("Add Device", systemImage: "plus").font(.headline)
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
    }

    // MARK: - Device List

    private var deviceListView: some View {
        List {
            if onlineDevices.isNotEmpty {
                Section("Online") {
                    ForEach(onlineDevices, id: \.id) { device in
                        deviceRow(device: device, status: device.isOnline ? .online : .offline)
                    }
                }
            }
            if offlineDevices.isNotEmpty {
                Section("Offline") {
                    ForEach(offlineDevices, id: \.id) { device in
                        deviceRow(device: device, status: .offline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deviceRow(device: PlainDevice, status: DeviceStatus) -> some View {
        DeviceRowView(
            device: device,
            status: status,
            onTap: { Task { await selectDevice(device) } },
            onDelete: { deviceToDelete = device },
            onRename: { newName in renameDevice(device, to: newName) }
        )
    }

    // MARK: - Computed

    private var onlineDevices: [PlainDevice] { devices.filter { $0.isOnline } }
    private var offlineDevices: [PlainDevice] { devices.filter { !$0.isOnline } }

    // MARK: - Actions

    private func selectDevice(_ device: PlainDevice) async {
        isConnecting = true
        errorMessage = nil

        let repo = DeviceRepository(context: modelContext)
        let connMgr = ConnectionManager(appState: appState)

        defer { isConnecting = false }

        do {
            // Deactivate current active
            if let current = try repo.fetchActive(), current.id != device.id {
                current.isActive = false
            }
            device.isActive = true
            try modelContext.save()

            // Connect
            try await connMgr.connect(to: device)
            appState.activeDevice = device
            appState.connectionState = .connected
        } catch {
            errorMessage = error.localizedDescription
            appState.setError(error.localizedDescription)
        }
    }

    private func renameDevice(_ device: PlainDevice, to newName: String) {
        guard !newName.isEmpty else { return }
        device.name = newName
        try? modelContext.save()
    }

    private func deleteConfirmedDevice() {
        guard let device = deviceToDelete else { return }
        if device.isActive {
            appState.activeDevice = nil
            appState.connectionState = .disconnected
        }
        modelContext.delete(device)
        try? modelContext.save()
        deviceToDelete = nil
    }
}

#Preview {
    DeviceListView()
        .environmentObject(AppState())
}
