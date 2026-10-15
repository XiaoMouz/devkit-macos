import AppIntents
import DevKitCore
import SwiftUI

struct ResultSnippetIntent: SnippetIntent {
  static let title: LocalizedStringResource = "DevKit Result"
  static let isDiscoverable = false
  @Parameter(title: "Result") var text: String
  @Parameter(title: "Tools") var tool: String
  @Parameter(title: "Copied", default: false) var copied: Bool
  init() {}
  init(text: String, tool: String, copied: Bool = false) {
    self.text = text
    self.tool = tool
    self.copied = copied
  }
  func perform() async throws -> some IntentResult & ShowsSnippetView {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    return .result(view: ResultSnippetView(text: text, tool: tool, copied: copied))
  }
}
struct CopyResultIntent: AppIntent {
  static let title: LocalizedStringResource = "Copy DevKit Result"
  static let isDiscoverable = false
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Result") var text: String
  @Parameter(title: "Tools") var tool: String
  init() {}
  init(text: String, tool: String) {
    self.text = text
    self.tool = tool
  }
  @MainActor func perform() async throws -> some IntentResult & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    guard Clipboard.copy(text) else { throw ToolFailure(L10n.tr("Could not copy. Please try again.")) }
    return .result(snippetIntent: ResultSnippetIntent(text: text, tool: tool, copied: true))
  }
}
struct ResultSnippetView: View {
  let text: String
  let tool: String
  let copied: Bool
  var body: some View {
    Button(intent: CopyResultIntent(text: text, tool: tool)) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Label(tool, systemImage: "curlybraces.square")
          Spacer()
          Label(
            copied ? L10n.tr("Copied") : L10n.tr("Click to Copy"), systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
        }.font(.caption).foregroundStyle(.secondary)
        Text(text.isEmpty ? L10n.tr("(Empty text)") : String(text.prefix(2000))).font(
          .system(.body, design: .monospaced)
        ).lineLimit(8).frame(maxWidth: .infinity, alignment: .leading)
        HStack {
          Text(L10n.tr("Bytes: \(text.utf8.count)"))
          if text.hasSuffix("\n") { Text(L10n.tr("Includes a trailing newline")) }
          if text.count > 2000 { Text(L10n.tr("Preview truncated · Copy includes the full result")) }
        }.font(.caption2).foregroundStyle(.secondary)
      }.padding(16).contentShape(Rectangle())
    }.buttonStyle(.plain).accessibilityLabel("\(tool)，\(copied ? L10n.tr("Copied") : L10n.tr("Copy Full Result"))")
  }
}

enum SpotlightExecution {
  static func run<T: ToolModule>(_ tool: T.Type, text: String, options: T.Options = .init())
    async throws -> String
  {
    let request = WorkerRequest(
      id: T.metadata.id, input: ToolInput(text: text), options: try JSONEncoder().encode(options))
    return try await run(request)
  }
  static func run(_ request: WorkerRequest) async throws -> String {
    try require(SpotlightPreferences.load().allows(request.id), L10n.tr("This tool’s Spotlight action is disabled. Enable it in DevKit settings."))
    try require(request.input.text.utf8.count <= 16 * 1024, L10n.tr("Spotlight input is limited to 16 KiB. Please use the main app instead."))
    let output = try await WorkerRunner.run(request)
    try require(SpotlightPreferences.load().allows(request.id), L10n.tr("This tool’s Spotlight action is disabled."))
    // Binary previews are not text results and must not be silently copied as decoded bytes.
    if request.id == "base64", let file = output.artifacts.first,
      String(data: file.data, encoding: .utf8) == nil
    {
      throw ToolFailure(L10n.tr("The decoded result is binary. Export it from the main app."))
    }
    try require(output.text.utf8.count <= 64 * 1024, L10n.tr("The result exceeds Spotlight’s limit. Use the main app instead."))
    return output.text
  }
}
