import Foundation

public enum TimestampTool: ToolModule {
  public struct Options: ToolOptions {
    public var unit: String = "seconds"
    public var timezone: String = TimeZone.current.identifier
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "timestamp", "时间戳", .numbers, "Unix 秒 / 毫秒与日期时间互转，按所选时区显示。", sample: "1700000000",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("unit", "时间戳单位", \.unit, choices: ["seconds", "milliseconds"]),
      .init("timezone", "时区", \.timezone),
    ]
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: options.unit == "milliseconds" ? "1700000000000" : metadata.sample)
  }
  public static func date(from text: String, options: Options) throws -> Date {
    try require(["seconds", "milliseconds"].contains(options.unit), "请选择秒或毫秒。")
    guard let zone = TimeZone(identifier: options.timezone) else { throw ToolFailure("请选择有效时区。") }
    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let date: Date
    if value.isEmpty { date = Date() }
    else if let n = Double(value), n.isFinite {
      date = Date(timeIntervalSince1970: n / (options.unit == "milliseconds" ? 1000 : 1))
    } else {
      guard let parsed = Dates.parse(value, timeZone: zone) else {
        throw ToolFailure("请输入有效时间戳，或选择日期时间（例如 2026-10-12 09:00:00）。")
      }
      date = parsed
    }
    try require(Dates.supportedRange.contains(date), "日期超出支持范围（0001–9999 年）。")
    return date
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let date = try date(from: input.text, options: options)
    let zone = TimeZone(identifier: options.timezone)!
    let rows = [
      ResultRow("日期时间", Dates.display(date, timeZone: zone, milliseconds: true)),
      ResultRow("时区", Dates.zoneLabel(zone, at: date)),
      ResultRow("Unix 秒", Dates.timestamp(date, milliseconds: false)),
      ResultRow("Unix 毫秒", Dates.timestamp(date, milliseconds: true)),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
