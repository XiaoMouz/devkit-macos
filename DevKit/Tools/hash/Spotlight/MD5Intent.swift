import AppIntents
import DevKitCore

struct MD5Intent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "MD5 摘要"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("MD5 摘要 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = HashTool.Options()
    options.algorithm = "MD5"
    let value = try await SpotlightExecution.run(HashTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "MD5 摘要"))
  }
}
