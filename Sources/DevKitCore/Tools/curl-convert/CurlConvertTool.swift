import Foundation

public enum CurlConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var format: String = "fetch"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "curl-convert", "cURL Converter", .web, "Parse common cURL options into fetch code without executing a shell.",
    sample:
      "curl 'https://example.com/api' -X POST -H 'Content-Type: application/json' -d '{\"hello\":\"world\"}'",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("format", L10n.tr("Output"), \.format, choices: ["fetch", "json"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("curl-convert", input: input, options: options)
  }
}
