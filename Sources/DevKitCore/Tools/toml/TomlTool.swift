import Foundation

public enum TomlTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "format"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "toml", "TOML", .structured, "TOML 1.1 解析、校验与格式化。",
    sample: "title = \"DevKit\"\n[app]\nversion = 1\n", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["format", "validate", "json"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("toml", input: input, options: options)
  }
}
