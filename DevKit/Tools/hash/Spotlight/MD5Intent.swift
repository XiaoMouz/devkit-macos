import AppIntents
import DevKitCore

struct MD5Intent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "MD5 Digest"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("MD5 Digest \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = HashTool.Options()
    options.algorithm = "MD5"
    let value = try await SpotlightExecution.run(HashTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("MD5 Digest")))
  }
}
