import AppIntents
import DevKitCore

struct SHA256Intent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "SHA-256 摘要"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("SHA-256 摘要 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = HashTool.Options()

    let value = try await SpotlightExecution.run(HashTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "SHA-256 摘要"))
  }
}
