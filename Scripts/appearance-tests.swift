import AppKit

@main struct AppearanceRegression {
  @MainActor static func main() {
    let app = NSApplication.shared
    app.finishLaunching()
    let system = app.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
    let windows = (0..<3).map { _ in
      let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      window.contentView = NSTextView()
      return window
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
