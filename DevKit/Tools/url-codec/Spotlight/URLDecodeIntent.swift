import AppIntents
import DevKitCore

struct URLDecodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "URL Decode"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("URL Decode \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = UrlCodecTool.Options()
    options.operation = "decode"
    let value = try await SpotlightExecution.run(UrlCodecTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("URL Decode")))
  }
}
