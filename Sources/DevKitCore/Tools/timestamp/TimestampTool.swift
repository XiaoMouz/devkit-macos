import Foundation

public enum TimestampTool: ToolModule {
  public struct Options: ToolOptions {
    public var unit: String = "seconds"
    public var timezone: String = "Asia/Shanghai"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "timestamp", "时间戳", .numbers, "Unix 秒 / 毫秒与 ISO 8601，空输入使用当前时间。", sample: "1700000000",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("unit", "时间戳单位", \.unit, choices: ["seconds", "milliseconds"]),
      .init("timezone", "时区", \.timezone),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let value = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    let date: Date
    if value.isEmpty {
      date = Date()
    } else if let n = Double(value), n.isFinite {
      date = Date(timeIntervalSince1970: n / (options.unit == "milliseconds" ? 1000 : 1))
    } else {
      guard let parsed = Dates.parse(value) else {
        throw ToolFailure("请输入 Unix 时间戳或带时区的 ISO 8601 日期。")
      }
      date = parsed
    }
    try require(abs(date.timeIntervalSince1970) < 253_402_300_800, "日期超出支持范围。")
    guard let zone = TimeZone(identifier: options.timezone) else {
      throw ToolFailure("时区无效，例如 Asia/Shanghai 或 UTC。")
    }
    let format = DateFormatter()
    format.locale = Locale(identifier: "en_US_POSIX")
    format.timeZone = zone
    format.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS XXX"
    let rows = [
      ResultRow("Unix 秒", String(format: "%.3f", date.timeIntervalSince1970)),
      ResultRow("Unix 毫秒", String(Int64((date.timeIntervalSince1970 * 1000).rounded()))),
      ResultRow("ISO 8601", Dates.iso(date)),
      ResultRow(options.timezone, format.string(from: date)),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
