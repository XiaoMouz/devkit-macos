import Foundation

public enum FormatConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var from: String = "json"
    public var to: String = "yaml"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "format-convert", "数据格式互转", .structured, "JSON / YAML / TOML / CSV 互转，无法无损表达时拒绝转换。",
    sample: "{\"name\":\"DevKit\",\"version\":1}", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("from", "源格式", \.from, choices: ["json", "yaml", "toml", "csv"]),
      .init("to", "目标格式", \.to, choices: ["json", "yaml", "toml", "csv"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("format-convert", input: input, options: options)
  }
}
