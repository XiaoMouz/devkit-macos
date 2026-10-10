import Foundation

public enum MockDataTool: ToolModule {
  public struct Options: ToolOptions {
    public var count: Int = 10
    public var seed: Int = 42
    public var format: String = "json"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "mock-data", "Mock 数据", .generators, "字段模板生成 JSON / CSV；按种子生成可复现测试数据。",
    sample:
      "{\"id\":\"index\",\"name\":\"name\",\"email\":\"email\",\"active\":\"boolean\",\"score\":\"integer\"}",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("count", "条数", \.count, range: 1...10000),
      .init("seed", "可重复种子", \.seed, range: 0...2_147_483_647),
      .init("format", "格式", \.format, choices: ["json", "csv"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("mock-data", input: input, options: options)
  }
}
