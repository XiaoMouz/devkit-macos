import Foundation
import Observation
import Synchronization

/// Synchronous reads are safe in workers; main-thread changes invalidate only
/// views that read a translation. No view identity or tool session is replaced.
public final class LanguageSelection: Observable, Sendable {
  private let storage: Mutex<String>
  private let registrar = ObservationRegistrar()
  public init(_ language: String) { storage = Mutex(language) }
  public var identifier: String {
    registrar.access(self, keyPath: \.identifier)
    return storage.withLock { $0 }
  }
  @MainActor func select(_ language: String) {
    guard language != identifier else { return }
    registrar.withMutation(of: self, keyPath: \.identifier) {
      storage.withLock { $0 = language }
    }
  }
}

/// An English source message with positional placeholders. Arguments are substituted once,
/// after lookup, so user input is never interpreted as another translation key.
public struct LocalizedMessage: ExpressibleByStringLiteral, ExpressibleByStringInterpolation, Sendable {
  public let key: String
  public let arguments: [String]
  public init(stringLiteral value: String) { key = value; arguments = [] }
  public init(stringInterpolation: StringInterpolation) {
    key = stringInterpolation.key; arguments = stringInterpolation.arguments
  }
  public struct StringInterpolation: StringInterpolationProtocol {
    var key = ""
    var arguments: [String] = []
    public init(literalCapacity: Int, interpolationCount: Int) {
      key.reserveCapacity(literalCapacity); arguments.reserveCapacity(interpolationCount)
    }
    public mutating func appendLiteral(_ value: String) { key += value }
    public mutating func appendInterpolation<T>(_ value: T) {
      key += "{\(arguments.count)}"; arguments.append(String(describing: value))
    }
  }
}

public enum L10n {
  public struct Language: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let strings: [String: String]
  }
  public static let preferenceKey = "appLanguage"
  /// Scoped overrides keep tool tests isolated and propagate through async calls.
  @TaskLocal public static var overrideLanguage: String?
  /// An isolated selection for hosts/tests that must not mutate the app's state.
  @TaskLocal public static var selectionOverride: LanguageSelection?
  public static let languages: [Language] = {
    guard let directory = Bundle.module.resourceURL?.appendingPathComponent("Resources/Translations"),
      let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    else { return [] }
    return urls.filter { $0.pathExtension == "json" }.compactMap { url in
      guard let data = try? Data(contentsOf: url) else { return nil }
      return try? JSONDecoder().decode(Language.self, from: data)
    }.sorted { $0.id < $1.id }
  }()
  private static let catalogs = Dictionary(uniqueKeysWithValues: languages.map { ($0.id, $0.strings) })
  private static let selection: LanguageSelection = {
    let explicit = ProcessInfo.processInfo.environment["DEVKIT_LANGUAGE"]
      ?? UserDefaults.standard.string(forKey: preferenceKey)
    return LanguageSelection(resolve(preferred: explicit.flatMap { $0 == "system" ? nil : [$0] } ?? Locale.preferredLanguages))
  }()
  public static var language: String { overrideLanguage ?? (selectionOverride ?? selection).identifier }
  public static var locale: Locale { Locale(identifier: language) }
  @MainActor public static func selectLanguage(_ preference: String, systemLanguages: [String]? = nil) {
    // Locale.preferredLanguages can retain the app's AppleLanguages override.
    // Read the system domain when returning to Follow System instead.
    let system = systemLanguages
      ?? UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String]
      ?? Locale.preferredLanguages
    (selectionOverride ?? selection).select(resolve(preferred: preference == "system" ? system : [preference]))
  }
  public static func resolve(preferred: [String], available: [String]? = nil) -> String {
    let supported = available ?? languages.map(\.id)
    for preference in preferred {
      let code = preference.replacingOccurrences(of: "_", with: "-")
      if let exact = supported.first(where: { $0.caseInsensitiveCompare(code) == .orderedSame }) { return exact }
      if let match = Bundle.preferredLocalizations(from: supported, forPreferences: [code]).first,
        match.split(separator: "-").first == code.split(separator: "-").first { return match }
      let base = String(code.split(separator: "-").first ?? "")
      if supported.contains(base) { return base }
    }
    return supported.contains("en") ? "en" : "zh-Hans"
  }
  public static func tr(_ message: LocalizedMessage) -> String {
    text(message.key, arguments: message.arguments)
  }
  /// Only pass developer-authored keys. Never localize editor input or result data.
  public static func text(_ key: String, arguments: [String] = [], language: String? = nil) -> String {
    let selected = language ?? self.language
    let template = catalogs[selected]?[key] ?? catalogs["en"]?[key] ?? key
    guard !arguments.isEmpty else { return template }
    // A single pass prevents braces or percent signs inside arguments from being
    // treated as placeholders and permits translators to reorder arguments.
    let pattern = /\{([0-9]+)\}/
    return template.replacing(pattern) { match in
      guard let index = Int(match.1), arguments.indices.contains(index) else { return String(match.0) }
      return arguments[index]
    }
  }
  public static var translations: [String: String] {
    (catalogs["en"] ?? [:]).merging(catalogs[language] ?? [:]) { _, selected in selected }
  }
}
