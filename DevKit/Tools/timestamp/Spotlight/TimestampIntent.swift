import AppIntents
import DevKitCore

struct TimestampIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Convert Timestamp"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Convert Timestamp \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = TimestampTool.Options()

    let value = try await SpotlightExecution.run(TimestampTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Convert Timestamp")))
  }
}
