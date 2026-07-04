import SwiftUI

struct RootView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            DeviceListView()
                .tabItem { Label("Devices", systemImage: "rectangle.grid.1x2") }.tag(0)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }.tag(1)
        }
    }
}
