import Foundation

public enum JsonPathTool: ToolModule {
  public struct Options: ToolOptions {
    public var syntax: String = "jsonpath"
    public var path: String = "$.users[*].name"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "json-path", "JSON 路径", .structured, "JSON Pointer / JSONPath Plus 查询；禁用脚本求值。",
    sample: "{\"users\":[{\"name\":\"Ada\"},{\"name\":\"Lin\"}]}", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("syntax", "语法", \.syntax, choices: ["jsonpath", "pointer"]),
      .init("path", "路径", \.path),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("json-path", input: input, options: options)
  }
}
