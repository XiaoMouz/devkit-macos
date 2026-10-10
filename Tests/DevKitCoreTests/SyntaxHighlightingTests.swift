import Foundation
import Testing
@testable import DevKitCore

@Suite("Offline syntax highlighting")
struct SyntaxHighlightingTests {
  @Test func jsonRangesPreserveUnicodeAndLiteralEntities() async {
    let source = #"{"名称":"🐈‍⬛ &amp; <span> \"hi\"","enabled":true,"count":-12.5}"#
    let tokens = await SyntaxHighlighter.shared.tokens(for: source, language: .json)
    let text = source as NSString
    #expect(tokens.contains { $0.kind == .key && text.substring(with: $0.range) == "\"名称\"" })
    #expect(tokens.contains { $0.kind == .string && text.substring(with: $0.range).contains("🐈‍⬛ &amp; <span>") })
    #expect(tokens.contains { $0.kind == .keyword && text.substring(with: $0.range) == "true" })
    #expect(tokens.contains { $0.kind == .number && text.substring(with: $0.range) == "-12.5" })
    #expect(tokens.allSatisfy { Range($0.range, in: source) != nil })
  }
  @Test func bundledGrammarsCoverToolContent() async {
    let examples: [(SyntaxLanguage, String)] = [
      (.javascript, "// comment\nconst sum = (a) => a + 12;"),
      (.typescript, "interface User { name: string; active: boolean }"),
      (.xml, "<svg width=\"24\"><text>&amp; 🐈</text></svg>"),
      (.css, ".card { color: #fff; padding: 12px; }"),
      (.sql, "SELECT name FROM users WHERE id = 42;"),
      (.markdown, "# Heading\n**strong** and `code`"),
      (.yaml, "name: DevKit\nenabled: true"), (.ini, "[tool]\nname = \"DevKit\""),
      (.bash, "#!/bin/bash\necho \"hello\""), (.swift, "let value: String = \"hello\""),
      (.python, "def greet(name):\n    return 'hello'"), (.java, "public class Example { int value = 1; }"),
      (.cpp, "#include <vector>\nint value = 1;"), (.csharp, "public class User { public string Name; }"),
      (.go, "package main\nfunc main() { println(42) }"), (.rust, "fn main() { let n = 42; }"),
      (.http, "HTTP/1.1 200 OK\nContent-Type: application/json\n\n{}"),
      (.diff, "--- a\n+++ b\n-old\n+new\n")
    ]
    for (language, source) in examples {
      let tokens = await SyntaxHighlighter.shared.tokens(for: source, language: language)
      #expect(!tokens.isEmpty, "Missing grammar: \(language)")
      #expect(tokens.allSatisfy { Range($0.range, in: source) != nil })
    }
  }
  @Test func stringsAndCommentsDoNotReceiveKeywordColors() async {
    let source = "// const false\nconst name = \"true const\";"
    let tokens = await SyntaxHighlighter.shared.tokens(for: source, language: .javascript)
    let text = source as NSString
    #expect(tokens.contains { $0.kind == .comment && text.substring(with: $0.range) == "// const false" })
    #expect(tokens.contains { $0.kind == .string && text.substring(with: $0.range) == "\"true const\"" })
  }
  @Test func toolModesChooseTheRightGrammar() {
    #expect(SyntaxLanguage.forTool("json", values: ["operation":"typescript"], output: true) == .typescript)
    #expect(SyntaxLanguage.forTool("json", values: ["operation":"schema"]) == .json)
    #expect(SyntaxLanguage.forTool("code-format", values: ["language":"sql"]) == .sql)
    #expect(SyntaxLanguage.forTool("code-minify", values: ["language":"html"]) == .xml)
    #expect(SyntaxLanguage.forTool("markdown", values: [:], output: true) == .xml)
    #expect(SyntaxLanguage.forTool("base64", values: ["operation":"encode"], output: true) == .plain)
    #expect(SyntaxLanguage.forTool("base64", values: ["operation":"decode"], output: true) == .automatic)
    #expect(SyntaxLanguage.automatic.resolved(for: "Just some text, true 42") == .plain)
    #expect(SyntaxLanguage.forMIME("application/problem+json; charset=utf-8") == .json)
    #expect(SyntaxLanguage.forMIME("text/css") == .css)
    #expect(SyntaxLanguage.forMIME("text/plain") == .automatic)
  }
  @Test func plainLargeAndExecutableLookingTextRemainData() async {
    let plain = await SyntaxHighlighter.shared.tokens(for: "hello 123 true", language: .plain)
    #expect(plain.isEmpty)
    let large = await SyntaxHighlighter.shared.tokens(for: String(repeating: "🐈", count: 100_001), language: .json)
    #expect(large.isEmpty)
    _ = await SyntaxHighlighter.shared.tokens(for: "throw new Error('must not run');", language: .javascript)
    let next = await SyntaxHighlighter.shared.tokens(for: "{\"ok\":true}", language: .json)
    #expect(!next.isEmpty)
  }
}
