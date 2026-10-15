import AppIntents
import DevKitCore

struct MIMETypeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "MIME Type Lookup"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("MIME Type Lookup \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = MimeTypesTool.Options()

    let value = try await SpotlightExecution.run(MimeTypesTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("MIME Type Lookup")))
  }
}
