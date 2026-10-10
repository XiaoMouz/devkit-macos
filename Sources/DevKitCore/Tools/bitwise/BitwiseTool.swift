import Foundation

public enum BitwiseTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "and"
    public var right: String = "15"
    public var bits: String = "32"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "bitwise", "位运算", .numbers, "无符号 8 / 16 / 32 / 64 位运算，超出位宽明确拒绝。", sample: "255", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["and", "or", "xor", "not", "shl", "shr"]),
      .init("right", "右操作数", \.right),
      .init("bits", "位宽", \.bits, choices: ["8", "16", "32", "64"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("bitwise", input: input, options: options)
  }
}
