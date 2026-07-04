import SwiftUI
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            Text("Devices").tabItem { Label("Devices", systemImage: "rectangle.grid.1x2") }.tag(0)
            DeviceControlView().tabItem { Label("Control", systemImage: "display") }.tag(1)
            SettingsView().tabItem { Label("Settings", systemImage: "gear") }.tag(2)
        }
    }
}
