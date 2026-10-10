import Foundation

public enum YamlTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "format"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "yaml", "YAML", .structured, "YAML 1.2 格式化、校验和多文档解析。",
    sample: "name: DevKit\ntools:\n  - base64\n  - json\n", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["format", "validate", "json"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("yaml", input: input, options: options)
  }
}
