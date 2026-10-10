import AppIntents
import DevKitCore
import SwiftUI

struct ResultSnippetIntent: SnippetIntent {
  static let title: LocalizedStringResource = "DevKit 结果"
  static let isDiscoverable = false
  @Parameter(title: "结果") var text: String
  @Parameter(title: "工具") var tool: String
  @Parameter(title: "已复制", default: false) var copied: Bool
  init() {}
  init(text: String, tool: String, copied: Bool = false) {
    self.text = text
    self.tool = tool
    self.copied = copied
  }
  func perform() async throws -> some IntentResult & ShowsSnippetView {
    .result(view: ResultSnippetView(text: text, tool: tool, copied: copied))
  }
}
struct CopyResultIntent: AppIntent {
  static let title: LocalizedStringResource = "复制 DevKit 结果"
  static let isDiscoverable = false
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "结果") var text: String
  @Parameter(title: "工具") var tool: String
  init() {}
  init(text: String, tool: String) {
    self.text = text
    self.tool = tool
  }
  @MainActor func perform() async throws -> some IntentResult & ShowsSnippetIntent {
    guard Clipboard.copy(text) else { throw ToolFailure("复制失败，请重试。") }
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
            copied ? "已复制" : "点击复制", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
        }.font(.caption).foregroundStyle(.secondary)
        Text(text.isEmpty ? "（空文本）" : String(text.prefix(2000))).font(
          .system(.body, design: .monospaced)
        ).lineLimit(8).frame(maxWidth: .infinity, alignment: .leading)
        HStack {
          Text("\(text.utf8.count) 字节")
          if text.hasSuffix("\n") { Text("包含尾部换行") }
          if text.count > 2000 { Text("预览已截断 · 复制包含完整内容") }
        }.font(.caption2).foregroundStyle(.secondary)
      }.padding(16).contentShape(Rectangle())
    }.buttonStyle(.plain).accessibilityLabel("\(tool)，\(copied ? "已复制" : "复制完整结果")")
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
    try require(SpotlightPreferences.load().allows(request.id), "此工具的 Spotlight 操作已关闭，请在 DevKit 设置中启用。")
    try require(request.input.text.utf8.count <= 16 * 1024, "Spotlight 输入上限 16 KiB，请改用工具箱。")
    let output = try await WorkerRunner.run(request)
    try require(SpotlightPreferences.load().allows(request.id), "此工具的 Spotlight 操作已关闭。")
    // Binary previews are not text results and must not be silently copied as decoded bytes.
    if request.id == "base64", let file = output.artifacts.first,
      String(data: file.data, encoding: .utf8) == nil
    {
      throw ToolFailure("解码结果是二进制，请在工具箱导出文件。")
    }
    try require(output.text.utf8.count <= 64 * 1024, "结果超过 Spotlight 上限，请在工具箱处理。")
    return output.text
  }
}
