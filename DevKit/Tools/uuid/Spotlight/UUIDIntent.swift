import AppIntents
import DevKitCore

struct UUIDIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Generate UUID"
  static var supportedModes: IntentModes { .background }

  static var parameterSummary: some ParameterSummary { Summary("Generate UUID") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    var options = UuidTool.Options()
    options.count = 1
    let value = try await SpotlightExecution.run(UuidTool.self, text: "", options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Generate UUID")))
  }
}
