import AppIntents
import DevKitCore

struct NumberBaseIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Decimal to Hexadecimal"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Decimal to Hexadecimal \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = NumberBaseTool.Options()

    let value = try await SpotlightExecution.run(NumberBaseTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Decimal to Hexadecimal")))
  }
}
