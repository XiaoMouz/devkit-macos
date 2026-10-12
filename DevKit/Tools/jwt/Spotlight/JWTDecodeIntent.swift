import AppIntents
import DevKitCore

struct JWTDecodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Parse JWT"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Parse JWT \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = JwtTool.Options()

    let value = try await SpotlightExecution.run(JwtTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Parse JWT")))
  }
}
