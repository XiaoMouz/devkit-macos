import AppIntents
import DevKitCore

struct ColorIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Color Converter"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Input") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Convert Color \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let options = ColorTool.Options()

    let value = try await SpotlightExecution.run(ColorTool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Color Converter")))
  }
}
