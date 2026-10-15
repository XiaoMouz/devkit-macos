import AppIntents
import DevKitCore

struct RandomStringIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Generate Random String"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Length", default: 24) var length: Int
  static var parameterSummary: some ParameterSummary { Summary("Generate a \(\.$length)-character random string") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    var options = RandomStringTool.Options()
    options.count = 1
    options.length = length
    let value = try await SpotlightExecution.run(RandomStringTool.self, text: "", options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Generate Random String")))
  }
}
