import AppKit
import SwiftUI

/// AppKit text views can become first responder outside SwiftUI's focus graph.
/// Keep commands scoped to their owning window even in that case.
@MainActor enum WindowCommandRouter {
  final class Box: NSObject {
    var actions: WorkspaceActions
    init(_ actions: WorkspaceActions) { self.actions = actions }
  }
  static let windows = NSMapTable<NSWindow, Box>.weakToStrongObjects()
  private static let closeObserver = NotificationCenter.default.addObserver(
    forName: NSWindow.willCloseNotification, object: nil, queue: .main
  ) { notification in
    guard let window = notification.object as? NSWindow else { return }
    MainActor.assumeIsolated { windows.removeObject(forKey: window) }
  }
  static func register(_ window: NSWindow, actions: WorkspaceActions) {
    _ = closeObserver
    windows.setObject(Box(actions), forKey: window)
  }
  static var current: WorkspaceActions? {
    guard let window = NSApp.keyWindow ?? NSApp.mainWindow else { return nil }
    return windows.object(forKey: window)?.actions
  }
}

struct WindowCommandScope: NSViewRepresentable {
  let actions: WorkspaceActions
  func makeNSView(context: Context) -> RegistrationView { RegistrationView(actions: actions) }
  func updateNSView(_ view: RegistrationView, context: Context) {
    view.actions = actions
    view.register()
  }
  @MainActor final class RegistrationView: NSView {
    var actions: WorkspaceActions
    init(actions: WorkspaceActions) {
      self.actions = actions
      super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      register()
    }
    func register() {
      if let window {
        WindowCommandRouter.register(window, actions: actions)
      }
    }
  }
}
