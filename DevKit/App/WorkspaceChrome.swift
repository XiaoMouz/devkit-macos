import AppKit
import SwiftUI

enum WorkspaceChromeMetrics {
  static let sidebarWidth: CGFloat = 188
  static let headerHeight: CGFloat = 44
}

/// System and custom modes share the same background-only opacity path.
struct WorkspaceGlass: NSViewRepresentable {
  @AppStorage("glassMode") private var mode = GlassMode.system.rawValue
  @AppStorage("glassTransparency") private var transparency = 0.55
  func makeNSView(context: Context) -> GlassBandView { GlassBandView() }
  func updateNSView(_ view: GlassBandView, context: Context) {
    view.configure(mode: GlassMode(rawValue: mode) ?? .system, transparency: transparency)
  }
  static func dismantleNSView(_ view: GlassBandView, coordinator: ()) { view.stopObserving() }
}
final class GlassBandView: NSView {
  private let backdrop = NSVisualEffectView()
  private let glass = NSGlassEffectView()
  private let surface = NSView()
  private var mode = GlassMode.system
  private var customTransparency = 0.55
  private var refreshTimer: Timer?
  private(set) var presentation = GlassPresentation(mode: .system, customTransparency: 0.55,
    systemTint: nil, reduceTransparency: false)

  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.masksToBounds = true
    backdrop.material = .underWindowBackground
    backdrop.blendingMode = .behindWindow
    backdrop.state = .followsWindowActiveState
    glass.cornerRadius = 0
    surface.wantsLayer = true
    for view in [backdrop, glass, surface] {
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
      // Keep the glass rim outside the window's own rounding.
      let inset: CGFloat = view === glass ? 16 : 0
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -inset),
        view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: inset),
        view.topAnchor.constraint(equalTo: topAnchor, constant: -inset),
        view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: inset),
      ])
    }
  }
  required init?(coder: NSCoder) { nil }

  func configure(mode: GlassMode, transparency: Double) {
    self.mode = mode
    customTransparency = transparency
    updateObservation()
    refresh()
  }
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    updateObservation()
    refresh()
  }
  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    render()
  }
  private func updateObservation() {
    stopObserving()
    guard window != nil else { return }
    NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(preferencesChanged),
      name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(preferencesChanged),
      name: NSApplication.didBecomeActiveNotification, object: nil)
    // There is no public notification for the numeric Liquid Glass setting. Refresh
    // while attached, including while System Settings is active, and stop in custom mode.
    if mode == .system {
      let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
        Task { @MainActor [weak self] in self?.refresh() }
      }
      timer.tolerance = 0.2
      refreshTimer = timer
      RunLoop.main.add(timer, forMode: .common)
    }
  }
  func stopObserving() {
    refreshTimer?.invalidate()
    refreshTimer = nil
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    NotificationCenter.default.removeObserver(self)
  }
  @objc private func preferencesChanged(_ notification: Notification) { refresh() }
  private func refresh() {
    let next = GlassPresentation(mode: mode, customTransparency: customTransparency,
      systemTint: mode == .system ? SystemGlassPreferences.tintAmount() : nil,
      reduceTransparency: NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency)
    guard next != presentation else { return }
    presentation = next
    render()
  }
  private func render() {
    glass.style = presentation.usesNativeStyle ? .regular : .clear
    let opaque = presentation.surfaceOpacity == 1
    backdrop.isHidden = opaque
    glass.isHidden = opaque
    // Resolve the dynamic color in this view's appearance, never the current global
    // drawing context. This keeps forced dark and return-to-system transitions consistent.
    effectiveAppearance.performAsCurrentDrawingAppearance {
      surface.layer?.backgroundColor = NSColor.windowBackgroundColor
        .withAlphaComponent(presentation.surfaceOpacity).cgColor
    }
  }
}

/// Align our control to AppKit's traffic lights, without moving the system buttons.
struct WorkspaceSidebarControl: NSViewRepresentable {
  let sidebarVisible: Bool
  let toggle: () -> Void
  func makeNSView(context: Context) -> SidebarControlView { SidebarControlView() }
  func updateNSView(_ view: SidebarControlView, context: Context) {
    view.toggle = toggle
    view.button.setAccessibilityValue(sidebarVisible ? "展开" : "收起")
    view.needsLayout = true
  }
  final class SidebarControlView: NSView {
    let button = NSButton()
    var toggle: (() -> Void)?
    override init(frame: NSRect) {
      super.init(frame: frame)
      button.setButtonType(.momentaryChange)
      button.isBordered = false
      button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "收放工具列表")
      button.imagePosition = .imageOnly
      button.contentTintColor = .secondaryLabelColor
      button.target = self
      button.action = #selector(toggleSidebar)
      button.toolTip = "收放工具列表"
      button.setAccessibilityLabel("收放工具列表")
      addSubview(button)
    }
    required init?(coder: NSCoder) { nil }
    @objc private func toggleSidebar() { toggle?() }
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      NotificationCenter.default.removeObserver(self)
      if let window {
        for name in [NSWindow.didResizeNotification, NSWindow.didBecomeKeyNotification,
          NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification] {
          NotificationCenter.default.addObserver(self, selector: #selector(geometryChanged), name: name, object: window)
        }
        for kind in [NSWindow.ButtonType.closeButton, .zoomButton] {
          if let light = window.standardWindowButton(kind) {
            light.postsFrameChangedNotifications = true
            NotificationCenter.default.addObserver(self, selector: #selector(geometryChanged),
              name: NSView.frameDidChangeNotification, object: light)
          }
        }
      }
      needsLayout = true
    }
    @objc private func geometryChanged(_ notification: Notification) { needsLayout = true }
    override func layout() {
      super.layout()
      guard let window else { return }
      var center = NSPoint(x: 100, y: bounds.midY)
      if !window.styleMask.contains(.fullScreen),
        let close = window.standardWindowButton(.closeButton),
        let zoom = window.standardWindowButton(.zoomButton) {
        let closeRect = convert(close.bounds, from: close)
        let zoomRect = convert(zoom.bounds, from: zoom)
        center = NSPoint(x: zoomRect.maxX + 26, y: closeRect.midY)
      }
      button.frame = NSRect(x: center.x - 14, y: center.y - 12, width: 28, height: 24)
    }
  }
}

struct WorkspaceWindowChrome: NSViewRepresentable {
  func makeNSView(context: Context) -> ChromeProbe { ChromeProbe() }
  func updateNSView(_ view: ChromeProbe, context: Context) { view.configure() }
  final class ChromeProbe: NSView {
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      configure()
    }
    func configure() {
      guard let window else { return }
      window.titleVisibility = .hidden
      window.titlebarAppearsTransparent = true
      window.titlebarSeparatorStyle = .none
      if !window.styleMask.contains(.fullSizeContentView) { window.styleMask.insert(.fullSizeContentView) }
      window.isOpaque = false
      window.backgroundColor = .clear
      window.isMovableByWindowBackground = true
      window.tabbingMode = .disallowed
    }
  }
}
