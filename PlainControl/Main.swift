import SwiftUI
import WebKit

@main
struct PlainControlApp: App {
    @State private var devices: [Device] = []
    @State private var activeDevice: Device?
    @State private var showAdd = false
    @State private var newIP = ""
    @State private var newPort = "8443"

    var body: some Scene {
        WindowGroup {
            TabView {
                deviceList.tabItem { Label("Devices", systemImage: "rectangle.grid.1x2") }
                controlView.tabItem { Label("Control", systemImage: "display") }
            }
        }
    }

    var deviceList: some View {
        NavigationView {
            List {
                ForEach(devices) { d in
                    Button {
                        activeDevice = d
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(d.name).font(.body).fontWeight(.medium)
                                Text("\(d.ip):\(d.port)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if activeDevice?.id == d.id {
                                Image(systemName: "checkmark").foregroundStyle(.accent)
                            }
                        }
                    }
                }
                .onDelete { idx in
                    devices.remove(atOffsets: idx)
                    save()
                }
            }
            .navigationTitle("Devices")
            .toolbar { Button { showAdd = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showAdd) {
                NavigationView {
                    Form {
                        TextField("IP", text: $newIP).keyboardType(.URL).autocapitalization(.none)
                        TextField("Port", text: $newPort).keyboardType(.numberPad)
                        Button("Add") {
                            if !newIP.isEmpty, let p = Int(newPort) {
                                devices.append(Device(ip: newIP, port: p))
                                save()
                                showAdd = false
                            }
                        }.disabled(newIP.isEmpty)
                    }
                    .navigationTitle("Add Device")
                    .toolbar { Button("Cancel") { showAdd = false } }
                }
            }
            .onAppear { load() }
        }
    }

    var controlView: some View {
        Group {
            if let d = activeDevice {
                WebView(url: URL(string: "https://\(d.ip):\(d.port)/")!)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "display").font(.system(size: 48)).foregroundStyle(.secondary)
                    Text("No Device").font(.title2)
                    Text("Select from Devices tab").foregroundStyle(.secondary)
                }
            }
        }
    }

    func load() {
        if let d = UserDefaults.standard.data(forKey: "devs"),
           let arr = try? JSONDecoder().decode([Device].self, from: d) { devices = arr }
    }
    func save() {
        if let d = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(d, forKey: "devs")
        }
    }
}

struct Device: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var name: String
    var ip: String
    var port: Int
    init(ip: String, port: Int) { self.ip = ip; self.port = port; self.name = ip }
}

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView(); w.navigationDelegate = context.coordinator
        w.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15))
        return w
    }
    func updateUIView(_ w: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ w: WKWebView, didReceive c: URLAuthenticationChallenge, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let t = c.protectionSpace.serverTrust else { completion(.performDefaultHandling, nil); return }
            completion(.useCredential, URLCredential(trust: t))
        }
    }
}
