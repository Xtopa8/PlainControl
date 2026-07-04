import Foundation
import WebKit
import SwiftUI

/// Coordinator for WKWebView lifecycle management.
///
/// Handles:
/// - Page loading lifecycle (start, progress, finish, fail)
/// - SSL certificate challenges (delegates to SSLTrustingNavigationDelegate)
/// - JavaScript alerts/confirms/prompts (via WKUIDelegate)
/// - Optional JavaScript-to-Native bridge messages
final class WebViewCoordinator: NSObject {
    // MARK: - Callbacks

    var onStartLoading: (() -> Void)?
    var onFinishLoading: (() -> Void)?
    var onFailLoading: ((Error) -> Void)?
    var onProgressUpdate: ((Double) -> Void)?
    var onTitleUpdate: ((String) -> Void)?
    var onJSBridgeMessage: ((String, Any) -> Void)?

    // MARK: - Properties

    private let sslDelegate = SSLTrustingNavigationDelegate()

    /// Estimated loading progress (key-value observation token).
    private var progressObservation: NSKeyValueObservation?

    // MARK: - WebView Configuration

    /// Create a configured WKWebView for PlainApp device control.
    func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()

        // Enable inline media playback (for screen mirror WebRTC)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Configure preferences
        let prefs = WKPreferences()
        prefs.isElementFullscreenEnabled = true
        config.preferences = prefs

        // Set up JavaScript message handler for native bridge
        let contentController = WKUserContentController()
        contentController.add(self, name: "plainControl")
        config.userContentController = contentController

        // Create the web view
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true

        // Observe loading progress
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.onProgressUpdate?(webView.estimatedProgress)
        }

        // Observe title changes
        progressObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            if let title = webView.title {
                self?.onTitleUpdate?(title)
            }
        }

        return webView
    }

    /// Load the device control URL in the WebView.
    func loadDeviceURL(_ url: URL, in webView: WKWebView) {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15
        webView.load(request)
    }

    /// Reload the current page.
    func reload(in webView: WKWebView) {
        webView.reload()
    }

    /// Stop loading.
    func stopLoading(in webView: WKWebView) {
        webView.stopLoading()
    }

    /// Go back in navigation history.
    func goBack(in webView: WKWebView) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewCoordinator: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Delegate to SSL trust manager
        sslDelegate.webView(webView, didReceive: challenge, completionHandler: completionHandler)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        onStartLoading?()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinishLoading?()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Navigation within the page failed — not always fatal
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return // Ignore cancelled loads
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Initial page load failed — this is the important error
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        onFailLoading?(error)
    }
}

// MARK: - WKUIDelegate

extension WebViewCoordinator: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        // For a controller app, we silently dismiss JS alerts
        // (they appear in the web UI context, not ours)
        completionHandler()
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

// MARK: - WKScriptMessageHandler (JS Bridge)

extension WebViewCoordinator: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "plainControl" else { return }

        // Handle native bridge messages from the web UI
        // Format: { "action": "switchDevice", "deviceId": "..." }
        if let body = message.body as? [String: Any],
           let action = body["action"] as? String {
            onJSBridgeMessage?(action, body)
        }
    }
}
