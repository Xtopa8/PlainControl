import SwiftUI

/// Root view of PlainControl.
///
/// Uses a TabView for primary navigation:
/// - Tab 1: Device list (discover, add, manage devices)
/// - Tab 2: Device control (WKWebView for active device)
/// - Tab 3: Settings
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .devices
    @State private var activeSheet: AppSheet?

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DeviceListView()
                    .tabItem {
                        Label(AppTab.devices.title, systemImage: AppTab.devices.icon)
                    }
                    .tag(AppTab.devices)

                Group {
                    if appState.activeDevice != nil {
                        DeviceControlView()
                    } else {
                        NoActiveDeviceView()
                    }
                }
                .tabItem {
                    Label(AppTab.control.title, systemImage: AppTab.control.icon)
                }
                .tag(AppTab.control)

                SettingsView()
                    .tabItem {
                        Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                    }
                    .tag(AppTab.settings)
            }

            // Global error banner overlay
            if let error = appState.globalErrorMessage {
                VStack {
                    ErrorBannerView(message: error) {
                        appState.clearError()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .animation(.spring(), value: appState.globalErrorMessage)
                .zIndex(100)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addDevice:
                AddDeviceView()
            case .devicePicker:
                DevicePickerSheet()
            case .pairingRequest(let deviceId):
                // Will be implemented in Phase 5
                Text("Pairing request for \(deviceId)")
            }
        }
        .onAppear {
            // Auto-select control tab when a device becomes active
            if appState.activeDevice != nil && selectedTab == .devices {
                // Stay on devices tab on first launch
            }
        }
    }
}

// MARK: - No Active Device Placeholder

private struct NoActiveDeviceView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "display")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Active Device")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Select a device from the Devices tab\nto start controlling it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                // This would switch to the devices tab
            }) {
                Label("Go to Devices", systemImage: "rectangle.grid.1x2")
            }
            .buttonStyle(.borderedProminent)
            .disabled(true) // Placeholder — will be wired in Phase 3
        }
        .padding()
    }
}

// MARK: - Error Banner

private struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(AppState())
}
