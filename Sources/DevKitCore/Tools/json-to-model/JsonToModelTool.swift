import Foundation

public enum JsonToModelTool: ToolModule {
  public struct Options: ToolOptions {
    public var name: String = "Root"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "json-to-model", "TypeScript 类型生成", .structured, "从 JSON 样例推断类型；数组合并类型，不把样例视为完整 Schema。",
    sample: "{\"id\":1,\"name\":\"Ada\",\"tags\":[\"swift\"],\"profile\":null}", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("name", "类型名称", \.name)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("json-to-model", input: input, options: options)
  }
}
