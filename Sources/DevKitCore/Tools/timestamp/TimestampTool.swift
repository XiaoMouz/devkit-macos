import Foundation

public enum TimestampTool: ToolModule {
  public struct Options: ToolOptions {
    public var unit: String = "seconds"
    public var timezone: String = TimeZone.current.identifier
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "timestamp", "Timestamp", .numbers, "Convert Unix seconds or milliseconds and dates, displayed in the selected time zone.", sample: "1700000000",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("unit", L10n.tr("Timestamp Unit"), \.unit, choices: ["seconds", "milliseconds"]),
      .init("timezone", L10n.tr("Time Zone"), \.timezone),
    ]
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: options.unit == "milliseconds" ? "1700000000000" : metadata.sample)
  }
  public static func date(from text: String, options: Options) throws -> Date {
    try require(["seconds", "milliseconds"].contains(options.unit), L10n.tr("Choose seconds or milliseconds."))
    guard let zone = TimeZone(identifier: options.timezone) else { throw ToolFailure(L10n.tr("Choose a valid time zone.")) }
    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let date: Date
    if value.isEmpty { date = Date() }
    else if let n = Double(value), n.isFinite {
      date = Date(timeIntervalSince1970: n / (options.unit == "milliseconds" ? 1000 : 1))
    } else {
      guard let parsed = Dates.parse(value, timeZone: zone) else {
        throw ToolFailure(L10n.tr("Enter a valid timestamp or choose a date and time (for example, 2026-10-12 09:00:00)."))
      }
      date = parsed
    }
    try require(Dates.supportedRange.contains(date), L10n.tr("Date is outside the supported range (years 0001–9999)."))
    return date
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let date = try date(from: input.text, options: options)
    let zone = TimeZone(identifier: options.timezone)!
    let rows = [
      ResultRow(L10n.tr("Date and Time"), Dates.display(date, timeZone: zone, milliseconds: true)),
      ResultRow(L10n.tr("Time Zone"), Dates.zoneLabel(zone, at: date)),
      ResultRow(L10n.tr("Unix Seconds"), Dates.timestamp(date, milliseconds: false)),
      ResultRow(L10n.tr("Unix Milliseconds"), Dates.timestamp(date, milliseconds: true)),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
