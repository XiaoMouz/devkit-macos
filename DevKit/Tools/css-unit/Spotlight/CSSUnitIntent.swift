import AppIntents
import DevKitCore

struct CSSUnitIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "px to rem"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("px to rem \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = CssUnitTool.Options()

    let value = try await SpotlightExecution.run(CssUnitTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("px to rem")))
  }
}
