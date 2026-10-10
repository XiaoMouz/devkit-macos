import Foundation

public enum CsvTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "format"
    public var delimiter: String = ","
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "csv", "CSV 与 TSV", .structured, "RFC 4180 引号与换行，表格行预览和 JSON 导出。",
    sample: "name,role\nAda,developer\nLin,designer", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["format", "json", "transpose"]),
      .init("delimiter", "分隔符", \.delimiter, choices: [",", "tab", ";", "|"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("csv", input: input, options: options)
  }
}
