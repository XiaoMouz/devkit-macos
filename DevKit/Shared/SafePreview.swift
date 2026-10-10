import SwiftUI
import WebKit

struct SafePreview: NSViewRepresentable {
  let html: String
  func makeCoordinator() -> Coordinator { Coordinator() }
  func makeNSView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = false
    let web = WKWebView(frame: .zero, configuration: configuration)
    web.navigationDelegate = context.coordinator
    web.setValue(false, forKey: "drawsBackground")
    return web
  }
  func updateNSView(_ view: WKWebView, context: Context) {
    guard context.coordinator.loaded != html else { return }
    context.coordinator.loaded = html
    let head =
      "<meta charset='utf-8'><meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src 'none'; script-src 'none'; connect-src 'none'; frame-src 'none'\"><style>:root{color-scheme:light dark}body{font:14px -apple-system;padding:20px;line-height:1.6;overflow-wrap:anywhere}pre{white-space:pre-wrap}img,svg{max-width:100%;height:auto}*{box-sizing:border-box}</style>"
    view.loadHTMLString(head + html, baseURL: nil)
  }
  @MainActor final class Coordinator: NSObject, WKNavigationDelegate {
    var loaded: String?
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async
      -> WKNavigationActionPolicy
    {
      navigationAction.navigationType == .other && navigationAction.request.url?.scheme == "about"
        ? .allow : .cancel
    }
  }
}
