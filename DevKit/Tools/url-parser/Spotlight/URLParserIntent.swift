import AppIntents
import DevKitCore

struct URLParserIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "URL Parser"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Parse URL \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = UrlParserTool.Options()

    let value = try await SpotlightExecution.run(UrlParserTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("URL Parser")))
  }
}
