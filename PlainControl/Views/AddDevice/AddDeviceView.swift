import SwiftUI
struct AddDeviceView: View {
    @EnvironmentObject var a: AppState; @Environment(\.dismiss) var dismiss
    @State private var host = ""; @State private var port = "8443"
    var body: some View {
        NavigationStack {
            Form {
                Section("Manual") {
                    TextField("IP Address", text: $host).keyboardType(.URL).autocapitalization(.none)
                    TextField("Port", text: $port).keyboardType(.numberPad)
                }
                Section { Button("Add") {
                    if let p = Int(port), !host.isEmpty {
                        let d = PlainDevice(id: host, name: host, ips: [host], httpsPort: p, isOnline: false)
                        a.addDevice(d); dismiss()
                    }
                }.disabled(host.isEmpty) }
            }
            .navigationTitle("Add Device")
            .toolbar { Button("Cancel") { dismiss() } }
        }
    }
}
