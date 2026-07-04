import SwiftUI
struct SettingsView: View {
    @EnvironmentObject var s: AppState
    var body: some View {
        NavigationStack{
            Form{
                Text("\(s.devices.count) devices")
                Button("Clear All",role:.destructive){s.devices.removeAll();s.save()}
            }.navigationTitle("Settings")
        }
    }
}
