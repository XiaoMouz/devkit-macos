import Foundation

public enum MarkdownTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "markdown", "Markdown", .text, "Local preview and HTML export, with scripts and external resources removed.",
    sample: "# DevKit\n\n- 原生工具箱\n- **本地处理**\n\n```js\nconst hello = \"world\";\n```",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("markdown", input: input, options: options)
  }
}
