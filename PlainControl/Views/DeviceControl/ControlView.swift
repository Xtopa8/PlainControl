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
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView(); w.navigationDelegate = context.coordinator
        w.load(URLRequest(url: url))
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
