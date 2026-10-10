import Foundation

public enum JsonDiffTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "json-diff", "JSON 结构对比", .structured, "保留数组顺序，按 JSON Pointer 显示新增、删除和修改。",
    sample: "{\"name\":\"DevKit\",\"version\":1}",
    secondary: "{\"name\":\"DevKit\",\"version\":2,\"ready\":true}", input: .pair, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("json-diff", input: input, options: options)
  }
}
