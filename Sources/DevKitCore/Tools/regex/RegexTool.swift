import Foundation

public enum RegexTool: ToolModule {
  public struct Options: ToolOptions {
    public var pattern: String = "([\\w.-]+)@([\\w.-]+)"
    public var flags: String = "g"
    public var operation: String = "match"
    public var replacement: String = "$1@new.test"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "regex", "正则测试", .text, "ECMAScript 正则、捕获组和替换预览；独立进程可取消。",
    sample: "user@example.com\nhello@devkit.app", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("pattern", "表达式", \.pattern),
      .init("flags", "标志", \.flags),
      .init("operation", "操作", \.operation, choices: ["match", "replace"]),
      .init("replacement", "替换文本", \.replacement),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.operation == "replace" || field.id != "replacement" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("regex", input: input, options: options)
  }
}
