import AppIntents
import DevKitCore

struct URLParserIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "URL 解析"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("URL 解析 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = UrlParserTool.Options()

    let value = try await SpotlightExecution.run(UrlParserTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "URL 解析"))
  }
}
