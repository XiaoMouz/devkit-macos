import AppIntents
import DevKitCore

struct TextStatsIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Text Statistics"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Text Statistics \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = TextStatsTool.Options()

    let value = try await SpotlightExecution.run(TextStatsTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Text Statistics")))
  }
}
