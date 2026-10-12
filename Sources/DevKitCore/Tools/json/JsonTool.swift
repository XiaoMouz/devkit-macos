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
    "json", "JSON Workspace", .structured, "Format, minify, query with JSONPath or Pointer, compare structures, validate schemas, and generate TypeScript types.",
    sample: "{\"name\":\"DevKit\",\"version\":1,\"users\":[{\"id\":1,\"name\":\"Ada\"}]}")
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", L10n.tr("Function"), \.operation,
        choices: ["format", "minify", "validate", "tree", "query", "diff", "schema", "typescript"]),
      .init("syntax", L10n.tr("Query Syntax"), \.syntax, choices: ["jsonpath", "pointer"]),
      .init("path", L10n.tr("Query Path"), \.path),
      .init("name", L10n.tr("TypeScript Type Name"), \.name),
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
    default: throw ToolFailure(L10n.tr("Unsupported JSON operation."))
    }
    return try ScriptEngine.execute(engine, input: input, options: options)
  }
}
