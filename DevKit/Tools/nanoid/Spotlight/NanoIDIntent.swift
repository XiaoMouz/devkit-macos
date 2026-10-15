import AppIntents
import DevKitCore

struct NanoIDIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Generate Nano ID"
  static var supportedModes: IntentModes { .background }

  static var parameterSummary: some ParameterSummary { Summary("Generate Nano ID") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    var options = NanoidTool.Options()
    options.count = 1
    let value = try await SpotlightExecution.run(NanoidTool.self, text: "", options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Generate Nano ID")))
  }
}
