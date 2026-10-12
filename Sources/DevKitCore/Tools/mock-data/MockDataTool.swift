import Foundation

public enum MockDataTool: ToolModule {
  public struct Options: ToolOptions {
    public var count: Int = 10
    public var seed: Int = 42
    public var format: String = "json"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "mock-data", "Mock Data", .generators, "Generate JSON or CSV from field templates, with seeds for reproducible test data.",
    sample:
      "{\"id\":\"index\",\"name\":\"name\",\"email\":\"email\",\"active\":\"boolean\",\"score\":\"integer\"}",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("count", L10n.tr("Rows"), \.count, range: 1...10000),
      .init("seed", L10n.tr("Reproducible Seed"), \.seed, range: 0...2_147_483_647),
      .init("format", L10n.tr("Output Format"), \.format, choices: ["json", "csv"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("mock-data", input: input, options: options)
  }
}
