import SwiftUI
import WebKit

struct ControlView: View {
    @EnvironmentObject var s: AppState
    @State private var useHTTP = false
    @State private var reloadTrigger = false

    var body: some View {
        VStack(spacing: 0) {
            if let d = s.activeDevice {
                // Build URL: try HTTPS first, HTTP fallback
                let scheme = useHTTP ? "http" : "https"
                let urlStr = "\(scheme)://\(d.ip):\(d.port)/"
                if let url = URL(string: urlStr) {
                    WebView(url: url, onError: { _ in
                        if !useHTTP {
                            useHTTP = true
                        }
                    })
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "display").font(.system(size: 48)).foregroundStyle(.secondary)
                    Text("No Device").font(.title2)
                    Text("Select a device from the Devices tab.").foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    var onError: ((Error) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView()
        w.navigationDelegate = context.coordinator
        context.coordinator.onError = onError
        w.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15))
        return w
    }

    func updateUIView(_ w: WKWebView, context: Context) {
        if w.url != url {
            context.coordinator.onError = onError
            w.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        var onError: ((Error) -> Void)?

        func webView(_ w: WKWebView, didReceive c: URLAuthenticationChallenge, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            guard let trust = c.protectionSpace.serverTrust else { completion(.performDefaultHandling, nil); return }
            completion(.useCredential, URLCredential(trust: trust))
        }

        func webView(_ w: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code != NSURLErrorCancelled {
                onError?(error)
            }
        }
    }
}
