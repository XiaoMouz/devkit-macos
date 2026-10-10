import Foundation

public enum DateTimeTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "zones"
    public var zone: String = "America/New_York"
    public var days: Int = 1
    public var other: String = "2025-02-01T12:00:00+08:00"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "date-time", "日期与时区", .numbers, "带时区的 ISO 8601、日期加减、时间差与时区对照。",
    sample: "2025-01-01T12:00:00+08:00", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["zones", "add-days", "difference"]),
      .init("zone", "目标时区", \.zone),
      .init("days", "增减天数", \.days, range: -36500...36500),
      .init("other", "对比日期", \.other),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let date = Dates.parse(input.text), let zone = TimeZone(identifier: options.zone) else {
      throw ToolFailure("请输入带时区的 ISO 8601 日期与有效时区。")
    }
    if options.operation == "difference" {
      guard let other = Dates.parse(options.other) else { throw ToolFailure("对比日期需要带时区。") }
      let seconds = other.timeIntervalSince(date)
      return ToolOutput(
        "\(seconds) 秒",
        rows: [
          ResultRow("秒", String(seconds)), ResultRow("小时", String(seconds / 3600)),
          ResultRow("24 小时日", String(seconds / 86400)),
        ])
    }
    var target = date
    if options.operation == "add-days" {
      try require((-36500...36500).contains(options.days), "天数超出范围。")
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = zone
      guard let newDate = calendar.date(byAdding: .day, value: options.days, to: date) else {
        throw ToolFailure("无法计算日期。")
      }
      target = newDate
    }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = zone
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss XXX zzz"
    return ToolOutput(
      formatter.string(from: target),
      rows: [
        ResultRow(options.zone, formatter.string(from: target)),
        ResultRow("UTC", Dates.iso(target)),
      ], note: "输入必须带明确偏移；日历加天按目标时区处理夏令时。")
  }
}
