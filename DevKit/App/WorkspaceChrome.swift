import AppKit
import SwiftUI

enum WorkspaceChromeMetrics {
  static let sidebarWidth: CGFloat = 188
  static let headerHeight: CGFloat = 44
}

/// A restrained native sidebar material. Its appearance must follow SwiftUI explicitly:
/// a representable's inherited AppKit appearance can lag an in-app theme override.
struct WorkspaceGlass: NSViewRepresentable {
  @AppStorage("glassTransparency") private var transparency = 0.55
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  func makeNSView(context: Context) -> GlassBandView { GlassBandView() }
  func updateNSView(_ view: GlassBandView, context: Context) {
    view.configure(dark: colorScheme == .dark,
      transparency: reduceTransparency ? 0 : min(0.85, max(0, transparency)))
  }
}
final class GlassBandView: NSView {
  private let backdrop = NSVisualEffectView()
  private let tint = NSView()
  override init(frame: NSRect) {
    super.init(frame: frame)
    backdrop.material = .sidebar
    backdrop.blendingMode = .behindWindow
    backdrop.state = .followsWindowActiveState
    tint.wantsLayer = true
    for view in [backdrop, tint] {
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.topAnchor.constraint(equalTo: topAnchor),
        view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }
  }
  required init?(coder: NSCoder) { nil }
  func configure(dark: Bool, transparency: Double) {
    let resolvedAppearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    appearance = resolvedAppearance
    backdrop.appearance = resolvedAppearance
    backdrop.isHidden = transparency == 0
    // Keep a legible neutral base even over a white wallpaper or an inactive window.
    // The preference adjusts material strength, never foreground or whole-window opacity.
    let base = NSColor(srgbRed: dark ? 0.135 : 0.955,
      green: dark ? 0.135 : 0.955, blue: dark ? 0.14 : 0.965, alpha: 1)
    tint.layer?.backgroundColor = base.withAlphaComponent(1 - transparency * 0.25).cgColor
  }
}
struct WorkspaceWindowChrome: NSViewRepresentable {
  func makeNSView(context: Context) -> ChromeProbe { ChromeProbe() }
  func updateNSView(_ view: ChromeProbe, context: Context) { view.configure() }
  final class ChromeProbe: NSView {
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      NotificationCenter.default.removeObserver(self)
      if let window {
        for name in [NSWindow.didResizeNotification, NSWindow.didBecomeKeyNotification,
          NSWindow.didExitFullScreenNotification] {
          NotificationCenter.default.addObserver(self, selector: #selector(windowChanged), name: name, object: window)
        }
        // AppKit may lay these out again after a theme or window-state change.
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
          if let button = window.standardWindowButton(kind) {
            button.postsFrameChangedNotifications = true
            NotificationCenter.default.addObserver(self, selector: #selector(windowChanged),
              name: NSView.frameDidChangeNotification, object: button)
          }
        }
      }
      configure()
    }
    override func layout() {
      super.layout()
      alignWindowButtons()
    }
    @objc private func windowChanged(_ notification: Notification) { scheduleAlignment() }
    func configure() {
      guard let window else { return }
      window.titleVisibility = .hidden
      window.titlebarAppearsTransparent = true
      window.titlebarSeparatorStyle = .none
      window.styleMask.insert(.fullSizeContentView)
      window.isOpaque = false
      window.backgroundColor = .clear
      window.isMovableByWindowBackground = true
      window.tabbingMode = .disallowed
      scheduleAlignment()
    }
    private func scheduleAlignment() {
      DispatchQueue.main.async { [weak self] in self?.alignWindowButtons() }
    }
    private func alignWindowButtons() {
      guard let window, !window.styleMask.contains(.fullScreen) else { return }
      let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
      for (index, kind) in buttons.enumerated() {
        guard let button = window.standardWindowButton(kind), let parent = button.superview else { continue }
        let center = parent.convert(NSPoint(
          x: 14 + CGFloat(index) * 20 + button.frame.width / 2,
          y: window.frame.height - WorkspaceChromeMetrics.headerHeight / 2), from: nil)
        let origin = NSPoint(x: center.x - button.frame.width / 2, y: center.y - button.frame.height / 2)
        if abs(button.frame.minX - origin.x) > 0.25 || abs(button.frame.minY - origin.y) > 0.25 {
          button.setFrameOrigin(origin)
        }
      }
    }
  }
}
