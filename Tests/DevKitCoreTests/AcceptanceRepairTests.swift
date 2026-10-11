import CryptoKit
import Foundation
import Testing
import Synchronization
@testable import DevKitCore

@Suite("Real acceptance regressions", .serialized)
struct AcceptanceRepairTests {
  @Test func decimalFormattingKeepsAllSignificantDigits() async throws {
    var options = NumberFormatTool.Options()
    options.scale = 20
    options.grouping = false
    #expect(try await NumberFormatTool.execute(.init(text: "1.12345678901234567890"), options: options).text == "1.12345678901234567890")
    #expect(try await NumberFormatTool.execute(.init(text: "-1.12345678901234567890"), options: options).text == "-1.12345678901234567890")
    options.scale = 2
    options.grouping = true
    #expect(try await NumberFormatTool.execute(.init(text: "123456789012345678901234567890.125"), options: options).text == "123,456,789,012,345,678,901,234,567,890.13")
    options.rounding = "bankers"
    #expect(try await NumberFormatTool.execute(.init(text: "1.245"), options: options).text == "1.24")
  }

  @Test func cookiesKeepIndependentHeadersAndExpiresCommas() async throws {
    let input = "Set-Cookie: a=1; Path=/\r\nSet-Cookie: b=2; Expires=Wed, 21 Oct 2030 07:28:00 GMT; HttpOnly"
    let result = try await CookieTool.execute(.init(text: input), options: .init())
    #expect(result.rows.map(\.value) == ["1", "/", "2", "Wed, 21 Oct 2030 07:28:00 GMT", "true"])
    #expect(result.rows[0].label != result.rows[2].label)
    var options = CookieTool.Options(); options.mode = "cookie"
    #expect(try await CookieTool.execute(.init(text: "Cookie: a=1; a=2=3"), options: options).rows.map(\.value) == ["1", "2=3"])
  }

