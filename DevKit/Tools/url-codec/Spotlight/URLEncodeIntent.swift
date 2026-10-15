import AppIntents
import DevKitCore

struct URLEncodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "URL Encode"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("URL Encode \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = UrlCodecTool.Options()

    let value = try await SpotlightExecution.run(UrlCodecTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("URL Encode")))
  }
}
