import AppIntents
import DevKitCore

struct NumberFormatIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Number Formatting"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Format Number \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = NumberFormatTool.Options()

    let value = try await SpotlightExecution.run(
      NumberFormatTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Number Formatting")))
  }
}
