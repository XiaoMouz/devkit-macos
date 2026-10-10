import Foundation

public enum JsonTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "format"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "json", "JSON 工作台", .structured, "精确保留数字；格式化、压缩、校验与路径树。",
    sample: "{\"name\":\"DevKit\",\"number\":9007199254740993}", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["format", "minify", "validate", "tree"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("json", input: input, options: options)
  }
}
