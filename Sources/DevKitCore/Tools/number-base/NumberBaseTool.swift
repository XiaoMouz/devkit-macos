import Foundation

public enum NumberBaseTool: ToolModule {
  public struct Options: ToolOptions {
    public var from: String = "10"
    public var to: String = "16"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "number-base", "Number Base Conversion", .numbers, "Exact conversion with big integers, including negative values, without implicit two’s complement.", sample: "255", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("from", L10n.tr("Source Base"), \.from, choices: ["2", "8", "10", "16"]),
      .init("to", L10n.tr("Target Base"), \.to, choices: ["2", "8", "10", "16"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("number-base", input: input, options: options)
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: ["2": "11111111", "8": "377", "10": "255", "16": "ff"][options.from] ?? metadata.sample)
  }
}
