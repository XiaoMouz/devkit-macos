import AppIntents
import DevKitCore

struct HTTPStatusIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "HTTP 状态码查询"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("HTTP 状态码查询 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = HttpStatusTool.Options()

    let value = try await SpotlightExecution.run(HttpStatusTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "HTTP 状态码查询"))
  }
}
