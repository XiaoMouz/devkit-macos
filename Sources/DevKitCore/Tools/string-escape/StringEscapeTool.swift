import Foundation

public enum StringEscapeTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "string-escape", "字符串转义", .encoding, "JSON 双引号字面量转义与反转义，不执行代码。", sample: "hello \"world\"\n你好",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("string-escape", input: input, options: options)
  }
}
