import AppIntents
import DevKitCore

struct JWTDecodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "JWT 解析"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("JWT 解析 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = JwtTool.Options()

    let value = try await SpotlightExecution.run(JwtTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "JWT 解析"))
  }
}
