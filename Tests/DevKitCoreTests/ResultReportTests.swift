import Foundation
import Testing
@testable import DevKitCore

@Suite("Functional result reports") struct ResultReportTests {
  @Test func base64TextStaysTextAndBinaryIsRejected() async throws {
    var options = Base64Tool.Options()
    for original in ["hello", "你好 😀\n", ""] {
      options.operation = "encode"
      let encoded = try await Base64Tool.execute(.init(text: original), options: options)
      options.operation = "decode"
      let decoded = try await Base64Tool.execute(.init(text: encoded.text), options: options)
      #expect(decoded.text == original)
      #expect(decoded.artifacts.isEmpty)
    }
    await #expect(throws: ToolFailure.self) {
      try await Base64Tool.execute(.init(text: "/w=="), options: options)
    }
  }
  @Test func urlExamplesMatchEachModeAndDirection() async throws {
    for mode in ["component", "url", "form"] {
      var options = UrlCodecTool.Options(); options.mode = mode
      let source = UrlCodecTool.example(for: options)
      let encoded = try await UrlCodecTool.execute(source, options: options)
      options.operation = "decode"
      #expect(UrlCodecTool.example(for: options).text == encoded.text)
      #expect(try await UrlCodecTool.execute(UrlCodecTool.example(for: options), options: options).text == source.text)
    }
  }
  @Test func formattedJSONHasFoldingCountsAndEscapedExactValues() async throws {
    let source = #"{"items":[1,2,3,4,5,6],"empty":[],"n":9007199254740993,"html":"</summary><script>alert(1)</script>"}"#
    let result = try await JsonTool.execute(.init(text: source), options: .init())
    let html = try #require(result.html)
    #expect(html.contains("<details open>"))
    #expect(html.contains("数组大小 6"))
    #expect(html.contains("数组大小 0"))
    #expect(html.contains("9007199254740993"))
    #expect(!html.contains("<script>"))
    #expect(!result.text.contains("数组大小"))
  }
  @Test func jsonValidationHasMetricsAndLocalizedFailureLocation() async throws {
    var options = JsonTool.Options(); options.operation = "validate"
    let good = try await JsonTool.execute(.init(text: #"{"items":[1,2,3,4,5,6]}"#), options: options)
    #expect(good.report?.state == "success")
    #expect(good.report?.metrics.first { $0.label == "数组元素" }?.value == "6")
    let bad = try await JsonTool.execute(.init(text: "{\n  \"a\":\n}"), options: options)
    #expect(bad.report?.state == "failure")
    #expect(bad.rows.first?.label.contains("第 3 行") == true)
    #expect(bad.html?.contains("numbered error") == true)
  }
  @Test func jsonDiffReportsChangesAndIgnoresObjectKeyOrder() async throws {
    var options = JsonTool.Options(); options.operation = "diff"
    let same = try await JsonTool.execute(.init(text: #"{"a":1,"b":[]}"#, secondary: #"{"b":[],"a":1}"#), options: options)
    #expect(same.report?.state == "success")
    #expect(same.rows.isEmpty)
    #expect(same.html?.contains("原始 JSON") == true)
    let changed = try await JsonTool.execute(.init(text: #"{"a/b":{"~key":1},"gone":true}"#, secondary: #"{"a/b":{"~key":2},"new":[1]}"#), options: options)
    #expect(changed.rows.contains { $0.label == "~ /a~1b/~0key" })
    #expect(changed.report?.metrics.map(\.value) == ["1", "1", "1"])
    #expect(changed.html?.contains("line change") == true)
    #expect(changed.html?.contains("line add") == true)
    #expect(changed.html?.contains("line remove") == true)
    let root = try await JsonTool.execute(.init(text: "1", secondary: "null"), options: options)
    #expect(root.rows.first?.label == "~ /")
  }
  @Test func schemaErrorsAreChineseAndHighlightDataAndRules() async throws {
    var options = JsonTool.Options(); options.operation = "schema"
    let schema = #"{"type":"object","required":["a/b"],"additionalProperties":false,"properties":{"a/b":{"type":"string"},"items":{"type":"array","minItems":2}}}"#
    let result = try await JsonTool.execute(.init(text: #"{"items":[],"extra":1}"#, secondary: schema), options: options)
    #expect(result.report?.state == "failure")
    #expect(result.rows.contains { $0.label == "/a~1b" && $0.value.contains("缺少必填字段") })
    #expect(result.rows.contains { $0.label == "/extra" && $0.value.contains("不允许字段") })
    #expect(result.rows.contains { $0.label == "/items" && $0.value.contains("数组至少需要 2") })
    #expect(!result.text.contains("must"))
    #expect(result.html?.contains("line error") == true)
    #expect(result.html?.contains("/properties/items/minItems") == true)
    let valid = try await JsonTool.execute(.init(text: #"{"a/b":"ok","items":[1,2]}"#, secondary: schema), options: options)
    #expect(valid.report?.state == "success")
    let scalar = try await JsonTool.execute(.init(text: "false", secondary: "false"), options: options)
    #expect(scalar.report?.state == "failure")
  }
  @Test func queryRequiresJSONPathButAllowsRootPointer() async throws {
    var options = JsonTool.Options(); options.operation = "query"; options.path = " "
    await #expect(throws: (any Error).self) {
      try await JsonTool.execute(.init(text: "{}"), options: options)
    }
    options.syntax = "pointer"
    #expect(try await JsonTool.execute(.init(text: "{}"), options: options).text == "{}")
  }
  @Test func textAndFileComparisonHaveSharedReports() async throws {
    var options = TextDiffTool.Options(); options.ignoreWhitespace = true
    let same = try await TextDiffTool.execute(.init(text: " hello \nworld", secondary: "hello\nworld"), options: options)
    #expect(same.report?.state == "success")
    let diff = try await TextDiffTool.execute(.init(text: "old\nkeep", secondary: "new\nkeep"), options: options)
    #expect(diff.rows.contains { $0.label == "− 原文第 1 行" })
    #expect(diff.rows.contains { $0.label == "+ 对比第 1 行" })
    #expect(diff.html?.contains("line remove") == true)
    var checksum = FileChecksumTool.Options()
    checksum.expected = Digest.compute(Data("hello".utf8), algorithm: "SHA-256")
    let good = try await FileChecksumTool.execute(.init(file: Data("hello".utf8)), options: checksum)
    #expect(good.report?.state == "success")
    checksum.expected = "wrong"
    let bad = try await FileChecksumTool.execute(.init(file: Data("hello".utf8)), options: checksum)
    #expect(bad.report?.state == "failure")
    #expect(bad.rows.count == 2)
  }
}
