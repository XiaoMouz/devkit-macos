import Foundation
import Testing
@testable import DevKitCore

@Suite("Real tool workflows") struct ScenarioTests {
  @Test func jsonOperationsShareOnePublicEntry() async throws {
    #expect(ToolRegistry.all.filter { $0.metadata.id.hasPrefix("json") }.map { $0.metadata.id } == ["json"])
    for operation in ["format", "minify", "validate", "tree", "query", "schema", "diff", "typescript"] {
      var options = JsonTool.Options()
      options.operation = operation
      options.path = "$.users[0].name"
      let result = try await JsonTool.execute(JsonTool.example(for: options), options: options)
      #expect(!result.text.isEmpty)
      if operation == "query" { #expect(result.text.contains("Ada")) }
      if operation == "typescript" { #expect(result.text.hasPrefix("export type Root")) }
      if operation == "diff" { #expect(result.rows.contains { $0.label == "~ /version" }) }
      if operation == "schema" { #expect(result.text.contains("校验通过")) }
    }
  }
  @Test(arguments: ["L", "M", "Q", "H"])
  func qrImagesCanBeRecognized(_ correction: String) async throws {
    var options = QrCodeTool.Options()
    options.correction = correction
    let value = "https://example.test/search?q=开发工具&emoji=😀"
    let generated = try await QrCodeTool.execute(.init(text: value), options: options)
    let image = try #require(generated.artifacts.first)
    #expect(image.mime == "image/png")
    options.operation = "scan"
    #expect(QrCodeTool.inputStyle(for: options) == .file)
    #expect(QrCodeTool.visibleFields(for: options).map(\.id) == ["operation"])
    #expect(try await QrCodeTool.execute(.init(file: image.data), options: options).text == value)
    await #expect(throws: ToolFailure.self) {
      try await QrCodeTool.execute(.init(text: value), options: options)
    }
  }
  @Test func qrRejectsEmptyAndInvalidGeneration() async {
    await #expect(throws: ToolFailure.self) { try await QrCodeTool.execute(.init(), options: .init()) }
    var options = QrCodeTool.Options()
    options.correction = "invalid"
    await #expect(throws: ToolFailure.self) { try await QrCodeTool.execute(.init(text: "hello"), options: options) }
  }
  @Test func queryBuilderPreservesReservedCharactersFlagsAndDuplicateKeys() async throws {
    let pairs = "[{\"name\":\"q&=\",\"value\":\"hello + 世界&#\"},{\"name\":\"tag\",\"value\":\"a\"},{\"name\":\"tag\",\"value\":\"b\"},{\"name\":\"flag\",\"value\":null},{\"name\":\"empty\",\"value\":\"\"}]"
    var options = QueryStringTool.Options()
    for form in [true, false] {
      options.form = form
      options.operation = "build"
      let query = try await QueryStringTool.execute(.init(text: pairs), options: options).text
      #expect(query.contains("q%26%3D="))
      options.operation = "parse"
      let parsed = try await QueryStringTool.execute(.init(text: "https://example.test/?" + query + "#fragment"), options: options)
      #expect(parsed.rows.map(\.label) == ["q&=", "tag", "tag", "flag", "empty"])
      #expect(parsed.rows.map(\.value) == ["hello + 世界&#", "a", "b", "(无值)", ""])
      #expect(try await QueryStringTool.execute(.init(text: "q=你好"), options: options).rows.first?.value == "你好")
    }
  }
  @Test func selectedLanguageHasAValidExample() async throws {
    for language in ["javascript", "typescript", "html", "css", "sql"] {
      var options = CodeFormatTool.Options()
      options.language = language
      #expect(!(try await CodeFormatTool.execute(CodeFormatTool.example(for: options), options: options)).text.isEmpty)
      #expect(CodeFormatTool.visibleFields(for: options).contains { $0.id == "dialect" } == (language == "sql"))
    }
    for language in ["javascript", "html", "css"] {
      var options = CodeMinifyTool.Options(); options.language = language
      #expect(!(try await CodeMinifyTool.execute(CodeMinifyTool.example(for: options), options: options)).text.isEmpty)
    }
  }
  @Test func unitChangesStayWithinOneDimension() async throws {
    var options = UnitConvertTool.Options()
    options.from = "h"
    #expect(UnitConvertTool.compatibleUnits(options.from).contains(options.to))
    options.to = "min"
    #expect(try await UnitConvertTool.execute(.init(text: "1.5"), options: options).text == "90 min")
  }
  @Test func ulidGenerateAndParseUseDifferentInputs() async throws {
    var options = UlidTool.Options()
    #expect(UlidTool.inputStyle(for: options) == .generator)
    let value = try await UlidTool.execute(.init(), options: options).rows[0].value
    options.operation = "parse"
    #expect(UlidTool.inputStyle(for: options) == .text)
    #expect(UlidTool.visibleFields(for: options).map(\.id) == ["operation"])
    #expect(Dates.parse(try await UlidTool.execute(.init(text: value), options: options).text) != nil)
    var preferences = SpotlightPreferences(); preferences.enabled = true; preferences.setEnabled(true, for: "ulid")
    let request = try SpotlightCommand.parse("ulid generate 3", preferences: preferences)
    #expect(try await UlidTool.executeEncoded(request.input, options: request.options).rows.count == 3)
  }
}
