import AppIntents
import DevKitCore

struct MIMETypeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "MIME 类型查询"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("MIME 类型查询 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = MimeTypesTool.Options()

    let value = try await SpotlightExecution.run(MimeTypesTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "MIME 类型查询"))
  }
}
