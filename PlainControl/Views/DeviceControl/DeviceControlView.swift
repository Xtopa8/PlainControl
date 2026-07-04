import SwiftUI
struct DeviceControlView: View {
    @EnvironmentObject var a: AppState
    var body: some View {
        Group {
            if let d = a.activeDevice, let url = d.connectionURL {
                DeviceWebView(url: url, coordinator: WebViewCoordinator())
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
