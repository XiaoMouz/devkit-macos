import AppIntents
import DevKitCore

struct ULIDIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "生成 ULID"
  static var supportedModes: IntentModes { .background }

  static var parameterSummary: some ParameterSummary { Summary("生成 ULID") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = UlidTool.Options()
    options.count = 1
    let value = try await SpotlightExecution.run(UlidTool.self, text: "", options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "生成 ULID"))
  }
}
