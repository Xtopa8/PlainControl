import SwiftUI

struct AddDeviceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var host = ""
    @State private var port = "8443"

    var body: some View {
        NavigationStack {
            Form {
                Section("Manual Entry") {
                    TextField("IP Address", text: $host)
                        .keyboardType(.URL).autocapitalization(.none)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                Section {
                    Button("Connect") { dismiss() }
                        .disabled(host.isEmpty)
                }
            }
            .navigationTitle("Add Device")
            .toolbar { Button("Cancel") { dismiss() } }
        }
    }
}
