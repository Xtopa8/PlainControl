import Foundation
import WebKit
final class WebViewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    func createWebView() -> WKWebView {
        let c = WKWebViewConfiguration()
        c.allowsInlineMediaPlayback = true
        c.mediaTypesRequiringUserActionForPlayback = []
        let w = WKWebView(frame: .zero, configuration: c)
        w.navigationDelegate = self; w.uiDelegate = self
        return w
    }
    func webView(_ w: WKWebView, didReceive c: URLAuthenticationChallenge, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = c.protectionSpace.serverTrust else { completion(.performDefaultHandling, nil); return }
        let host = c.protectionSpace.host
        if host.hasPrefix("192.168.") || host.hasPrefix("10.") || host.hasPrefix("172.") || host == "localhost" || host.hasSuffix(".local") {
            completion(.useCredential, URLCredential(trust: trust))
        } else { completion(.performDefaultHandling, nil) }
    }
}
