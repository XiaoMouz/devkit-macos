import AppKit
import DevKitCore
import SwiftUI

@MainActor final class DetachedWorkspaceWindows {
  static let shared = DetachedWorkspaceWindows()
  private var controllers: [String: PaneWindowController] = [:]
  func open<T: ToolModule>(_ session: ToolSession<T>, pane: DetachedWorkspacePane) {
    let key = session.id.uuidString + ":" + pane.rawValue
    if let controller = controllers[key] {
      controller.showWindow(nil)
      controller.window?.makeKeyAndOrderFront(nil)
      return
    }
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: pane == .comparison ? 1100 : 900, height: 740),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    window.title = "\(session.metadata.name) · \(pane.title)"
    window.titlebarAppearsTransparent = true
    window.tabbingMode = .disallowed
    window.isRestorable = false
    window.isReleasedWhenClosed = false
    window.contentMinSize = NSSize(width: pane == .comparison ? 880 : 560, height: 440)
    window.contentViewController = NSHostingController(
      rootView: DetachedWorkspaceRoot(session: session, pane: pane))
    let controller = PaneWindowController(window: window)
    controller.closed = { [weak self, weak session] in
      session?.detachedClosed()
      self?.controllers[key] = nil
    }
    controllers[key] = controller
    session.detachedOpened()
    window.center()
    controller.showWindow(nil)
    window.makeKeyAndOrderFront(nil)
  }
}

@MainActor private final class PaneWindowController: NSWindowController, NSWindowDelegate {
  var closed: (() -> Void)?
  override init(window: NSWindow?) {
    super.init(window: window)
    window?.delegate = self
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
  func windowWillClose(_ notification: Notification) {
    let callback = closed
    closed = nil
    callback?()
  }
}

private struct DetachedWorkspaceRoot<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  let pane: DetachedWorkspacePane
  @State private var actions: WorkspaceActions
  init(session: ToolSession<T>, pane: DetachedWorkspacePane) {
    self.session = session
    self.pane = pane
    _actions = State(initialValue: WorkspaceActions(
      run: { [weak session] in session?.run() }, copy: { [weak session] in session?.copyResult() },
      search: {}, supportsNavigation: false))
  }
  var body: some View {
    ToolWorkspace(session: session, detachedPane: pane)
      .environment(\.locale, L10n.locale)
      .background(DetachedWindowTitle(title: "\(session.metadata.name) · \(pane.title)"))
      .background(WindowCommandScope(actions: actions))
  }
}

private struct DetachedWindowTitle: NSViewRepresentable {
  let title: String
  func makeNSView(context: Context) -> NSView { NSView() }
  func updateNSView(_ view: NSView, context: Context) {
    if let window = view.window { window.title = title }
    else {
      DispatchQueue.main.async { [weak view, title] in view?.window?.title = title }
    }
  }
}
