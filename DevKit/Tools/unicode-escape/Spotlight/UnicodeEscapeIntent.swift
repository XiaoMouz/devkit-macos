import AppIntents
import DevKitCore

struct UnicodeEscapeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Unicode 转义"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Unicode 转义 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = UnicodeEscapeTool.Options()

    let value = try await SpotlightExecution.run(
      UnicodeEscapeTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "Unicode 转义"))
  }
}
