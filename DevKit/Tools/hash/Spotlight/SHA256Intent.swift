import AppIntents
import DevKitCore

struct SHA256Intent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "SHA-256 Digest"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("SHA-256 Digest \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = HashTool.Options()

    let value = try await SpotlightExecution.run(HashTool.self, text: text, options: options)
    return .result(
      value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("SHA-256 Digest")))
  }
}
