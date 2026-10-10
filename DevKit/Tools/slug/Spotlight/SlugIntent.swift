import AppIntents
import DevKitCore

struct SlugIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "生成 Slug"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("生成 Slug \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = SlugTool.Options()

    let value = try await SpotlightExecution.run(SlugTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "生成 Slug"))
  }
}
