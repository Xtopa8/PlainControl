import SwiftUI

struct DeviceControlView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if let device = appState.activeDevice, let url = device.connectionURL {
                DeviceWebView(url: url, coordinator: WebViewCoordinator())
                    .ignoresSafeArea(edges: [.horizontal, .bottom])
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "display").font(.system(size: 48)).foregroundStyle(.secondary)
                    Text("No Active Device").font(.title2)
                    Text("Select a device from the Devices tab.").foregroundStyle(.secondary)
                }
            }
        }
    }
}
