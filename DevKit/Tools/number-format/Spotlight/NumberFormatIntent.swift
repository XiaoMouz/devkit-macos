import AppIntents
import DevKitCore

struct NumberFormatIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "数字格式化"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("数字格式化 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = NumberFormatTool.Options()

    let value = try await SpotlightExecution.run(
      NumberFormatTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "数字格式化"))
  }
}
