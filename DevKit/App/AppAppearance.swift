import AppKit

/// A single appearance owner for SwiftUI, AppKit editors, settings and detached windows.
/// Windows and views inherit it; nil releases the override and resumes live system changes.
@MainActor enum AppAppearance {
  static func apply(_ preference: String) {
    switch preference {
    case "light": NSApp.appearance = NSAppearance(named: .aqua)
    case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
    default: NSApp.appearance = nil
    }
  }
}
