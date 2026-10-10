import Foundation

public enum TextReplaceTool: ToolModule {
  public struct Options: ToolOptions {
    public var search: String = "hello"
    public var replacement: String = "Hello"
    public var regex: Bool = false
    public var flags: String = "g"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "text-replace", "查找替换", .text, "普通文本或 ECMAScript 正则，保留原文并预览结果。",
    sample: "hello world\nhello DevKit", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("search", "查找", \.search),
      .init("replacement", "替换", \.replacement),
      .init("regex", "正则模式", \.regex),
      .init("flags", "正则标志", \.flags),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("text-replace", input: input, options: options)
  }
}
