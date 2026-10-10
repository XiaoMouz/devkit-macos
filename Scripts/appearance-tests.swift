import AppKit
import CoreFoundation

@main struct AppearanceRegression {
  @MainActor static func main() {
    let app = NSApplication.shared
    app.finishLaunching()
    let system = app.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
    let domain = "app.devkit.glass-tests." + UUID().uuidString
    defer {
      CFPreferencesSetValue("NSGlassTintAmount" as CFString, nil, domain as CFString,
        kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
      CFPreferencesSynchronize(domain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }
    for tint in [0.0, 0.5, 1.0, 0.0] {
      CFPreferencesSetValue("NSGlassTintAmount" as CFString, NSNumber(value: tint), domain as CFString,
        kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
      CFPreferencesSynchronize(domain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
      let read = SystemGlassPreferences.tintAmount(domain: domain as CFString)
      precondition(read == tint)
      let systemStyle = GlassPresentation(mode: .system, customTransparency: 0.8,
        systemTint: read, reduceTransparency: false)
      precondition(systemStyle.frosting == tint && !systemStyle.opaqueFallback)
    }
    let transparent = GlassPresentation(mode: .custom, customTransparency: 1, systemTint: 1, reduceTransparency: false)
    let frosted = GlassPresentation(mode: .custom, customTransparency: 0, systemTint: 0, reduceTransparency: false)
    precondition(transparent.backdropWeight > 0 && transparent.backdropWeight < frosted.backdropWeight)
    precondition(frosted.backdropWeight == 1)
    // A real native view must retain Regular glass at every slider position;
    // a pure state-mapping check would miss a disappearing legibility layer.
    let band = GlassBandView(frame: NSRect(x: 0, y: 0, width: 188, height: 500))
    for value in [1.0, 0.5, 0.0, 1.0] {
      band.configure(mode: .custom, transparency: value)
      let materials = band.subviews.compactMap { $0 as? NSGlassEffectView }
      precondition(materials.count == 1)
      precondition(materials[0].style == .regular && materials[0].alphaValue == 1)
      precondition(materials[0].isHidden == NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency)
    }
    precondition(!transparent.opaqueFallback && !frosted.opaqueFallback)
    precondition(GlassPresentation(mode: .system, customTransparency: 0.8, systemTint: nil,
      reduceTransparency: false).usesNativeStyle)
    precondition(GlassPresentation(mode: .custom, customTransparency: 1, systemTint: nil,
      reduceTransparency: true).opaqueFallback)
    precondition(GlassPresentation(mode: .custom, customTransparency: .nan, systemTint: nil,
      reduceTransparency: false).transparency == 0.55)
    print("PASS: all slider positions retain Regular glass, system refresh and accessibility fallback")
    let windows = (0..<3).map { _ in
      let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      window.contentView = NSTextView()
      return window
    }
    for width in [900.0, 1280.0, 1500.0] {
      let window = windows[0]
      window.setContentSize(NSSize(width: width, height: 800))
      let host = NSView(frame: window.contentView!.bounds)
      window.contentView = host
      let sidebar = WorkspaceSidebarControl.SidebarControlView(frame: NSRect(x: 0, y: host.bounds.height - 44, width: 188, height: 44))
      host.addSubview(sidebar)
      let close = window.standardWindowButton(.closeButton)!
      let originalFrame = close.frame
      sidebar.layoutSubtreeIfNeeded()
      let closeCenter = close.convert(close.bounds, to: nil).midY
      let sidebarCenter = sidebar.button.convert(sidebar.button.bounds, to: nil).midY
      precondition(abs(closeCenter - sidebarCenter) < 0.5)
      precondition(close.frame == originalFrame)
      print("PASS: traffic lights and sidebar center aligned at width \(width)")
      window.contentView = NSTextView()
    }
    for preference in ["light", "dark", "system", "dark", "light", "system"] {
      AppAppearance.apply(preference)
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
      let expected: NSAppearance.Name? = preference == "light" ? .aqua : preference == "dark" ? .darkAqua : system
      for window in windows {
        precondition(window.appearance == nil)
        precondition(window.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == expected)
        precondition(window.contentView!.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == expected)
      }
      if preference == "system" { precondition(app.appearance == nil) }
      print("PASS: \(preference) propagated to 3 windows and native text editors")
    }
  }
}
