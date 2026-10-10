import AppIntents
import DevKitCore

struct NumberBaseIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "十进制转十六进制"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("十进制转十六进制 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = NumberBaseTool.Options()

    let value = try await SpotlightExecution.run(NumberBaseTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "十进制转十六进制"))
  }
}
