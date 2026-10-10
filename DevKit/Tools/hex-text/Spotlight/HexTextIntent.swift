import AppIntents
import DevKitCore

struct HexTextIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "文本转 Hex"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("文本转 Hex \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = HexTextTool.Options()

    let value = try await SpotlightExecution.run(HexTextTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "文本转 Hex"))
  }
}
