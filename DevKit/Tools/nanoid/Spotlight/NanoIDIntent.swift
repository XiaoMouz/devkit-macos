import AppIntents
import DevKitCore

struct NanoIDIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "生成 Nano ID"
  static var supportedModes: IntentModes { .background }

  static var parameterSummary: some ParameterSummary { Summary("生成 Nano ID") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = NanoidTool.Options()
    options.count = 1
    let value = try await SpotlightExecution.run(NanoidTool.self, text: "", options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "生成 Nano ID"))
  }
}
