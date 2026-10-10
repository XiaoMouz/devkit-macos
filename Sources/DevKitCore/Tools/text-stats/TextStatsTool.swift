import Foundation

public enum TextStatsTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "text-stats", "文本统计", .text, "区分字素、Unicode 码点、UTF-16 和 UTF-8 字节。", sample: "Hello 世界 👩‍💻",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let rows = [
      ResultRow("字素", String(input.text.count)),
      ResultRow("Unicode 码点", String(input.text.unicodeScalars.count)),
      ResultRow("UTF-16 单元", String(input.text.utf16.count)),
      ResultRow("UTF-8 字节", String(input.text.utf8.count)),
      ResultRow(
        "行", String(input.text.isEmpty ? 0 : input.text.components(separatedBy: "\n").count)),
      ResultRow("词（空白分隔）", String(input.text.split(whereSeparator: { $0.isWhitespace }).count)),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
