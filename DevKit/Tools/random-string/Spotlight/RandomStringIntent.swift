import AppIntents
import DevKitCore

struct RandomStringIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "生成随机字符串"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "长度", default: 24) var length: Int
  static var parameterSummary: some ParameterSummary { Summary("生成随机字符串 \(\.$length) 位") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = RandomStringTool.Options()
    options.count = 1
    options.length = length
    let value = try await SpotlightExecution.run(RandomStringTool.self, text: "", options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "生成随机字符串"))
  }
}
