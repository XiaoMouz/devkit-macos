import Foundation

public enum CodeMinifyTool: ToolModule {
  public struct Options: ToolOptions {
    public var language: String = "javascript"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "code-minify", "Code Minifier", .assets, "Minify JS, CSS, and HTML with parsers, without executing the input code.",
    sample: "function hello(name) { return \"Hello, \" + name; }", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("language", L10n.tr("Language"), \.language, choices: ["javascript", "css", "html"])
    ]
  }
  public static func example(for options: Options) -> ToolInput {
    let samples = ["javascript": "const user={name:\"Ada\",active:true};", "typescript": "type User={name:string;active:boolean};",
      "html": "<main><h1>Hello</h1><p>DevKit</p></main>", "css": ".card{display:flex;gap:16px;color:#3478f6;}", "sql": "select id,name from users where active=1 order by id;"]
    return ToolInput(text: samples[options.language] ?? metadata.sample)
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("code-minify", input: input, options: options)
  }
}
