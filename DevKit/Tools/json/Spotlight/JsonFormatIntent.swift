import AppIntents
import DevKitCore

struct JsonFormatIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Format JSON"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Format JSON \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = JsonTool.Options()

    let value = try await SpotlightExecution.run(JsonTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Format JSON")))
  }
}
