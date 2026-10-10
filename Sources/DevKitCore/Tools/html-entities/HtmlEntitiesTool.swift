import Foundation

public enum HtmlEntitiesTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var named: Bool = true
    public var all: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "html-entities", "HTML 实体", .encoding, "HTML5 命名和数字实体转换，不渲染输入 HTML。",
    sample: "<div title=\"hello\">你好 & world</div>", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"]),
      .init("named", "使用命名实体", \.named),
      .init("all", "转义全部字符", \.all),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("html-entities", input: input, options: options)
  }
}
