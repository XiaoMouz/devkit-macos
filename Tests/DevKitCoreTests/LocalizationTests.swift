import Foundation
import Observation
import Synchronization
import Testing
@testable import DevKitCore

@Suite("Localization and translation resources")
struct LocalizationTests {

  @Test @MainActor func liveSelectionInvalidatesTranslationsAndCachedMetadata() {
    let selection = LanguageSelection("zh-Hans")
    L10n.$selectionOverride.withValue(selection) {
      let tool = JsonTool.metadata
      let action = SpotlightCatalog.actions.first { $0.id == "json:format" }!
      #expect(action.name.contains("JSON 工作台"))
      let changes = Mutex(0)
      withObservationTracking {
        #expect(L10n.tr("Copy") == "复制")
        #expect(tool.name == "JSON 工作台")
      } onChange: {
        changes.withLock { $0 += 1 }
      }
      L10n.selectLanguage("en")
      #expect(changes.withLock { $0 } == 1)
      #expect(L10n.tr("Copy") == "Copy")
      #expect(tool.name == "JSON Workspace")
      #expect(action.name == "JSON Workspace · Format")
      #expect(L10n.locale.identifier == "en")
      // This must ignore a cached per-app preference when returning to System.
      L10n.selectLanguage("system", systemLanguages: ["zh-Hans", "en"])
      #expect(L10n.language == "zh-Hans")
      #expect(action.name.contains("JSON 工作台"))
    }
  }

  @Test func matchesLanguagePreferencesAndFallsBack() {
    #expect(L10n.resolve(preferred: ["en-GB"]) == "en")
    #expect(L10n.resolve(preferred: ["zh-CN"]) == "zh-Hans")
    #expect(L10n.resolve(preferred: ["zh-Hant-TW"]) == "en")
    #expect(L10n.resolve(preferred: ["fr-FR", "zh-Hans"]) == "zh-Hans")
    #expect(L10n.resolve(preferred: ["unsupported"]) == "en")
    #expect(L10n.resolve(preferred: ["fr-CA"], available: ["en", "zh-Hans", "fr"]) == "fr")
    #expect(L10n.text("Tools", language: "fr") == "Tools")
    #expect(L10n.text("unknown.key", language: "en") == "unknown.key")
  }

  @Test func catalogsAreCompleteAndArgumentsAreNotReinterpreted() throws {
    let source = try #require(L10n.languages.first { $0.id == "zh-Hans" })
    let english = try #require(L10n.languages.first { $0.id == "en" })
    #expect(source.strings.count > 1200)
    #expect(Set(source.strings.keys) == Set(english.strings.keys))
    for (key, value) in english.strings {
      #expect(!value.isEmpty, "Missing English translation: \(key)")
      #expect(value.range(of: "[一-鿿]", options: .regularExpression) == nil, "Untranslated: \(key)")
    }
    #expect(L10n.text("Showing the first {0} of {1} issues.", arguments: ["5", "20"], language: "zh-Hans") == "共 20 个问题，显示前 5 个。")
    let input = "原文 {1} %@ 100% 👩‍💻"
    L10n.$overrideLanguage.withValue("en") {
      #expect(L10n.tr("Could not import “\(input)”: \(input) The current input has not been replaced. Import again or confirm that you want to keep using it.")
        == "Could not import “\(input)”: \(input) The current input has not been replaced. Import again or confirm that you want to keep using it.")
    }
  }

  @Test func toolDiscoveryAndPresentationUseEnglishWithoutChangingContracts() {
    L10n.$overrideLanguage.withValue("en") {
      for tool in ToolRegistry.all { checkPresentation(tool) }
      #expect(JsonTool.metadata.name == "JSON Workspace")
      #expect(JsonTool.metadata.searchText.contains("JSON 工作台"))
      #expect(JsonTool.metadata.searchText.contains("JSON Workspace"))
      #expect(ToolCategory.structured.rawValue == "结构化数据")
      #expect(ToolCategory.structured.title == "Structured Data")
      #expect(Base64Tool.fields.first?.read(.init()) == "encode")
    }
  }
  private func checkPresentation<T: ToolModule>(_ tool: T.Type) {
    let options = T.Options()
    let values = Dictionary(uniqueKeysWithValues: T.fields.map { ($0.id, $0.read(options)) })
    let presentation = ToolPresentation(id: T.metadata.id, style: T.inputStyle(for: options), values: values)
    for value in [T.metadata.name, T.metadata.summary, T.metadata.category.title,
                  presentation.action, presentation.inputTitle, presentation.outputTitle] + T.fields.map(\.label) {
      #expect(value.range(of: "[一-鿿]", options: .regularExpression) == nil, "\(T.metadata.id): \(value)")
    }
  }

  @Test func englishExecutionPreservesUserDataAndStructuredErrorLocations() async throws {
    try await L10n.$overrideLanguage.withValue("en") {
      let original = "你好，世界 {0} %@\n"
      let encoded = try await Base64Tool.execute(ToolInput(text: original), options: .init())
      var decode = Base64Tool.Options(); decode.operation = "decode"
      let restored = try await Base64Tool.execute(ToolInput(text: encoded.text), options: decode)
      #expect(restored.text == original)
      var json = JsonTool.Options(); json.operation = "validate"
      let invalid = try await JsonTool.execute(ToolInput(text: "{\n  \"a\": 1,\n  invalid\n}"), options: json)
      #expect(invalid.report?.title == "JSON Validation Failed")
      #expect(invalid.rows.first?.label.hasPrefix("Line 3") == true)
      #expect(invalid.html?.contains("line numbered error") == true)
      json.operation = "schema"
      let schema = try await JsonTool.execute(ToolInput(text: "{\"age\":\"你好\"}", secondary: "{\"type\":\"object\",\"properties\":{\"age\":{\"type\":\"integer\"}}}"), options: json)
      #expect(schema.rows.contains { $0.value.contains("Expected Integer") })
      #expect(schema.html?.contains("你好") == true)
      #expect(schema.report?.title == "Validation Issues Found: 1")
      do {
        _ = try await Base64Tool.execute(ToolInput(text: "%%%"), options: decode)
        Issue.record("Invalid Base64 should fail")
      } catch let error as ToolFailure {
        #expect(error.code == "invalid-input")
        #expect(error.message.hasPrefix("Base64 contains invalid characters"))
      }
    }
  }
}
