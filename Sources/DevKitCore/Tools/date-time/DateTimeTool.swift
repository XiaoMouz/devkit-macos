import Foundation

public enum DateTimeTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "zones"
    public var sourceZone: String = TimeZone.current.identifier
    public var zone: String = TimeZone.current.identifier
    public var days: Int = 1
    public var other: String = Dates.iso(Date())
    public init() {}
    enum CodingKeys: String, CodingKey { case operation, sourceZone, zone, days, other }
    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      operation = try values.decodeIfPresent(String.self, forKey: .operation) ?? "zones"
      sourceZone = try values.decodeIfPresent(String.self, forKey: .sourceZone) ?? TimeZone.current.identifier
      zone = try values.decodeIfPresent(String.self, forKey: .zone) ?? TimeZone.current.identifier
      days = try values.decodeIfPresent(Int.self, forKey: .days) ?? 1
      other = try values.decodeIfPresent(String.self, forKey: .other) ?? Dates.iso(Date())
    }
  }
  public static let metadata = ToolMetadata(
    "date-time", "Date and Time Zones", .numbers, "Choose dates and times, convert time zones, add or subtract dates, and calculate differences.",
    sample: "2026-10-11 12:00:00", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", L10n.tr("Operation"), \.operation, choices: ["zones", "add-days", "difference"]),
      .init("sourceZone", L10n.tr("Input Time Zone"), \.sourceZone),
      .init("zone", L10n.tr("Target Time Zone"), \.zone),
      .init("days", L10n.tr("Days to Add or Subtract"), \.days, range: -36500...36500),
      .init("other", L10n.tr("Comparison Date"), \.other),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in
      (field.id != "sourceZone" || options.operation == "zones")
        && (field.id != "days" || options.operation == "add-days")
        && (field.id != "other" || options.operation == "difference")
    }.map { field in
      field.id == "zone" && options.operation != "zones" ? .init("zone", L10n.tr("Time Zone"), \.zone) : field
    }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(["zones", "add-days", "difference"].contains(options.operation), L10n.tr("Choose a valid date operation."))
    guard let zone = TimeZone(identifier: options.zone),
      let source = TimeZone(identifier: options.operation == "zones" ? options.sourceZone : options.zone) else {
      throw ToolFailure(L10n.tr("Choose a valid time zone."))
    }
    guard let date = Dates.parse(input.text, timeZone: source), Dates.supportedRange.contains(date) else {
      throw ToolFailure(L10n.tr("Choose a valid date and time. Times skipped by daylight saving changes are unavailable."))
    }
    if options.operation == "difference" {
      guard let other = Dates.parse(options.other, timeZone: zone), Dates.supportedRange.contains(other) else {
        throw ToolFailure(L10n.tr("Choose a valid comparison date and time."))
      }
      let seconds = other.timeIntervalSince(date)
      let rows = [
        ResultRow(L10n.tr("Start Time"), Dates.display(date, timeZone: zone, milliseconds: true)),
        ResultRow(L10n.tr("Comparison Time"), Dates.display(other, timeZone: zone, milliseconds: true)),
        ResultRow(L10n.tr("Seconds"), String(format: "%.3f", seconds)),
        ResultRow(L10n.tr("Hours"), String(format: "%.6f", seconds / 3600)),
        ResultRow(L10n.tr("24-Hour Days"), String(format: "%.6f", seconds / 86400)),
      ]
      return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows,
        note: L10n.tr("\(Dates.zoneLabel(zone, at: date)) · Comparison time minus start time, using elapsed time including daylight saving changes."))
    }
    var target = date
    if options.operation == "add-days" {
      try require((-36500...36500).contains(options.days), L10n.tr("Number of days is out of range."))
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = zone
      guard let newDate = calendar.date(byAdding: .day, value: options.days, to: date), Dates.supportedRange.contains(newDate) else {
        throw ToolFailure(L10n.tr("The calculated date is outside the supported range."))
      }
      target = newDate
    }
    return ToolOutput(Dates.display(target, timeZone: zone, milliseconds: true), rows: [
      ResultRow(L10n.tr("Start Time · \(Dates.zoneLabel(source, at: date))"), Dates.display(date, timeZone: source, milliseconds: true)),
      ResultRow("\(options.operation == "zones" ? L10n.tr("Converted Time") : L10n.tr("Calculated Result")) · \(Dates.zoneLabel(zone, at: target))", Dates.display(target, timeZone: zone, milliseconds: true)),
    ], note: options.operation == "zones" ? L10n.tr("The same instant displayed in two time zones.") : L10n.tr("Add or subtract \(options.days) calendar days in the selected time zone. Local time is preserved across daylight saving changes; elapsed time may be 23 or 25 hours."))
  }
}
