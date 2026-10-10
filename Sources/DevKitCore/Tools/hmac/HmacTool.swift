import CryptoKit
import Foundation

public enum HmacTool: ToolModule {
  public struct Options: ToolOptions {
    public var algorithm: String = "SHA-256"
    public var key: String = ""
    public var keyFormat: String = "utf8"
    public var output: String = "hex"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "hmac", "HMAC", .security, "SHA-256 / SHA-512 消息认证码；密钥仅在当前会话中使用。", sample: "hello",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("algorithm", "算法", \.algorithm, choices: ["SHA-256", "SHA-512"]),
      .init("key", "密钥", \.key, secret: true),
      .init("keyFormat", "密钥格式", \.keyFormat, choices: ["utf8", "hex", "base64"]),
      .init("output", "输出", \.output, choices: ["hex", "base64"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let keyData =
      try options.keyFormat == "hex"
      ? unhex(options.key)
      : options.keyFormat == "base64" ? Base64Codec.decode(options.key) : Data(options.key.utf8)
    try require(!keyData.isEmpty, "请输入密钥。")
    let key = SymmetricKey(data: keyData)
    let mac =
      options.algorithm == "SHA-512"
      ? Data(HMAC<SHA512>.authenticationCode(for: input.bytes, using: key))
      : Data(HMAC<SHA256>.authenticationCode(for: input.bytes, using: key))
    return ToolOutput(options.output == "base64" ? mac.base64EncodedString() : hex(mac))
  }
}
