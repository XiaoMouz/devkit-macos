import Foundation
import Security

/// Discovery metadata can be indexed from an ad-hoc build even when linkd rejects
/// its runtime connection. A team identifier is a prerequisite, not an end-to-end test.
struct SpotlightRuntimeStatus: Sendable {
  let teamIdentifier: String?
  static let current = inspect()
  var hasDeveloperIdentity: Bool { teamIdentifier?.isEmpty == false }
  var issue: String? {
    hasDeveloperIdentity ? nil : "当前为临时签名构建，macOS 无法验证开发者团队，因此拒绝 Spotlight 执行动作。需要使用 Apple 开发证书重新签名；工具箱可正常使用。"
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
