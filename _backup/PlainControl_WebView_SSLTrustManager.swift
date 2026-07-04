import Foundation
import WebKit

/// Manages SSL/TLS certificate trust for PlainApp devices.
///
/// PlainApp Android devices use self-signed BKS certificates.
/// Since these devices are on the LAN, we can safely trust them
/// after verifying they're on a private IP range (RFC1918).
final class SSLTrustManager: NSObject {
    /// Check whether a host is safe to trust with a self-signed certificate.
    /// Only allows private IP ranges and .local domains.
    static func isSafeToTrust(host: String) -> Bool {
        host.isSafeForSelfSignedTLS
    }

    /// Create a URLCredential from a server trust for a LAN host.
    static func credential(for trust: SecTrust) -> URLCredential {
        URLCredential(trust: trust)
    }
}

// MARK: - WKNavigationDelegate for SSL Handling

/// WKNavigationDelegate that handles self-signed certificate challenges.
///
/// Only trusts certificates for private IP addresses (RFC1918).
/// Public IPs and internet hosts are rejected.
final class SSLTrustingNavigationDelegate: NSObject, WKNavigationDelegate {
    /// Called when WKWebView receives an authentication challenge.
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // Only trust self-signed certs for LAN/private IPs
        if SSLTrustManager.isSafeToTrust(host: host) {
            let credential = SSLTrustManager.credential(for: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // For public IPs, perform default validation
            completionHandler(.performDefaultHandling, nil)
        }
    }

    /// Called when the WebView starts provisional navigation.
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {}

    /// Called when the WebView finishes loading.
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {}

    /// Called on navigation failure.
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {}

    /// Called on provisional navigation failure.
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {}
}
