import AppIntents
import DevKitCore

struct TimestampIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "时间戳转换"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "输入") var text: String
  static var parameterSummary: some ParameterSummary { Summary("时间戳转换 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let options = TimestampTool.Options()

    let value = try await SpotlightExecution.run(TimestampTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "时间戳转换"))
  }
}
