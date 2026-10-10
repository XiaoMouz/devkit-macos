import Foundation

public enum UnicodeEscapeTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var style: String = "utf16"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "unicode-escape", "Unicode 转义", .encoding, "UTF-16 代理对或 Unicode 码点转换。", sample: "你好 👩‍💻",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"]),
      .init("style", "形式", \.style, choices: ["utf16", "codepoint"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("unicode-escape", input: input, options: options)
  }
}
