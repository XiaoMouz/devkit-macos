import DevKitCore
import SwiftUI
import WebKit
import OSLog

/// Keep at most one detached renderer briefly for tab/view switches. Content is
/// local, JavaScript stays disabled, and the renderer is cleared before reuse.
@MainActor private final class PreviewPool {
  static let shared = PreviewPool()
  static let log = Logger(subsystem: "app.devkit.macos", category: "Preview")
  private var idle: WKWebView?
  private var expiration: Task<Void, Never>?
  private var store: WKWebsiteDataStore?
  private var active = 0

  func take() -> WKWebView {
    expiration?.cancel()
    expiration = nil
    active += 1
    if let web = idle {
      idle = nil
      Self.log.debug("reuse renderer")
      return web
    }
    let configuration = WKWebViewConfiguration()
    if store == nil { store = .nonPersistent() }
    configuration.websiteDataStore = store!
    configuration.defaultWebpagePreferences.allowsContentJavaScript = false
    let web = WKWebView(frame: .zero, configuration: configuration)
    web.underPageBackgroundColor = .clear
    Self.log.info("create renderer; active=\(self.active)")
    return web
  }

  func put(_ web: WKWebView) {
    active = max(0, active - 1)
    web.stopLoading()
    web.navigationDelegate = nil
    web.loadHTMLString("", baseURL: nil)
    web.removeFromSuperview()
    idle = web
    expiration?.cancel()
    expiration = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(10)) } catch { return }
      guard let self else { return }
      idle = nil
      if active == 0 { store = nil }
      expiration = nil
      Self.log.debug("release idle renderer")
    }
  }
}

struct SafePreview: View {
  let html: String
  var toolID = "preview"
  @State private var failure: String?
  @State private var reload = 0
  var body: some View {
    NativeSafePreview(html: html, toolID: toolID, reload: reload, failure: $failure)
      .overlay {
        if let failure {
          VStack(spacing: 12) {
            Label(failure, systemImage: "exclamationmark.triangle")
            Button(L10n.tr("Reload Preview")) { self.failure = nil; reload += 1 }
          }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
        }
      }
  }
}

private struct NativeSafePreview: NSViewRepresentable {
  let html: String
  let toolID: String
  let reload: Int
  @Binding var failure: String?
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  func makeNSView(context: Context) -> WKWebView {
    let web = PreviewPool.shared.take()
    web.navigationDelegate = context.coordinator
    return web
  }
  func updateNSView(_ web: WKWebView, context: Context) {
    let coordinator = context.coordinator
    coordinator.parent = self
    guard coordinator.loaded != html || coordinator.reload != reload else { return }
    coordinator.loaded = html
    coordinator.reload = reload
    coordinator.recoveries = 0
    coordinator.load(web)
  }
  static func dismantleNSView(_ web: WKWebView, coordinator: Coordinator) {
    coordinator.loaded = nil
    PreviewPool.log.debug("detach tool=\(coordinator.parent.toolID, privacy: .public)")
    PreviewPool.shared.put(web)
  }
  @MainActor final class Coordinator: NSObject, WKNavigationDelegate {
    var parent: NativeSafePreview
    var loaded: String?
    var reload = -1
    var recoveries = 0
    init(_ parent: NativeSafePreview) { self.parent = parent }
    func load(_ web: WKWebView) {
      guard let loaded else { return }
      let head = "<meta charset='utf-8'><meta http-equiv='Content-Security-Policy' content=\"default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src 'none'; script-src 'none'; connect-src 'none'; frame-src 'none'\"><style>:root{color-scheme:light dark}body{font:14px -apple-system;padding:20px;line-height:1.6;overflow-wrap:anywhere}pre{white-space:pre-wrap}img,svg{max-width:100%;height:auto}*{box-sizing:border-box}</style>"
      PreviewPool.log.debug("load tool=\(self.parent.toolID, privacy: .public)")
      web.loadHTMLString(head + loaded, baseURL: nil)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
      navigationAction.navigationType == .other && navigationAction.request.url?.scheme == "about" ? .allow : .cancel
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      parent.failure = nil
      PreviewPool.log.debug("ready tool=\(self.parent.toolID, privacy: .public)")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) { failed(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) { failed(error) }
    private func failed(_ error: any Error) {
      let code = (error as NSError).code
      guard code != NSURLErrorCancelled else { return }
      parent.failure = L10n.tr("Preview could not load. Try reloading; the original result can still be copied or exported.")
      PreviewPool.log.error("navigation failed tool=\(self.parent.toolID, privacy: .public) code=\(code)")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      PreviewPool.log.error("content process terminated tool=\(self.parent.toolID, privacy: .public) recovery=\(self.recoveries)")
      if recoveries == 0 {
        recoveries += 1
        load(webView)
      } else { parent.failure = L10n.tr("The preview process exited. Reload it manually.") }
    }
  }
}
