import Foundation

public enum CodeMinifyTool: ToolModule {
  public struct Options: ToolOptions {
    public var language: String = "javascript"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "code-minify", "代码压缩", .assets, "使用解析器压缩 JS / CSS / HTML，不执行输入代码。",
    sample: "function hello(name) { return \"Hello, \" + name; }", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("language", "语言", \.language, choices: ["javascript", "css", "html"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("code-minify", input: input, options: options)
  }
}
