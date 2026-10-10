import AppIntents
import DevKitCore

enum Base64Operation: String, AppEnum {
  case encode, decode
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Base64 操作")
  static let caseDisplayRepresentations: [Base64Operation: DisplayRepresentation] = [
    .encode: "编码", .decode: "解码",
  ]
}
struct Base64CommandIntent: AppIntent {
  static let isDiscoverable = true
  static let title: LocalizedStringResource = "Base64 命令"
  static let description = IntentDescription(
    "为此动作设置快捷短语 base64，然后输入 base64 encode 123。选择动作后也可直接填写 encode 123。",
    searchKeywords: ["base64", "b64", "编码", "解码"], resultValueName: "Base64 结果")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "命令", description: "encode hello / decode aGVsbG8=") var command: String
  static var parameterSummary: some ParameterSummary { Summary("Base64 命令 \(\.$command)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let request = try SpotlightCommand.parse(command, toolID: "base64", preferences: .load())
    let value = try await SpotlightExecution.run(request)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "Base64"))
  }
}
struct Base64GuidedIntent: AppIntent {
  static let isDiscoverable = true
  static let title: LocalizedStringResource = "Base64 编码或解码"
  static let description = IntentDescription("选择编码或解码，填写文本后在 Spotlight 内显示结果。",
    searchKeywords: ["base64", "编码", "解码"], resultValueName: "Base64 结果")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "操作") var operation: Base64Operation
  @Parameter(title: "文本") var text: String
  static var parameterSummary: some ParameterSummary {
    Summary("Base64 \(\.$operation) \(\.$text)")
  }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = Base64Tool.Options()
    options.operation = operation.rawValue
    let value = try await SpotlightExecution.run(Base64Tool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "Base64"))
  }
}
struct Base64EncodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Base64 编码"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "文本") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Base64 编码 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let value = try await SpotlightExecution.run(Base64Tool.self, text: text)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "Base64 编码"))
  }
}
struct Base64DecodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Base64 解码"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "文本") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Base64 解码 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = Base64Tool.Options()
    options.operation = "decode"
    let value = try await SpotlightExecution.run(Base64Tool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "Base64 解码"))
  }
}
