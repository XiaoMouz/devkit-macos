import Foundation

public enum CronTool: ToolModule {
  public struct Options: ToolOptions {
    public var timezone: String = "Asia/Shanghai"
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
      .init("start", "起始 ISO 日期（空为现在）", \.start),
      .init("count", "预览次数", \.count, range: 1...100),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("cron", input: input, options: options)
  }
}
