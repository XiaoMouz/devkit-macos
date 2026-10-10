import AppIntents
import DevKitCore

struct UUIDIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "生成 UUID"
  static var supportedModes: IntentModes { .background }

  static var parameterSummary: some ParameterSummary { Summary("生成 UUID") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = UuidTool.Options()
    options.count = 1
    let value = try await SpotlightExecution.run(UuidTool.self, text: "", options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "生成 UUID"))
  }
}
