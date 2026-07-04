import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("App", value: "PlainControl")
                    LabeledContent("Version", value: "1.0.0")
                }
                Section("PlainApp") {
                    Link("GitHub", destination: URL(string: "https://github.com/plainhub/plain-app")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