  @Test func regexAllowsExactLimitAndAdvancesUnicodeSetsZeroWidth() async throws {
    var options = RegexTool.Options(); options.pattern = "a"; options.flags = "g"
    let output = try await RegexTool.execute(.init(text: String(repeating: "a", count: 10000)), options: options)
    #expect(output.rows.count == 10000)
    await #expect(throws: ToolFailure.self) {
      try await RegexTool.execute(.init(text: String(repeating: "a", count: 10001)), options: options)
    }
    options.pattern = "(?=)"; options.flags = "gv"
    let unicode = try await RegexTool.execute(.init(text: "🌍"), options: options)
    #expect(unicode.rows.count == 2)
    #expect(unicode.rows.last?.label.hasSuffix(" 2") == true)
  }

  @Test func cssBoundsMatchDeclaredFields() async throws {
    var options = CssUnitTool.Options(); options.from = "vh"; options.to = "px"; options.height = 20000
    #expect(try await CssUnitTool.execute(.init(text: "1"), options: options).text == "200px")
    options.height = 20001
    await #expect(throws: ToolFailure.self) { try await CssUnitTool.execute(.init(text: "1"), options: options) }
    options.height = 900; options.root = 257
    await #expect(throws: ToolFailure.self) { try await CssUnitTool.execute(.init(text: "1"), options: options) }
  }

  @Test func historicalDateUsesProlepticGregorianRoundTrip() throws {
    let utc = TimeZone(secondsFromGMT: 0)!
    let earliest = Date(timeIntervalSince1970: -62135596800)
    #expect(Dates.display(earliest, timeZone: utc) == "0001-01-01 00:00:00")
    #expect(Dates.parse("0001-01-01 00:00:00", timeZone: utc) == earliest)
    #expect(Dates.parse(Dates.iso(earliest), timeZone: utc) == earliest)
    #expect(Dates.parse("1500-02-29 00:00:00", timeZone: utc) == nil)
    #expect(Dates.parse("1600-02-29 00:00:00", timeZone: utc) != nil)
  }

  @Test func allSupportedLineSeparatorsCountConsistently() async throws {
    for separator in ["\n", "\r\n", "\r", "\u{85}", "\u{2028}", "\u{2029}"] {
      let result = try await TextStatsTool.execute(.init(text: "a" + separator + "b"), options: .init())
      #expect(result.rows.first { $0.label == "行" }?.value == "2")
    }
  }

  @Test func badIPv6AndJWTStructuresAreRejected() async throws {
    await #expect(throws: ToolFailure.self) { try await UrlParserTool.execute(.init(text: "https://[bad]/"), options: .init()) }
    #expect(try await UrlParserTool.execute(.init(text: "https://[2001:db8::1]:8443/"), options: .init()).text.contains("8443"))
    await #expect(throws: ToolFailure.self) { try await JwtTool.execute(.init(text: "W10.W10."), options: .init()) }
  }

  @Test func validSignatureDoesNotHideExpiredOrFutureClaims() async throws {
    func b64(_ data: Data) -> String {
      data.base64EncodedString().replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
    }
    let header = b64(Data(#"{"alg":"HS256"}"#.utf8))
    let payload = b64(Data(#"{"exp":1,"nbf":4102444800}"#.utf8))
    let input = header + "." + payload
    let signature = b64(Data(HMAC<SHA256>.authenticationCode(for: Data(input.utf8), using: SymmetricKey(data: Data("synthetic".utf8)))))
    var options = JwtTool.Options(); options.verify = true; options.key = "synthetic"
    let result = try await JwtTool.execute(.init(text: input + "." + signature), options: options)
    #expect(result.report?.state == "warning")
    #expect(result.text.contains("已过期"))
    #expect(result.text.contains("尚未生效"))
  }

  @Test func rowDraftValidationIsReadableAndPreservesOrder() async throws {
    let rows = #"[{"name":"z","value":"index"},{"name":"a","value":"name"}]"#
    var options = MockDataTool.Options(); options.format = "csv"; options.count = 1
    #expect(try await MockDataTool.execute(.init(text: rows), options: options).text.hasPrefix("z,a\r\n"))
    for bad in [#"[{"name":"","value":"name"}]"#, #"[{"name":"x","value":"name"},{"name":"x","value":"email"}]"#] {
      await #expect(throws: ToolFailure.self) { try await MockDataTool.execute(.init(text: bad), options: options) }
    }
    #expect(try NetworkSupport.headers(#"[{"name":"X-Test","value":"one"}]"#) == ["X-Test": "one"])
    #expect(throws: ToolFailure.self) { try NetworkSupport.headers(#"[{"name":"X-Test","value":"one"},{"name":"x-test","value":"two"}]"#) }
  }

  @Test func destructiveCSSMinificationReturnsWarning() async throws {
    var options = CodeMinifyTool.Options(); options.language = "css"
    let result = try await CodeMinifyTool.execute(.init(text: "a{color:"), options: options)
    #expect(result.text.isEmpty)
    #expect(result.report?.state == "warning")
  }

  @Test func streamingChecksumReadsBeyondOldLimitAndSupportsCancellation() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("devkit-stream-" + UUID().uuidString)
    _ = FileManager.default.createFile(atPath: url.path, contents: nil)
    defer { try? FileManager.default.removeItem(at: url) }
    let file = try FileHandle(forWritingTo: url)
    try file.truncate(atOffset: 33 * 1024 * 1024)
    try file.close()
    let result = try await FileChecksumTool.stream(url, options: .init())
    let expected = Digest.compute(Data(repeating: 0, count: 33 * 1024 * 1024), algorithm: "SHA-256")
    #expect(result.text == expected)
    let cancelled = Task { try await FileChecksumTool.stream(url, options: .init()) }
    cancelled.cancel()
    await #expect(throws: CancellationError.self) { try await cancelled.value }
  }

  @Test func streamingChecksumRejectsFileModifiedDuringRead() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("devkit-mutation-" + UUID().uuidString)
    _ = FileManager.default.createFile(atPath: url.path, contents: nil)
    defer { try? FileManager.default.removeItem(at: url) }
    let file = try FileHandle(forWritingTo: url)
    try file.truncate(atOffset: 64 * 1024 * 1024)
    try file.close()
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 0)], ofItemAtPath: url.path)
    let changed = Mutex(false)
    await #expect(throws: ToolFailure.self) {
      try await FileChecksumTool.stream(url, options: .init()) { read, _ in
        changed.withLock { alreadyChanged in
          guard !alreadyChanged, read > 0 else { return }
          alreadyChanged = true
          if let writer = try? FileHandle(forWritingTo: url) {
            try? writer.seek(toOffset: 0)
            try? writer.write(contentsOf: Data([1]))
            try? writer.close()
          }
        }
      }
    }
    #expect(changed.withLock { $0 })
  }

  @Test func hugeSingleLinesUseHorizontalScrollingWithoutChangingText() {
    let boundary = String(repeating: "a", count: 16_384)
    #expect(EditorTextPolicy.shouldWrap(boundary))
    #expect(!EditorTextPolicy.shouldWrap(boundary + "a"))
    #expect(EditorTextPolicy.shouldWrap(String(repeating: "abc\n", count: 100_000)))
    #expect(EditorTextPolicy.shouldWrap(boundary + "\u{2028}" + boundary))
  }

  @Test func editorPagesPreserveSurrogatePairsAndEntireDocument() {
    let original = String(repeating: "a", count: EditorPage.size - 1) + "🌍尾" + String(repeating: "b", count: 70_000)
    var page = EditorPage()
    var reconstructed = ""
    while true {
      reconstructed += page.content(in: original)
      if !page.hasNext(in: original) { break }
      page.next(in: original)
    }
    #expect(reconstructed == original)
    #expect(!reconstructed.contains("�"))
  }
  @Test func editsInOnePagePreserveOtherPagesAndPreviousNavigation() {
    let original = String(repeating: "a", count: EditorPage.size) + "TAIL" + String(repeating: "b", count: EditorPage.size)
    var page = EditorPage()
    let first = page.content(in: original)
    let updated = page.replace(with: first + "X", in: original)
    #expect(updated == first + "XTAIL" + String(repeating: "b", count: EditorPage.size))
    page.next(in: updated)
    #expect(page.content(in: updated).hasPrefix("TAIL"))
    page.previous()
    #expect(page.content(in: updated) == first + "X")
  }

  @Test func comparisonPrecisionAndHTTPNamesAreSpecific() async throws {
    var options = ContrastTool.Options(); options.background = "#ffffff"
    let contrast = try await ContrastTool.execute(.init(text: "#959595"), options: options)
    #expect(contrast.rows.first?.value == "2.9953:1")
    #expect(contrast.note?.contains("略低于") == true)
    #expect(HttpStatusTool.phrase(200) == "OK")
    #expect(HttpStatusTool.phrase(429) == "Too Many Requests")
    #expect(HttpStatusTool.phrase(599) == "Unassigned")
  }
}
