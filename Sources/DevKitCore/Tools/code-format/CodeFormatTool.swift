import Foundation

public enum CodeFormatTool: ToolModule {
  public struct Options: ToolOptions {
    public var language: String = "javascript"
    public var indent: Int = 2
    public var dialect: String = "sql"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "code-format", "代码格式化", .assets, "Prettier 格式化 JS / TS / HTML / CSS；SQL 可选方言。",
    sample: "const hello={name:\"DevKit\",tools:[\"base64\",\"json\"]};", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "language", "语言", \.language, choices: ["javascript", "typescript", "html", "css", "sql"]),
      .init("indent", "缩进", \.indent, range: 1...8),
      .init(
        "dialect", "SQL 方言", \.dialect,
        choices: ["sql", "mysql", "postgresql", "sqlite", "transactsql"]),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.language == "sql" || field.id != "dialect" }
  }
  public static func example(for options: Options) -> ToolInput {
    let samples = ["javascript": "const user={name:\"Ada\",active:true};", "typescript": "type User={name:string;active:boolean};",
      "html": "<main><h1>Hello</h1><p>DevKit</p></main>", "css": ".card{display:flex;gap:16px;color:#3478f6;}", "sql": "select id,name from users where active=1 order by id;"]
    return ToolInput(text: samples[options.language] ?? metadata.sample)
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("code-format", input: input, options: options)
  }
}
