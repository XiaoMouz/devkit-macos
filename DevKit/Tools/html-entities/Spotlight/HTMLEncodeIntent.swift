import AppIntents
import DevKitCore

struct HTMLEncodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "HTML 实体编码"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("HTML 实体编码 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = HtmlEntitiesTool.Options()

    let value = try await SpotlightExecution.run(
      HtmlEntitiesTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "HTML 实体编码"))
  }
}
