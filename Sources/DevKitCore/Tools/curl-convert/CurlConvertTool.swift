import Foundation

public enum CurlConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var format: String = "fetch"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "curl-convert", "cURL 转换", .web, "静态解析常用 cURL 参数，输出 fetch；不执行 Shell。",
    sample:
      "curl 'https://example.com/api' -X POST -H 'Content-Type: application/json' -d '{\"hello\":\"world\"}'",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("format", "输出", \.format, choices: ["fetch", "json"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("curl-convert", input: input, options: options)
  }
}
