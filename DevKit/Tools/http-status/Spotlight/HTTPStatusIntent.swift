import AppIntents
import DevKitCore

struct HTTPStatusIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "HTTP Status Lookup"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("HTTP Status Lookup \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = HttpStatusTool.Options()

    let value = try await SpotlightExecution.run(HttpStatusTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("HTTP Status Lookup")))
  }
}
