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
    "date-time", "日期与时区", .numbers, "日期时间选择、时区转换、日期加减与时间差。",
    sample: "2026-10-11 12:00:00", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["zones", "add-days", "difference"]),
      .init("sourceZone", "输入时区", \.sourceZone),
      .init("zone", "目标时区", \.zone),
      .init("days", "增减天数", \.days, range: -36500...36500),
      .init("other", "对比日期", \.other),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in
      (field.id != "sourceZone" || options.operation == "zones")
        && (field.id != "days" || options.operation == "add-days")
        && (field.id != "other" || options.operation == "difference")
    }.map { field in
      field.id == "zone" && options.operation != "zones" ? .init("zone", "时区", \.zone) : field
    }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(["zones", "add-days", "difference"].contains(options.operation), "请选择有效的日期操作。")
    guard let zone = TimeZone(identifier: options.zone),
      let source = TimeZone(identifier: options.operation == "zones" ? options.sourceZone : options.zone) else {
      throw ToolFailure("请选择有效时区。")
    }
    guard let date = Dates.parse(input.text, timeZone: source), Dates.supportedRange.contains(date) else {
      throw ToolFailure("请选择有效日期时间；该时区夏令时跳过的时间不可用。")
    }
    if options.operation == "difference" {
      guard let other = Dates.parse(options.other, timeZone: zone), Dates.supportedRange.contains(other) else {
        throw ToolFailure("请选择有效的对比日期时间。")
      }
      let seconds = other.timeIntervalSince(date)
      let rows = [
        ResultRow("起始时间", Dates.display(date, timeZone: zone, milliseconds: true)),
        ResultRow("对比时间", Dates.display(other, timeZone: zone, milliseconds: true)),
        ResultRow("秒", String(format: "%.3f", seconds)),
        ResultRow("小时", String(format: "%.6f", seconds / 3600)),
        ResultRow("24 小时日", String(format: "%.6f", seconds / 86400)),
      ]
      return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows,
        note: "\(Dates.zoneLabel(zone, at: date)) · 对比时间减去起始时间；按实际经过时长计算，包含夏令时变化。")
    }
    var target = date
    if options.operation == "add-days" {
      try require((-36500...36500).contains(options.days), "天数超出范围。")
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = zone
      guard let newDate = calendar.date(byAdding: .day, value: options.days, to: date), Dates.supportedRange.contains(newDate) else {
        throw ToolFailure("计算结果超出支持的日期范围。")
      }
      target = newDate
    }
    return ToolOutput(Dates.display(target, timeZone: zone, milliseconds: true), rows: [
      ResultRow("起始时间 · \(Dates.zoneLabel(source, at: date))", Dates.display(date, timeZone: source, milliseconds: true)),
      ResultRow("\(options.operation == "zones" ? "转换时间" : "计算结果") · \(Dates.zoneLabel(zone, at: target))", Dates.display(target, timeZone: zone, milliseconds: true)),
    ], note: options.operation == "zones" ? "同一时刻在两个时区中的日期时间。" : "按所选时区增减 \(options.days) 个日历日；跨夏令时时保持本地时间，可能相差 23 或 25 小时。")
  }
}
