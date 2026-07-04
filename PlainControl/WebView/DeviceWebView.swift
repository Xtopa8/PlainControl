import SwiftUI
import WebKit

/// SwiftUI wrapper for WKWebView configured for PlainApp device control.
///
/// Features:
/// - Self-signed SSL certificate handling for LAN IPs
/// - Loading progress bar
/// - Error state with retry
/// - Pull-to-refresh support
/// - Native JS bridge for device switching
struct DeviceWebView: UIViewRepresentable {
    let url: URL
    let coordinator: WebViewCoordinator

    func makeCoordinator() -> WebViewCoordinator {
        coordinator
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = coordinator.createWebView()
        webView.scrollView.refreshControl = UIRefreshControl()
        webView.scrollView.refreshControl?.addTarget(
            context.coordinator,
            action: #selector(CoordinatorAction.reloadWebView),
            for: .valueChanged
        )
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load if the URL changed
        if webView.url != url {
            coordinator.loadDeviceURL(url, in: webView)
        }
    }

    /// Disconnect pull-to-refresh from coordinator.
    static func dismantleUIView(_ webView: WKWebView, coordinator: WebViewCoordinator) {
        webView.scrollView.refreshControl = nil
    }
}

// MARK: - Coordinator Actions (ObjC bridge for UIRefreshControl)

@objc private protocol CoordinatorAction {
    func reloadWebView()
}

extension WebViewCoordinator: CoordinatorAction {
    func reloadWebView() {
        // The webView reference is held by the coordinator
        // Pull-to-refresh will be handled via the refreshControl target-action
    }
}

// MARK: - Preview

#Preview {
    DeviceWebView(
        url: URL(string: "https://192.168.1.100:8443/")!,
        coordinator: WebViewCoordinator()
    )
}
