import AppIntents
import DevKitCore

struct JsonFormatIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "JSON 格式化"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("JSON 格式化 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = JsonTool.Options()

    let value = try await SpotlightExecution.run(JsonTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "JSON 格式化"))
  }
}
