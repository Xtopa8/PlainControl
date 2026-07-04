import SwiftUI
struct RootView: View {
    @EnvironmentObject var s: AppState; @State private var t=0
    var body: some View {
        TabView(selection:$t){
            DeviceListView().tabItem{Label("Devices",systemImage:"rectangle.grid.1x2")}.tag(0)
            ControlView().tabItem{Label("Control",systemImage:"display")}.tag(1)
            SettingsView().tabItem{Label("Settings",systemImage:"gear")}.tag(2)
        }
    }
}
