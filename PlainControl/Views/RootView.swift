import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Text("Devices")
                .tabItem { Label("Devices", systemImage: "rectangle.grid.1x2") }
            Text("Control")
                .tabItem { Label("Control", systemImage: "display") }
            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

#Preview {
    RootView()
}
