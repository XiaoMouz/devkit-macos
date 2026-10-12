import CryptoKit
import Foundation

public enum HashTool: ToolModule {
  public struct Options: ToolOptions {
    public var algorithm: String = "SHA-256"
    public var uppercase: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "hash", "Hash Digest", .security, "MD5 and SHA digests. MD5 and SHA-1 are for compatibility and checksums only.", sample: "hello", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("algorithm", L10n.tr("Algorithm"), \.algorithm, choices: ["MD5", "SHA-1", "SHA-256", "SHA-512"]),
      .init("uppercase", L10n.tr("Uppercase"), \.uppercase),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let value = Digest.compute(input.bytes, algorithm: options.algorithm)
    return ToolOutput(
      options.uppercase ? value.uppercased() : value,
      note: options.algorithm == "MD5" || options.algorithm == "SHA-1" ? L10n.tr("This algorithm is unsuitable for password storage or security signatures.") : nil)
  }
}
