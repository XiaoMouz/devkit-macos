import Foundation

public enum JsonSchemaTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "json-schema", "JSON Schema", .structured, "Draft 2020-12 校验；只使用本地引用，不获取远程 Schema。",
    sample: "{\"name\":\"DevKit\",\"version\":1}",
    secondary:
      "{\"$schema\":\"https://json-schema.org/draft/2020-12/schema\",\"type\":\"object\",\"required\":[\"name\"],\"properties\":{\"name\":{\"type\":\"string\"}}}",
    input: .pair, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("json-schema", input: input, options: options)
  }
}
