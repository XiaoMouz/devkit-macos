import CoreFoundation
import Foundation

enum GlassMode: String {
  case system, custom
}

struct GlassPresentation: Equatable {
  /// nil delegates to native glass on systems without a readable numeric preference.
  let transparency: Double?
  let reduceTransparency: Bool
  /// Regular glass is always present for navigation text legibility. The preference
  /// changes only the supplementary native blur, never the glass layer's opacity.
  var frosting: Double { transparency.map { 1 - $0 } ?? 1 }
  // Dense navigation keeps a semantic material beneath its labels, even when
  // the user's glass setting is at its clearest. Only the extra frosting varies.
  var backdropWeight: Double { reduceTransparency ? 0 : 0.65 + 0.35 * frosting }
  var opaqueFallback: Bool { reduceTransparency }
  var usesNativeStyle: Bool { transparency == nil }

  init(mode: GlassMode, customTransparency: Double, systemTint: Double?, reduceTransparency: Bool) {
    self.reduceTransparency = reduceTransparency
    if mode == .custom {
      transparency = Self.clamp(customTransparency.isFinite ? customTransparency : 0.55)
    } else {
      transparency = systemTint.flatMap { $0.isFinite ? 1 - Self.clamp($0) : nil }
    }
  }
  private static func clamp(_ value: Double) -> Double { min(1, max(0, value)) }
}

enum SystemGlassPreferences {
  /// Observed in macOS 27's global appearance preferences. This key is not a public
  /// AppKit contract: keep the bridge read-only and fall back to native glass if absent.
  /// Never write this setting or persist a system value in the user's custom setting.
  static func tintAmount(domain: CFString = kCFPreferencesAnyApplication) -> Double? {
    CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    guard let value = CFPreferencesCopyValue("NSGlassTintAmount" as CFString, domain,
      kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? NSNumber,
      value.doubleValue.isFinite else { return nil }
    return min(1, max(0, value.doubleValue))
  }
}
