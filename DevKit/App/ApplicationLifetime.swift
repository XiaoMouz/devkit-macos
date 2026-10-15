import AppKit
import Combine
import DevKitCore

/// App Intents may launch the app without opening a window. These launches are transient.
@MainActor final class ApplicationLifetime: NSObject, ObservableObject {
  static let shared = ApplicationLifetime()
  @Published private(set) var showsBackgroundStatus = false
  @Published private(set) var activeTaskCount = 0
  private var policy = BackgroundLifetimePolicy(now: ProcessInfo.processInfo.systemUptime)
  private var idleTask: Task<Void, Never>?
  private var started = false
  private var foregroundServicesStarted = false
  private let openedWindows = NSHashTable<NSWindow>.weakObjects()
  private let closingWindows = NSHashTable<NSWindow>.weakObjects()

  func start() {
    guard !started else { return }
    started = true
    for name in [NSWindow.didBecomeKeyNotification, NSWindow.didBecomeMainNotification,
      NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification,
      NSWindow.willCloseNotification, NSApplication.didHideNotification,
      NSApplication.didUnhideNotification, NSApplication.didBecomeActiveNotification] {
      NotificationCenter.default.addObserver(self, selector: #selector(windowsChanged(_:)), name: name, object: nil)
    }
    refresh()
  }

  @objc private func windowsChanged(_ notification: Notification) {
    if let window = notification.object as? NSWindow, isContentWindow(window) {
      if notification.name == NSWindow.willCloseNotification {
        openedWindows.remove(window)
        closingWindows.add(window)
      } else {
        closingWindows.remove(window)
        openedWindows.add(window)
      }
    }
    // Let AppKit/SwiftUI finish the window transaction before publishing state.
    Task { @MainActor [weak self] in self?.refresh() }
  }

  private func isContentWindow(_ window: NSWindow) -> Bool {
    window.styleMask.contains(.titled)
  }

  private func hasOpenWindows() -> Bool {
    for window in NSApp.windows where isContentWindow(window) && !closingWindows.contains(window) {
      if window.isVisible || window.isMiniaturized { openedWindows.add(window) }
    }
    // Hiding/minimizing an existing workspace must never discard its session.
    return !openedWindows.allObjects.isEmpty || NSApp.modalWindow != nil
  }

  private func refresh() {
    guard started else { return }
    let hasWindows = hasOpenWindows()
    policy.setHasOpenWindows(hasWindows, now: ProcessInfo.processInfo.systemUptime)
    if activeTaskCount != policy.activities.count { activeTaskCount = policy.activities.count }
    if showsBackgroundStatus != !hasWindows { showsBackgroundStatus = !hasWindows }
    if hasWindows && !foregroundServicesStarted {
      foregroundServicesStarted = true
      SpotlightSettingsStore.shared.refresh()
      AppUpdater.shared.start()
    }
    idleTask?.cancel()
    guard let deadline = policy.idleDeadline else { return }
    idleTask = Task { @MainActor [weak self] in
      let delay = max(0, deadline - ProcessInfo.processInfo.systemUptime)
      do { try await Task.sleep(for: .seconds(delay)) } catch { return }
      guard let self, !Task.isCancelled else { return }
      self.policy.setHasOpenWindows(self.hasOpenWindows(), now: ProcessInfo.processInfo.systemUptime)
      guard self.policy.shouldTerminate(now: ProcessInfo.processInfo.systemUptime) else { return }
      NSApp.terminate(nil)
    }
  }

  func beginActivity() -> BackgroundActivity {
    let id = UUID()
    policy.begin(id)
    refresh()
    return BackgroundActivity(id: id)
  }

  fileprivate func finishActivity(_ id: UUID) {
    policy.finish(id, now: ProcessInfo.processInfo.systemUptime)
    refresh()
  }
}

/// Finish in a defer, including permission failures, cancellation and snippet rendering.
struct BackgroundActivity: Sendable {
  fileprivate let id: UUID
  static func begin() async -> Self { await ApplicationLifetime.shared.beginActivity() }
  func finish() {
    Task { @MainActor in ApplicationLifetime.shared.finishActivity(id) }
  }
}
