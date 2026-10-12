import DevKitCore
import Foundation
import Security

/// Discovery metadata can be indexed from an ad-hoc build even when linkd rejects
/// its runtime connection. A team identifier is a prerequisite, not an end-to-end test.
struct SpotlightRuntimeStatus: Sendable {
  let teamIdentifier: String?
  static let current = inspect()
  var hasDeveloperIdentity: Bool { teamIdentifier?.isEmpty == false }
  var issue: String? {
    hasDeveloperIdentity ? nil : L10n.tr("This build uses ad hoc signing. macOS cannot verify the developer team and refuses to run Spotlight actions. Sign with an Apple development certificate; the main app works normally.")
  }
  private static func inspect() -> Self {
    var code: SecCode?
    guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return Self(teamIdentifier: nil) }
    var staticCode: SecStaticCode?
    guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return Self(teamIdentifier: nil) }
    var information: CFDictionary?
    guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
      let values = information as? [String: Any] else { return Self(teamIdentifier: nil) }
    return Self(teamIdentifier: values[kSecCodeInfoTeamIdentifier as String] as? String)
  }
}
