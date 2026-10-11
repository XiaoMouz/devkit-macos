import Foundation
import Darwin
import JavaScriptCore

public enum SyntaxLanguage: String, Sendable, CaseIterable {
  case automatic, plain, json, javascript, typescript, xml, css, sql, markdown, yaml, ini
  case bash, swift, python, java, cpp, csharp, go, rust, http, diff

  public var title: String {
    switch self {
    case .automatic: "自动"; case .plain: "文本"; case .json: "JSON"
    case .javascript: "JavaScript"; case .typescript: "TypeScript"; case .xml: "HTML / XML"
    case .css: "CSS"; case .sql: "SQL"; case .markdown: "Markdown"; case .yaml: "YAML"
    case .ini: "TOML / INI"; case .bash: "Shell"; case .swift: "Swift"; case .python: "Python"
    case .java: "Java"; case .cpp: "C / C++"; case .csharp: "C#"; case .go: "Go"
    case .rust: "Rust"; case .http: "HTTP"; case .diff: "Diff"
    }
  }
  public func resolved(for text: String) -> Self {
    guard self == .automatic else { return self }
    let sample = String(text.prefix(2048)).trimmingCharacters(in: .whitespacesAndNewlines)
    if sample.hasPrefix("{") || sample.hasPrefix("[") { return .json }
    if sample.hasPrefix("<") { return .xml }
    if sample.hasPrefix("HTTP/") { return .http }
    if sample.hasPrefix("#!/") || sample.hasPrefix("curl ") { return .bash }
    if sample.hasPrefix("# ") || sample.hasPrefix("## ") || sample.hasPrefix("```") { return .markdown }
    return .plain
  }
  public static func forTool(_ id: String, values: [String: String], output: Bool = false) -> Self {
    let operation = values["operation"] ?? ""
    switch id {
    case "json":
      if !output { return .json }
      if operation == "typescript" { return .typescript }
      return ["validate", "tree", "diff", "schema"].contains(operation) ? .automatic : .json
    case "code-format", "code-minify":
      let value = values["language"] ?? "javascript"
      return value == "html" ? .xml : Self(rawValue: value) ?? .automatic
    case "markdown": return output ? .xml : .markdown
    case "svg": return .xml
    case "curl-convert": return output ? (values["format"] == "json" ? .json : .javascript) : .bash
    case "mock-data": return output && values["format"] != "csv" ? .json : .plain
    case "jwt": return output ? .json : .plain
    case "base64": return output == (operation != "decode") ? .plain : .automatic
    case "text-diff": return output ? .diff : .automatic
    case "hash", "hmac", "file-checksum", "uuid", "nanoid", "ulid", "random-string", "data-url": return .plain
    default: return .automatic
    }
  }
  public static func forMIME(_ mime: String) -> Self {
    let type = mime.lowercased().split(separator: ";").first.map(String.init) ?? ""
    if type.contains("json") { return .json }
    if type.contains("javascript") { return .javascript }
    if type.contains("typescript") { return .typescript }
    if type.contains("xml") || type == "text/html" { return .xml }
    if type == "text/css" { return .css }
    if type.contains("yaml") { return .yaml }
    if type.contains("markdown") { return .markdown }
    return .automatic
  }
}

public struct SyntaxToken: Codable, Sendable, Equatable {
  public enum Kind: String, Codable, Sendable, CaseIterable { case key, string, number, keyword, type, comment, addition, deletion }
  public let location: Int
  public let length: Int
  public let kind: Kind
  public var range: NSRange { NSRange(location: location, length: length) }
}

/// One offline grammar VM, serialized away from the UI. The editor cancels stale
/// requests and applies only temporary display attributes, never attributed input.
public actor SyntaxHighlighter {
  public static let shared = SyntaxHighlighter()
  public static let maximumLength = 200_000
  private var context: JSContext?
  private var loadAttempted = false
  private var idleRelease: Task<Void, Never>?
  public func releaseResources() {
    idleRelease?.cancel(); idleRelease = nil
    context = nil; loadAttempted = false
    Task { await IdleMemoryCleanup.shared.schedule() }
  }

  public func tokens(for text: String, language: SyntaxLanguage) -> [SyntaxToken] {
    let resolved = language.resolved(for: text)
    guard resolved != .plain, !text.isEmpty, text.utf16.count <= Self.maximumLength,
      !Task.isCancelled else { return [] }
    idleRelease?.cancel()
    idleRelease = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(15)) } catch { return }
      await self?.releaseResources()
    }
    return autoreleasepool {
    if !loadAttempted {
      loadAttempted = true
      if let url = Bundle.module.url(forResource: "syntax", withExtension: "js", subdirectory: "Resources"),
        let source = try? String(contentsOf: url, encoding: .utf8), let vm = JSContext() {
        vm.evaluateScript(source)
        if vm.exception == nil { context = vm }
      }
    }
    guard let function = context?.objectForKeyedSubscript("devkitHighlight"), !function.isUndefined,
      let response = function.call(withArguments: [text, resolved.rawValue])?.toString(),
      !Task.isCancelled, let data = response.data(using: .utf8),
      let tokens = try? JSONDecoder().decode([SyntaxToken].self, from: data)
    else { return [] }
    let length = text.utf16.count
    return tokens.filter { $0.location >= 0 && $0.length > 0 && $0.location <= length && $0.length <= length - $0.location }
    }
  }
}

/// Debounced reclamation of unused allocator pages after large UI resources
/// have been released. This never evicts a user's input or completed result.
public actor IdleMemoryCleanup {
  public static let shared = IdleMemoryCleanup()
  private var pending: Task<Void, Never>?
  public func schedule() {
    pending?.cancel()
    pending = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(2)) } catch { return }
      await self?.reclaim()
    }
  }
  private func reclaim() {
    pending = nil
    malloc_zone_pressure_relief(nil, 0)
  }
}
