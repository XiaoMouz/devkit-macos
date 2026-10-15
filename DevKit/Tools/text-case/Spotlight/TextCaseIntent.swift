import AppIntents
import DevKitCore

struct TextCaseIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Convert to camelCase"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Convert to camelCase \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = TextCaseTool.Options()

    let value = try await SpotlightExecution.run(TextCaseTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Convert to camelCase")))
  }
}
