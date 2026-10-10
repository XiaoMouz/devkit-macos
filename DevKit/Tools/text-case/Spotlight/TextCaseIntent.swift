import AppIntents
import DevKitCore

struct TextCaseIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "转为 camelCase"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("转为 camelCase \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = TextCaseTool.Options()

    let value = try await SpotlightExecution.run(TextCaseTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "转为 camelCase"))
  }
}
