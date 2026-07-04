import SwiftUI
import WebKit

struct ControlView: View {
    @EnvironmentObject var s: AppState
    var body: some View {
        if let d = s.activeDevice, let url = URL(string: "https://\(d.ip):\(d.port)/") {
            WebView(url: url)
        } else {
            VStack(spacing: 20) {
                Image(systemName: "display").font(.system(size: 48)).foregroundStyle(.secondary)
                Text("No Device").font(.title2)
                Text("Select a device from the Devices tab.").foregroundStyle(.secondary)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView()
        w.navigationDelegate = context.coordinator
        w.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15))
        return w
    }
    func updateUIView(_ w: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ w: WKWebView, didReceive c: URLAuthenticationChallenge, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let trust = c.protectionSpace.serverTrust else { completion(.performDefaultHandling, nil); return }
            let host = c.protectionSpace.host
            if host.hasPrefix("192.168.") || host.hasPrefix("10.") || host.hasPrefix("172.") || host == "localhost" || host.hasSuffix(".local") {
                completion(.useCredential, URLCredential(trust: trust))
            } else { completion(.performDefaultHandling, nil) }
        }
    }
}
