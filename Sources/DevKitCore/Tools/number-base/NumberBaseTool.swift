import Foundation

public enum NumberBaseTool: ToolModule {
  public struct Options: ToolOptions {
    public var from: String = "10"
    public var to: String = "16"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "number-base", "进制转换", .numbers, "基于大整数精确转换，支持正负数；不隐式套用补码。", sample: "255", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("from", "源进制", \.from, choices: ["2", "8", "10", "16"]),
      .init("to", "目标进制", \.to, choices: ["2", "8", "10", "16"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("number-base", input: input, options: options)
  }
}
