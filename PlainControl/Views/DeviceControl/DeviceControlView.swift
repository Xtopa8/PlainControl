import SwiftUI

/// Main device control screen — wraps a WKWebView loading the PlainApp web UI
/// from the active device, with a native toolbar overlay.
struct DeviceControlView: View {
    @EnvironmentObject private var appState: AppState

    @State private var isLoading = false
    @State private var loadingProgress = 0.0
    @State private var pageTitle = ""
    @State private var showToolbar = true
    @State private var showDevicePicker = false
    @State private var toolbarHideTask: Task<Void, Never>?

    private let coordinator = WebViewCoordinator()

    var body: some View {
        ZStack {
            // WebView
            if let url = appState.activeDevice?.connectionURL {
                DeviceWebView(url: url, coordinator: configuredCoordinator)
                    .ignoresSafeArea(edges: [.horizontal, .bottom])
            } else {
                noURLView
            }

            // Toolbar
            VStack {
                if showToolbar {
                    toolbarOverlay
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }

            // Loading bar
            if isLoading {
                VStack {
                    ProgressView(value: loadingProgress).progressViewStyle(.linear).tint(.accentColor)
                    Spacer()
                }
            }

            // Error banner
            if case .error(let connErr) = appState.connectionState {
                ConnectionStatusBanner(error: connErr) {
                    Task { await reconnect() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToolbar)
        .sheet(isPresented: $showDevicePicker) {
            DevicePickerSheet()
        }
        .onTapGesture {
            withAnimation { showToolbar.toggle(); if showToolbar { autoHideToolbar() } }
        }
        .onAppear { autoHideToolbar() }
    }

    // MARK: - Coordinator Config

    private var configuredCoordinator: WebViewCoordinator {
        coordinator.onStartLoading = { isLoading = true; loadingProgress = 0 }
        coordinator.onFinishLoading = { isLoading = false; loadingProgress = 1 }
        coordinator.onFailLoading = { _ in isLoading = false }
        coordinator.onProgressUpdate = { loadingProgress = min($0, 1) }
        coordinator.onTitleUpdate = { pageTitle = $0 }
        coordinator.onJSBridgeMessage = { action, _ in
            if action == "switchDevice" || action == "pickerDevice" { showDevicePicker = true }
        }
        return coordinator
    }

    // MARK: - Toolbar

    private var toolbarOverlay: some View {
        HStack(spacing: 12) {
            if let device = appState.activeDevice {
                DeviceIconView(deviceType: device.deviceType, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name).font(.subheadline).fontWeight(.semibold).lineLimit(1)
                    HStack(spacing: 8) {
                        StatusPill(status: currentStatus)
                        if let ip = device.primaryIP {
                            Text(ip).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button { showDevicePicker = true } label: {
                    Image(systemName: "arrow.triangle.swap").font(.caption)
                }.buttonStyle(.bordered)
                Button(role: .destructive) {
                    disconnect()
                } label: {
                    Image(systemName: "xmark").font(.caption)
                }.buttonStyle(.bordered)
            }
        }
        .padding(.horizontal).padding(.vertical, 10).padding(.top, 44)
        .background(.regularMaterial)
    }

    // MARK: - No URL State

    private var noURLView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("Cannot Connect").font(.title3)
            Text("No connection URL available for the active device.\nCheck that the device has valid IP and port settings.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding()
    }

    // MARK: - Computed

    private var currentStatus: DeviceStatus {
        switch appState.connectionState {
        case .connected: return .online
        case .connecting: return .connecting
        case .error: return .error
        case .disconnected: return .offline
        }
    }

    // MARK: - Actions

    private func reconnect() async {
        guard let device = appState.activeDevice else { return }
        let connMgr = ConnectionManager(appState: appState)
        try? await connMgr.connect(to: device)
    }

    private func disconnect() {
        let connMgr = ConnectionManager(appState: appState)
        connMgr.disconnect()
    }

    private func autoHideToolbar() {
        toolbarHideTask?.cancel()
        toolbarHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { showToolbar = false }
        }
    }
}

#Preview {
    DeviceControlView().environmentObject(AppState())
}
