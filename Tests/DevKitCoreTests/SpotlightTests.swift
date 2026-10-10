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
    try preferences.setAliases("b64, b", for: "base64")
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
    try preferences.setAliases("b, b64", for: "base64")
    let request = try SpotlightCommand.parse("B EnC --  你好\n$HOME \\n", preferences: preferences)
    #expect(request.input.text == " 你好\n$HOME \\n")
    let output = try await Base64Tool.executeEncoded(request.input, options: request.options)
    #expect(String(data: Data(base64Encoded: output.text)!, encoding: .utf8) == request.input.text)
    #expect(try SpotlightCommand.parse("BASE64 encode hello", preferences: preferences).input.text == "hello")
  }
  @Test func aliasesCannotShadowOtherToolsOrEachOther() throws {
    var preferences = enabled("base64")
    for invalid in ["json", "url-codec", "url", "b64,b64", "123", "bad/name", ""] {
      #expect(throws: ToolFailure.self) { try preferences.setAliases(invalid, for: "base64") }
    }
    try preferences.setAliases("b64, encode64", for: "base64")
    #expect(preferences.aliases(for: "base64") == ["b64", "encode64"])
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
    try preferences.setAliases("b64, b", for: "base64")
    try preferences.save(to: defaults)
    #expect(SpotlightPreferences.load(from: defaults) == preferences)
    defaults.set(Data("broken".utf8), forKey: SpotlightPreferences.storageKey)
    #expect(!SpotlightPreferences.load(from: defaults).enabled)
  }
}
