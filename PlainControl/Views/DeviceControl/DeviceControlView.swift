import SwiftUI

struct DeviceControlView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            VStack {
                if let device = appState.activeDevice {
                    DeviceWebView(url: device.connectionURL ?? URL(string: "about:blank")!,
                                  coordinator: WebViewCoordinator())
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "display").font(.system(size: 48)).foregroundStyle(.secondary)
                        Text("No Active Device").font(.title2)
                        Text("Select a device from the Devices tab.").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(appState.activeDevice?.name ?? "Control")
            .toolbar {
                ToolbarItem {
                    Button { showPicker = true } label: { Image(systemName: "arrow.triangle.swap") }
                }
            }
            .sheet(isPresented: $showPicker) { DevicePickerSheet() }
        }
    }
}
