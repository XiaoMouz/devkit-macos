import AppIntents
import DevKitCore

struct StringEscapeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "JSON 字符串转义"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("JSON 字符串转义 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = StringEscapeTool.Options()

    let value = try await SpotlightExecution.run(
      StringEscapeTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "JSON 字符串转义"))
  }
}
