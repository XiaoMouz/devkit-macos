import AppIntents
import DevKitCore

struct TextStatsIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "文本统计"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("文本统计 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = TextStatsTool.Options()

    let value = try await SpotlightExecution.run(TextStatsTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "文本统计"))
  }
}
