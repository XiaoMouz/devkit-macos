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
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.verify || field.id != "key" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let parts = input.text.trimmingCharacters(in: .whitespacesAndNewlines).split(
      separator: ".", omittingEmptySubsequences: false)
    try require(parts.count == 3, "JWT 必须由三个以 . 分隔的部分组成。")
    let header = try jsonObject(utf8(Base64Codec.decode(String(parts[0]), urlSafe: true)))
    let payload = try jsonObject(utf8(Base64Codec.decode(String(parts[1]), urlSafe: true)))
    guard let headerValues = header as? [String: Any], let values = payload as? [String: Any] else {
      throw ToolFailure("JWT Header 和 Payload 必须是 JSON 对象。")
    }
    let now = Date().timeIntervalSince1970
    var temporalIssues = [String]()
    for key in ["iat", "exp", "nbf"] where values[key] != nil {
      guard let number = values[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
        number.doubleValue.isFinite else { throw ToolFailure("\(key) 必须是数值时间戳。") }
      if key == "exp", now >= number.doubleValue { temporalIssues.append("已过期") }
      if key == "nbf", now < number.doubleValue { temporalIssues.append("尚未生效") }
    }
    var rows = [
      ResultRow("Header", try prettyJSON(header)), ResultRow("Payload", try prettyJSON(payload)),
    ]
    var state = "未验证签名；不要仅凭解析结果信任令牌。"
    var verification: ResultReport?
    var html: String?
    if options.verify {
      try require(
        headerValues["alg"] as? String == "HS256", "此验证入口只接受 alg=HS256，拒绝算法替换。")
      try require(!options.key.isEmpty, "请输入验签密钥。")
      let signature = try Base64Codec.decode(String(parts[2]), urlSafe: true)
      let valid = HMAC<SHA256>.isValidAuthenticationCode(
        signature, authenticating: Data("\(parts[0]).\(parts[1])".utf8),
        using: SymmetricKey(data: Data(options.key.utf8)))
      state = valid ? "HS256 签名有效；仍需检查 exp、aud、iss 等业务声明。" : "签名无效"
      verification = ResultReport(valid ? "success" : "failure", valid ? "JWT 签名校验通过" : "JWT 签名校验未通过",
        valid ? "签名与当前密钥匹配，仍需检查过期时间、受众和签发者。" : "签名与当前密钥不匹配，请检查令牌内容及密钥。",
        metrics: [ResultRow("算法", "HS256"), ResultRow("签名", valid ? "有效" : "无效")])
      if valid && !temporalIssues.isEmpty {
        state = "HS256 签名有效；令牌" + temporalIssues.joined(separator: "、") + "。"
        verification = ResultReport("warning", "签名有效，但令牌" + temporalIssues.joined(separator: "、"),
          "签名校验不代表令牌当前可用；仍需核对 aud、iss 等业务声明。",
          metrics: [ResultRow("签名", "有效"), ResultRow("时间声明", temporalIssues.joined(separator: "、"))])
      }
      rows.append(ResultRow("签名", state))
      html = ComparisonPreview.documents([
        ("令牌内容", [(text: "头部：" + rows[0].value, kind: ""), (text: "载荷：" + rows[1].value, kind: "")]),
        ("签名校验", [(text: String(parts[2]), kind: valid ? "add" : "error"), (text: state, kind: valid ? "" : "error")]),
      ])
    }
    if !temporalIssues.isEmpty { rows.append(ResultRow("时间声明（未验证业务可信性）", temporalIssues.joined(separator: "、"))) }
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
