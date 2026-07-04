import SwiftUI
import SwiftData

/// App settings screen.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showClearConfirmation = false
    @State private var deviceCount: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - About
                Section {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("PlainControl")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Saved Devices")
                        Spacer()
                        Text("\(deviceCount)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // MARK: - Discovery
                Section {
                    HStack {
                        Text("Discovery Protocol")
                        Spacer()
                        Text("UDP Multicast (224.0.0.100:52352)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("mDNS Support")
                        Spacer()
                        Text("Bonjour + plainapp.local")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Network")
                } footer: {
                    Text("Devices are discovered automatically on your local network via UDP multicast. mDNS is used as a fallback.")
                }

                // MARK: - Security
                Section {
                    HStack {
                        Text("SSL Certificates")
                        Spacer()
                        Text("Trusted for LAN IPs only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Encryption")
                        Spacer()
                        Text("Handled by device Web UI")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Security")
                } footer: {
                    Text("Self-signed certificates are only trusted on private IP ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x).")
                }

                // MARK: - Data Management
                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Devices")
                        }
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Removes all saved devices from this device. You can re-add them at any time.")
                }

                // MARK: - About PlainApp
                Section {
                    Link(destination: URL(string: "https://github.com/plainhub/plain-app")!) {
                        HStack {
                            Text("PlainApp GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("PlainApp")
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Devices?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllDevices()
                }
            } message: {
                Text("This will remove all saved devices. This action cannot be undone.")
            }
            .onAppear {
                updateDeviceCount()
            }
        }
    }

    private func updateDeviceCount() {
        do {
            deviceCount = try modelContext.fetchCount(FetchDescriptor<PlainDevice>())
        } catch {
            deviceCount = 0
        }
    }

    private func clearAllDevices() {
        do {
            let devices = try modelContext.fetch(FetchDescriptor<PlainDevice>())
            for device in devices {
                modelContext.delete(device)
            }
            try modelContext.save()
            deviceCount = 0
        } catch {}
    }
}

#Preview {
    SettingsView()
}
