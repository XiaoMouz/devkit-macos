import CryptoKit
import Foundation

public enum JwtTool: ToolModule {
  public struct Options: ToolOptions {
    public var verify: Bool = false
    public var key: String = ""
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "jwt", "JWT Workspace", .security, "Parse Header and Payload, with optional HS256 signature verification. Parsing does not imply trust.",
    sample:
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFkYSJ9.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("verify", L10n.tr("Verify HS256 Signature"), \.verify),
      .init("key", L10n.tr("HS256 Key"), \.key, secret: true),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.verify || field.id != "key" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let parts = input.text.trimmingCharacters(in: .whitespacesAndNewlines).split(
      separator: ".", omittingEmptySubsequences: false)
    try require(parts.count == 3, L10n.tr("JWT must have three parts separated by periods."))
    let header = try jsonObject(utf8(Base64Codec.decode(String(parts[0]), urlSafe: true)))
    let payload = try jsonObject(utf8(Base64Codec.decode(String(parts[1]), urlSafe: true)))
    guard let headerValues = header as? [String: Any], let values = payload as? [String: Any] else {
      throw ToolFailure(L10n.tr("JWT Header and Payload must be JSON objects."))
    }
    let now = Date().timeIntervalSince1970
    var temporalIssues = [String]()
    for key in ["iat", "exp", "nbf"] where values[key] != nil {
      guard let number = values[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
        number.doubleValue.isFinite else { throw ToolFailure(L10n.tr("\(key) must be a numeric timestamp.")) }
      if key == "exp", now >= number.doubleValue { temporalIssues.append(L10n.tr("Expired")) }
      if key == "nbf", now < number.doubleValue { temporalIssues.append(L10n.tr("Not Yet Valid")) }
    }
    var rows = [
      ResultRow(L10n.tr("Header"), try prettyJSON(header)), ResultRow(L10n.tr("Payload"), try prettyJSON(payload)),
    ]
    var state = L10n.tr("Signature not verified. Do not trust a token based only on its parsed content.")
    var verification: ResultReport?
    var html: String?
    if options.verify {
      try require(
        headerValues["alg"] as? String == "HS256", L10n.tr("This verifier only accepts alg=HS256 and rejects algorithm substitution."))
      try require(!options.key.isEmpty, L10n.tr("Enter the verification key."))
      let signature = try Base64Codec.decode(String(parts[2]), urlSafe: true)
      let valid = HMAC<SHA256>.isValidAuthenticationCode(
        signature, authenticating: Data("\(parts[0]).\(parts[1])".utf8),
        using: SymmetricKey(data: Data(options.key.utf8)))
      state = valid ? L10n.tr("Valid HS256 signature. Still check application claims such as exp, aud, and iss.") : L10n.tr("Invalid Signature")
      verification = ResultReport(valid ? "success" : "failure", valid ? L10n.tr("JWT Signature Verification Passed") : L10n.tr("JWT Signature Verification Failed"),
        valid ? L10n.tr("The signature matches the current key. Still check expiration, audience, and issuer.") : L10n.tr("The signature does not match the current key. Check the token and key."),
        metrics: [ResultRow(L10n.tr("Algorithm"), "HS256"), ResultRow(L10n.tr("Signature"), valid ? L10n.tr("Valid") : L10n.tr("Invalid"))])
      if valid && !temporalIssues.isEmpty {
        state = L10n.tr("Valid HS256 signature; token ") + temporalIssues.joined(separator: "、") + "。"
        verification = ResultReport("warning", L10n.tr("Valid signature, but token ") + temporalIssues.joined(separator: "、"),
          L10n.tr("Signature verification does not guarantee the token is currently usable. Still check application claims such as aud and iss."),
          metrics: [ResultRow(L10n.tr("Signature"), L10n.tr("Valid")), ResultRow(L10n.tr("Time Claims"), temporalIssues.joined(separator: "、"))])
      }
      rows.append(ResultRow(L10n.tr("Signature"), state))
      html = ComparisonPreview.documents([
        (L10n.tr("Token Content"), [(text: L10n.tr("Header: ") + rows[0].value, kind: ""), (text: L10n.tr("Payload: ") + rows[1].value, kind: "")]),
        (L10n.tr("Signature Verification"), [(text: String(parts[2]), kind: valid ? "add" : "error"), (text: state, kind: valid ? "" : "error")]),
      ])
    }
    if !temporalIssues.isEmpty { rows.append(ResultRow(L10n.tr("Time Claims (Application Trust Not Verified)"), temporalIssues.joined(separator: "、"))) }
    do {
      for key in ["iat", "exp", "nbf"] {
        if let n = values[key] as? NSNumber, abs(n.doubleValue) < 253_402_300_800 {
          rows.append(ResultRow("\(key) · \(Dates.zoneLabel(.current, at: Date(timeIntervalSince1970: n.doubleValue)))", Dates.display(Date(timeIntervalSince1970: n.doubleValue))))
        }
      }
    }
    return ToolOutput(
      rows.map { "\($0.label)\n\($0.value)" }.joined(separator: "\n\n"), rows: rows, html: html, note: state, report: verification)
  }
}
