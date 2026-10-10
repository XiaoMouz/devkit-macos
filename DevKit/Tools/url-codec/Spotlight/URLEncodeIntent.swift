import AppIntents
import DevKitCore

struct URLEncodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "URL 编码"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("URL 编码 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = UrlCodecTool.Options()

    let value = try await SpotlightExecution.run(UrlCodecTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "URL 编码"))
  }
}
