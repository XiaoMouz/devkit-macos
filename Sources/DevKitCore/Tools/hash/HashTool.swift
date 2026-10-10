import CryptoKit
import Foundation

public enum HashTool: ToolModule {
  public struct Options: ToolOptions {
    public var algorithm: String = "SHA-256"
    public var uppercase: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "hash", "哈希摘要", .security, "MD5 / SHA 摘要；MD5 和 SHA-1 仅用于兼容与校验。", sample: "hello", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("algorithm", "算法", \.algorithm, choices: ["MD5", "SHA-1", "SHA-256", "SHA-512"]),
      .init("uppercase", "大写", \.uppercase),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let value = Digest.compute(input.bytes, algorithm: options.algorithm)
    return ToolOutput(
      options.uppercase ? value.uppercased() : value,
      note: options.algorithm == "MD5" || options.algorithm == "SHA-1" ? "此算法不适合密码存储或安全签名。" : nil)
  }
}
