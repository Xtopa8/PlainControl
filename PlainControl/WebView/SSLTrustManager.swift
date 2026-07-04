import Foundation
import WebKit
final class SSLTrustManager: NSObject, WKNavigationDelegate {
    func webView(_ w: WKWebView, didReceive c: URLAuthenticationChallenge, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard c.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = c.protectionSpace.serverTrust else { completion(.performDefaultHandling, nil); return }
        let host = c.protectionSpace.host
        if host.hasPrefix("192.168.") || host.hasPrefix("10.") || host.hasPrefix("172.") || host == "localhost" || host.hasSuffix(".local") {
            completion(.useCredential, URLCredential(trust: trust))
        } else { completion(.performDefaultHandling, nil) }
    }
}
