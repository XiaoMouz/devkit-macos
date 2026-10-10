import CryptoKit
import Foundation

public enum JwtTool: ToolModule {
  public struct Options: ToolOptions {
    public var verify: Bool = false
    public var key: String = ""
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "jwt", "JWT 工作台", .security, "解析 Header / Payload；可选 HS256 验签，解析不代表可信。",
    sample:
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFkYSJ9.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("verify", "验证 HS256 签名", \.verify),
      .init("key", "HS256 密钥", \.key, secret: true),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let parts = input.text.trimmingCharacters(in: .whitespacesAndNewlines).split(
      separator: ".", omittingEmptySubsequences: false)
    try require(parts.count == 3, "JWT 必须由三个以 . 分隔的部分组成。")
    let header = try jsonObject(utf8(Base64Codec.decode(String(parts[0]), urlSafe: true)))
    let payload = try jsonObject(utf8(Base64Codec.decode(String(parts[1]), urlSafe: true)))
    var rows = [
      ResultRow("Header", try prettyJSON(header)), ResultRow("Payload", try prettyJSON(payload)),
    ]
    var state = "未验证签名；不要仅凭解析结果信任令牌。"
    if options.verify {
      try require(
        (header as? [String: Any])?["alg"] as? String == "HS256", "此验证入口只接受 alg=HS256，拒绝算法替换。")
      try require(!options.key.isEmpty, "请输入验签密钥。")
      let signature = try Base64Codec.decode(String(parts[2]), urlSafe: true)
      let valid = HMAC<SHA256>.isValidAuthenticationCode(
        signature, authenticating: Data("\(parts[0]).\(parts[1])".utf8),
        using: SymmetricKey(data: Data(options.key.utf8)))
      state = valid ? "HS256 签名有效；仍需检查 exp、aud、iss 等业务声明。" : "签名无效"
    }
    if let values = payload as? [String: Any] {
      for key in ["iat", "exp", "nbf"] {
        if let n = values[key] as? NSNumber, abs(n.doubleValue) < 253_402_300_800 {
          rows.append(ResultRow(key, Dates.iso(Date(timeIntervalSince1970: n.doubleValue))))
        }
      }
    }
    return ToolOutput(
      rows.map { "\($0.label)\n\($0.value)" }.joined(separator: "\n\n"), rows: rows, note: state)
  }
}
