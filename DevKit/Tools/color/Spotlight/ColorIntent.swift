import AppIntents
import DevKitCore

struct ColorIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "颜色转换"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("颜色转换 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = ColorTool.Options()

    let value = try await SpotlightExecution.run(ColorTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "颜色转换"))
  }
}
