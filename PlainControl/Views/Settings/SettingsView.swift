import SwiftUI
struct SettingsView: View {
    @EnvironmentObject var a: AppState
    var body: some View {
        NavigationStack {
            Form {
                Section { LabeledContent("Devices", value: "\(a.devices.count)") }
                Section { Button("Clear All", role: .destructive) { a.devices.removeAll(); a.save() } }
            }.navigationTitle("Settings")
        }
    }
}
