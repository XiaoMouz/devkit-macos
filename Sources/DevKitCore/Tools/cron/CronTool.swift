import Foundation

public enum CronTool: ToolModule {
  public struct Options: ToolOptions {
    public var timezone: String = TimeZone.current.identifier
    public var start: String = ""
    public var count: Int = 10
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "cron", "Cron", .numbers, "Preview upcoming runs for five-field Cron expressions without registering system tasks.", sample: "*/15 9-18 * * 1-5",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("timezone", L10n.tr("Time Zone"), \.timezone),
      .init("start", L10n.tr("Start Time"), \.start),
      .init("count", L10n.tr("Preview Count"), \.count, range: 1...100),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...100).contains(options.count), L10n.tr("Count must be 1–100"))
    try require(input.text.split(whereSeparator: \.isWhitespace).count == 5,
      L10n.tr("This tool only supports five-field Cron: minute hour day month weekday"))
    guard let zone = TimeZone(identifier: options.timezone) else { throw ToolFailure(L10n.tr("Choose a valid time zone.")) }
    var resolved = options
    if !options.start.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      guard let start = Dates.parse(options.start, timeZone: zone), Dates.supportedRange.contains(start) else {
        throw ToolFailure(L10n.tr("Choose a valid start date and time."))
      }
      resolved.start = Dates.iso(start)
    } else { resolved.start = Dates.iso(Date()) }
    var output: ToolOutput
    do { output = try ScriptEngine.execute("cron", input: input, options: resolved) }
    catch let failure as ToolFailure {
      if failure.code == "invalid-input" {
        throw ToolFailure(L10n.tr("Invalid Cron expression or no upcoming runs. Check all five fields: minute 0–59, hour 0–23, day 1–31, month 1–12, weekday 0–7, as well as ranges and steps."))
      }
      throw failure
    }
    output.rows = try output.rows.map { row in
      guard let date = Dates.parse(row.value) else { throw ToolFailure(L10n.tr("Could not read Cron run times.")) }
      return ResultRow(L10n.tr("Run \(row.label)"), Dates.display(date, timeZone: zone) + " · " + Dates.offsetLabel(zone, at: date))
    }
    output.text = output.rows.map(\.value).joined(separator: "\n")
    output.note = L10n.tr("Calculated and displayed in \(zone.identifier). cron-parser shifts times skipped by daylight saving changes (for example, 02:30 → 03:30); repeated times use the first occurrence. No system task is created.")
    return output
  }
}
