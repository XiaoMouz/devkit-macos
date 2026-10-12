import Foundation
import Testing
@testable import DevKitCore

@Suite("User-controlled Spotlight commands") struct SpotlightTests {
  private func enabled(_ ids: String...) -> SpotlightPreferences {
    var preferences = SpotlightPreferences()
    preferences.enabled = true
    for id in ids { preferences.setEnabled(true, for: id) }
    return preferences
  }
  @Test func dedicatedActionAcceptsQuickKeyArgumentsAndFullCommands() async throws {
    var preferences = enabled("base64")
    preferences.tools["base64"] = .init(enabled: true, aliases: ["b64", "b"])
    for command in ["encode 123", "base64 encode 123", "B64 ENC 123", "b encode 123"] {
      let request = try SpotlightCommand.parse(command, toolID: "base64", preferences: preferences)
      let result = try await Base64Tool.executeEncoded(request.input, options: request.options)
      #expect(result.text == "MTIz")
    }
    let request = try SpotlightCommand.parse("decode MTIzMTIzMTIzYXNkZmFkc2ZzZGFmCg", toolID: "base64", preferences: preferences)
    let result = try await Base64Tool.executeEncoded(request.input, options: request.options)
    #expect(result.text == "123123123asdfadsfsdaf\n")
    #expect(try SpotlightCommand.parse("enc --  你好\n", toolID: "base64", preferences: preferences).input.text == " 你好\n")
    #expect(try SpotlightCommand.parse("encode --", toolID: "base64", preferences: preferences).input.text.isEmpty)
  }
  @Test func dedicatedActionHonorsSwitchesAndCannotRunAnotherTool() throws {
    var preferences = enabled("base64", "json")
    for command in ["json format {}", "encode", "encode ", "encode " + String(repeating: "a", count: 16384)] {
      #expect(throws: ToolFailure.self) { try SpotlightCommand.parse(command, toolID: "base64", preferences: preferences) }
    }
    preferences.setEnabled(false, for: "base64")
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("encode 123", toolID: "base64", preferences: preferences) }
    preferences.setEnabled(true, for: "base64")
    preferences.enabled = false
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("encode 123", toolID: "base64", preferences: preferences) }
  }
  @Test func freshInstallAndDisabledToolsNeverExecute() throws {
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("b64 encode hello", preferences: .init()) }
    var preferences = enabled("base64")
    _ = try SpotlightCommand.parse("b64 encode hello", preferences: preferences)
    preferences.setEnabled(false, for: "base64")
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("b64 encode hello", preferences: preferences) }
    preferences.setEnabled(true, for: "base64")
    preferences.enabled = false
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("b64 encode hello", preferences: preferences) }
  }
  @Test func aliasesApplyWithoutChangingPayload() async throws {
    var preferences = enabled("base64")
    preferences.tools["base64"] = .init(enabled: true, aliases: ["b", "b64"])
    let request = try SpotlightCommand.parse("B EnC --  你好\n$HOME \\n", preferences: preferences)
    #expect(request.input.text == " 你好\n$HOME \\n")
    let output = try await Base64Tool.executeEncoded(request.input, options: request.options)
    #expect(String(data: Data(base64Encoded: output.text)!, encoding: .utf8) == request.input.text)
    #expect(try SpotlightCommand.parse("BASE64 encode hello", preferences: preferences).input.text == "hello")
  }
  @Test func emptyInputAndDecodeWithOmittedPadding() async throws {
    let preferences = enabled("base64")
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("b64 encode", preferences: preferences) }
    #expect(try SpotlightCommand.parse("b64 encode --", preferences: preferences).input.text.isEmpty)
    let request = try SpotlightCommand.parse("b64 dec MTIzMTIzMTIzYXNkZmFkc2ZzZGFmCg", preferences: preferences)
    let output = try await Base64Tool.executeEncoded(request.input, options: request.options)
    #expect(output.text == "123123123asdfadsfsdaf\n")
  }
  @Test func invalidOperationAndLargePayloadFail() {
    let preferences = enabled("base64")
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("b64 encod hello", preferences: preferences) }
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("b64 encode " + String(repeating: "x", count: 16384), preferences: preferences) }
  }
  @Test func generatorsSupportValidatedCounts() async throws {
    let preferences = enabled("uuid")
    let request = try SpotlightCommand.parse("uuid 3", preferences: preferences)
    let output = try await UuidTool.executeEncoded(request.input, options: request.options)
    #expect(output.rows.count == 3)
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("uuid -1", preferences: preferences) }
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("uuid nope", preferences: preferences) }
  }
  @Test func catalogueIsUniqueAndOnlyContainsLocalTextTools() {
    #expect(Set(SpotlightCatalog.tools.map(\.id)).count == SpotlightCatalog.tools.count)
    #expect(Set(SpotlightCatalog.actions.map(\.id)).count == SpotlightCatalog.actions.count)
    for tool in SpotlightCatalog.tools {
      #expect(ToolRegistry.find(tool.id) != nil)
      #expect(ToolRegistry.find(tool.id)?.metadata.network == false)
      #expect(!tool.actions.isEmpty)
    }
  }
  @Test func preferencesRoundTripAndCorruptionFailsClosed() throws {
    let name = "app.devkit.tests." + UUID().uuidString
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    var preferences = enabled("base64")
    preferences.tools["base64"] = .init(enabled: true, aliases: ["b64", "b"])
    try preferences.save(to: defaults)
    #expect(SpotlightPreferences.load(from: defaults) == preferences)
    defaults.set(Data("broken".utf8), forKey: SpotlightPreferences.storageKey)
    #expect(!SpotlightPreferences.load(from: defaults).enabled)
  }
  @Test func chineseCommandsExecuteAndPreservePayload() async throws {
    let preferences = enabled("base64", "url-codec", "json", "text-lines")
    try await L10n.$overrideLanguage.withValue("zh-Hans") {
      for command in ["base64 编码 hello", "编码 hello", "BASE64 ENC hello"] {
        let request = try SpotlightCommand.parse(command, toolID: "base64", preferences: preferences)
        let result = try await Base64Tool.executeEncoded(request.input, options: request.options)
        #expect(result.text == "aGVsbG8=")
      }
      let request = try SpotlightCommand.parse("base64 解码 aGVsbG8=", preferences: preferences)
      #expect(try await Base64Tool.executeEncoded(request.input, options: request.options).text == "hello")
      let original = " 你好 👩‍💻 encode 解码 {0} $HOME \\n\r\n"
      let preserved = try SpotlightCommand.parse("base64 编码 -- " + original, preferences: preferences)
      #expect(preserved.input.text == original)
      #expect(try SpotlightCommand.parse("base64 编码 --", preferences: preferences).input.text.isEmpty)
      let lines = try SpotlightCommand.parse("text-lines 去重 a\nb\na", preferences: preferences)
      #expect(try await TextLinesTool.executeEncoded(lines.input, options: lines.options).text == "a\nb")
      let url = try SpotlightCommand.parse("url-codec 编码 hello world", preferences: preferences)
      #expect(try await UrlCodecTool.executeEncoded(url.input, options: url.options).text == "hello%20world")
    }
  }
  @Test func translatedOperationsRoundTripForEveryContributedLanguage() throws {
    var preferences = SpotlightPreferences()
    preferences.enabled = true
    for tool in SpotlightCatalog.tools { preferences.setEnabled(true, for: tool.id) }
    for language in L10n.languages {
      try L10n.$overrideLanguage.withValue(language.id) {
        for key in SpotlightCatalog.operationKeys.values { #expect(language.strings[key] != nil) }
        for tool in SpotlightCatalog.tools {
          for action in tool.actions {
            let localized = action.example(command: tool.id)
            let canonical = ([tool.id] + [action.operation].compactMap { $0 } + [action.exampleInput]).joined(separator: " ")
            let expected = try SpotlightCommand.parse(canonical, preferences: preferences)
            let actual = try SpotlightCommand.parse(localized, preferences: preferences)
            #expect(actual.id == expected.id)
            #expect(actual.input.text == expected.input.text)
            let actualOptions = try JSONSerialization.jsonObject(with: actual.options) as! NSDictionary
            let expectedOptions = try JSONSerialization.jsonObject(with: expected.options) as! NSDictionary
            #expect(actualOptions == expectedOptions, "\(language.id): \(localized)")
          }
        }
      }
    }
  }
  @Test func multiwordOperationsAndLanguageSwitchesKeepInputIntact() throws {
    let preferences = enabled("text-lines", "base64")
    try L10n.$overrideLanguage.withValue("en") {
      let request = try SpotlightCommand.parse("text-lines Remove Empty Lines\t  hello\n\n", preferences: preferences)
      #expect(try JSONDecoder().decode(TextLinesTool.Options.self, from: request.options).mode == "remove-empty")
      #expect(request.input.text == "  hello\n\n")
      #expect(try SpotlightCommand.parse("base64 编码 hello", preferences: preferences).input.text == "hello")
      #expect(SpotlightCatalog.tools.first { $0.id == "base64" }?.example(alias: "base64") == "base64 encode hello")
    }
    L10n.$overrideLanguage.withValue("zh-Hans") {
      #expect(SpotlightCatalog.tools.first { $0.id == "base64" }?.example(alias: "base64") == "base64 编码 hello")
    }
  }
  @Test func localizedCommandsKeepValidationAndPermissions() {
    var preferences = enabled("base64")
    for command in ["base64 编码器 hello", "base64 解码", "base64 编码 " + String(repeating: "你", count: 5500)] {
      #expect(throws: ToolFailure.self) { try SpotlightCommand.parse(command, preferences: preferences) }
    }
    preferences.setEnabled(false, for: "base64")
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("base64 编码 hello", preferences: preferences) }
    preferences.setEnabled(true, for: "base64"); preferences.enabled = false
    #expect(throws: ToolFailure.self) { try SpotlightCommand.parse("编码 hello", toolID: "base64", preferences: preferences) }
  }
  @Test func namingFormatsShareTranslationsAndExecuteInBothLanguages() async throws {
    let preferences = enabled("text-case")
    let cases = [
      ("camelCase", "小驼峰", "Camel Case", "helloWorld"),
      ("PascalCase", "大驼峰", "Pascal Case", "HelloWorld"),
      ("snake_case", "下划线", "Snake Case", "hello_world"),
      ("kebab-case", "短横线", "Kebab Case", "hello-world"),
      ("UPPERCASE", "大写", "Uppercase", "HELLO WORLD"),
      ("lowercase", "小写", "Lowercase", "hello world"),
    ]
    for (mode, chinese, english, expected) in cases {
      for (language, title) in [("zh-Hans", chinese), ("en", english)] {
        try await L10n.$overrideLanguage.withValue(language) {
          #expect(TextCaseTool.modeTitle(mode) == title)
          let action = try #require(SpotlightCatalog.actions.first { $0.id == "text-case:" + mode })
          #expect(action.name == TextCaseTool.metadata.name + " · " + title)
          for operation in [chinese, english, mode] {
            let request = try SpotlightCommand.parse("case " + operation + " hello World", preferences: preferences)
            #expect(try JSONDecoder().decode(TextCaseTool.Options.self, from: request.options).mode == mode)
            #expect(try await TextCaseTool.executeEncoded(request.input, options: request.options).text == expected)
          }
        }
      }
    }
  }
  @Test func oldQuickKeyReminderIsIgnoredWithoutResettingTools() throws {
    let old = Data(#"{"enabled":true,"quickKeyReminder":"custom","tools":{"base64":{"enabled":true,"aliases":["custom64"]}}}"#.utf8)
    let preferences = try JSONDecoder().decode(SpotlightPreferences.self, from: old)
    #expect(preferences.allows("base64"))
    #expect(try SpotlightCommand.parse("custom64 编码 hello", preferences: preferences).input.text == "hello")
    let saved = String(decoding: try JSONEncoder().encode(preferences), as: UTF8.self)
    #expect(!saved.contains("quickKeyReminder"))
  }
}
