import AppIntents
import DevKitCore

enum Base64Operation: String, AppEnum {
  case encode, decode
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Base64 Operation")
  static let caseDisplayRepresentations: [Base64Operation: DisplayRepresentation] = [
    .encode: "Encode", .decode: "Decode",
  ]
}
struct Base64CommandIntent: AppIntent {
  static let isDiscoverable = true
  static let title: LocalizedStringResource = "Base64 Command"
  static let description = IntentDescription(
    "Enter encode hello or decode aGVsbG8=. You can also include the tool name: base64 encode hello.",
    searchKeywords: ["base64", "b64", "Encode", "Decode"], resultValueName: "Base64 Result")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Command", description: "encode hello / decode aGVsbG8=") var command: String
  static var parameterSummary: some ParameterSummary { Summary("Base64 Command \(\.$command)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let request = try SpotlightCommand.parse(command, toolID: "base64", preferences: .load())
    let value = try await SpotlightExecution.run(request)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: "Base64"))
  }
}
struct Base64GuidedIntent: AppIntent {
  static let isDiscoverable = true
  static let title: LocalizedStringResource = "Base64 Encode or Decode"
  static let description = IntentDescription("Choose encode or decode and enter text to see the result in Spotlight.",
    searchKeywords: ["base64", "Encode", "Decode"], resultValueName: "Base64 Result")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Operation") var operation: Base64Operation
  @Parameter(title: "Text") var text: String
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
  static let title: LocalizedStringResource = "Base64 Encode"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Text") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Base64 Encode \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let value = try await SpotlightExecution.run(Base64Tool.self, text: text)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Base64 Encode")))
  }
}
struct Base64DecodeIntent: AppIntent {
  static let isDiscoverable = false
  static let title: LocalizedStringResource = "Base64 Decode"
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Text") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Base64 Decode \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    var options = Base64Tool.Options()
    options.operation = "decode"
    let value = try await SpotlightExecution.run(Base64Tool.self, text: text, options: options)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: L10n.tr("Base64 Decode")))
  }
}
