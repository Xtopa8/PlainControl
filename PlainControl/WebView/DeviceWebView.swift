import SwiftUI
import WebKit
struct DeviceWebView: UIViewRepresentable {
    let url: URL; let coordinator: WebViewCoordinator
    func makeCoordinator() -> WebViewCoordinator { coordinator }
    func makeUIView(context: Context) -> WKWebView {
        let w = coordinator.createWebView()
        w.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15))
        return w
    }
    func updateUIView(_ w: WKWebView, context: Context) {}
}
