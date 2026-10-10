import Foundation

public enum CronTool: ToolModule {
  public struct Options: ToolOptions {
    public var timezone: String = TimeZone.current.identifier
    public var start: String = ""
    public var count: Int = 10
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "cron", "Cron", .numbers, "五字段 Cron，预览后续执行时间，不注册系统任务。", sample: "*/15 9-18 * * 1-5",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("timezone", "时区", \.timezone),
      .init("start", "起始时间", \.start),
      .init("count", "预览次数", \.count, range: 1...100),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let zone = TimeZone(identifier: options.timezone) else { throw ToolFailure("请选择有效时区。") }
    var resolved = options
    if !options.start.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      guard let start = Dates.parse(options.start, timeZone: zone), Dates.supportedRange.contains(start) else {
        throw ToolFailure("请选择有效的起始日期时间。")
      }
      resolved.start = Dates.iso(start)
    } else { resolved.start = Dates.iso(Date()) }
    var output: ToolOutput
    do { output = try ScriptEngine.execute("cron", input: input, options: resolved) }
    catch let failure as ToolFailure {
      if failure.code == "invalid-input", failure.message.range(of: "[一-龥]", options: .regularExpression) == nil {
        throw ToolFailure("Cron 表达式无效或无法生成后续时间。请检查五个字段：分 0–59、时 0–23、日 1–31、月 1–12、周 0–7，以及范围和步长。")
      }
      throw failure
    }
    output.rows = try output.rows.map { row in
      guard let date = Dates.parse(row.value) else { throw ToolFailure("无法读取 Cron 执行时间。") }
      return ResultRow("第 \(row.label) 次", Dates.display(date, timeZone: zone) + " · " + Dates.offsetLabel(zone, at: date))
    }
    output.text = output.rows.map(\.value).joined(separator: "\n")
    output.note = "按 \(zone.identifier) 计算并显示，自动处理夏令时；不创建系统任务。"
    return output
  }
}
