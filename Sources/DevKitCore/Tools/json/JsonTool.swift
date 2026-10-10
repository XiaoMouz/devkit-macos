import Foundation

public enum JsonTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation = "format"
    public var syntax = "jsonpath" {
      didSet { if syntax != oldValue { path = syntax == "pointer" ? "" : "$" } }
    }
    public var path = "$"
    public var name = "Root"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "json", "JSON 工作台", .structured, "格式化、压缩、JSONPath / Pointer、结构对比、Schema 校验与 TypeScript 类型。",
    sample: "{\"name\":\"DevKit\",\"version\":1,\"users\":[{\"id\":1,\"name\":\"Ada\"}]}")
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "功能", \.operation,
        choices: ["format", "minify", "validate", "tree", "query", "diff", "schema", "typescript"]),
      .init("syntax", "查询语法", \.syntax, choices: ["jsonpath", "pointer"]),
      .init("path", "查询路径", \.path),
      .init("name", "TypeScript 类型名称", \.name),
    ]
  }
  public static func inputStyle(for options: Options) -> InputStyle {
    ["diff", "schema"].contains(options.operation) ? .pair : .text
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in
      field.id == "operation" || (options.operation == "query" && ["syntax", "path"].contains(field.id))
        || (options.operation == "typescript" && field.id == "name")
    }
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: metadata.sample, secondary: options.operation == "schema"
      ? "{\"type\":\"object\",\"required\":[\"name\"],\"properties\":{\"name\":{\"type\":\"string\"}}}"
      : "{\"name\":\"DevKit\",\"version\":2,\"users\":[{\"id\":1,\"name\":\"Lin\"}]}")
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let engine: String
    switch options.operation {
    case "format", "minify", "validate", "tree": engine = "json"
    case "query": engine = "json-path"
    case "diff": engine = "json-diff"
    case "schema": engine = "json-schema"
    case "typescript": engine = "json-to-model"
    default: throw ToolFailure("不支持的 JSON 操作。")
    }
    return try ScriptEngine.execute(engine, input: input, options: options)
  }
}
