import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showAddDevice = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DeviceListView()
                    .tabItem { Label("Devices", systemImage: "rectangle.grid.1x2") }
                    .tag(0)

                Text("Select a device first")
                    .tabItem { Label("Control", systemImage: "display") }
                    .tag(1)

                Text("Settings")
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(2)
            }
        }
        .sheet(isPresented: $showAddDevice) {
            Text("Add Device")
        }
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
