import AppIntents
import DevKitCore

struct UniqueLinesIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Remove Duplicate Lines"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Remove Duplicate Lines \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = TextLinesTool.Options()

    let value = try await SpotlightExecution.run(TextLinesTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Remove Duplicate Lines")))
  }
}
