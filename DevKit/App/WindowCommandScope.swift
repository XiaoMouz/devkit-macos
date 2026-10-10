import AppKit
import SwiftUI

/// AppKit text views can become first responder outside SwiftUI's focus graph.
/// Keep commands scoped to their owning window even in that case.
@MainActor enum WindowCommandRouter {
  @Observable final class FocusRevision { var value = 0 }
  private static let focusRevision = FocusRevision()
  private static var refreshScheduled = false
  final class Box: NSObject {
    var actions: WorkspaceActions
    init(_ actions: WorkspaceActions) { self.actions = actions }
  }
  static let windows = NSMapTable<NSWindow, Box>.weakToStrongObjects()
  private static let observers = [NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification,
    NSWindow.didBecomeMainNotification, NSWindow.didResignMainNotification, NSWindow.willCloseNotification
  ].map { name in
    NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { notification in
      let closingWindow = notification.name == NSWindow.willCloseNotification ? notification.object as? NSWindow : nil
      MainActor.assumeIsolated {
        if let window = closingWindow {
          windows.removeObject(forKey: window)
        }
        refreshCommands()
      }
    }
  }
  private static func refreshCommands() {
    guard !refreshScheduled else { return }
    refreshScheduled = true
    // Window notifications can arrive during SwiftUI's AppKit update. Publish
    // menu availability after that transaction, once per batch of focus changes.
    DispatchQueue.main.async {
      refreshScheduled = false
      focusRevision.value += 1
    }
  }
  static func register(_ window: NSWindow, actions: WorkspaceActions) {
    _ = observers
    if windows.object(forKey: window)?.actions !== actions {
      windows.setObject(Box(actions), forKey: window)
      refreshCommands()
    }
  }
  static var current: WorkspaceActions? {
    _ = focusRevision.value
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
