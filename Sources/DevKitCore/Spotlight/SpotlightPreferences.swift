import Foundation

public struct SpotlightToolPreference: Codable, Equatable, Sendable {
  public var enabled = false
  /// Retained to decode commands saved by earlier versions; there is no alias editor.
  public var aliases: [String] = []
  public init(enabled: Bool = false, aliases: [String] = []) {
    self.enabled = enabled; self.aliases = aliases
  }
}
public struct SpotlightPreferences: Codable, Equatable, Sendable {
  public static let storageKey = "spotlightPreferencesV1"
  public var enabled = false
  public var tools: [String: SpotlightToolPreference] = [:]
  public init() {}
  public func allows(_ toolID: String) -> Bool { enabled && tools[toolID]?.enabled == true }
  public func aliases(for toolID: String) -> [String] {
    tools[toolID]?.aliases.isEmpty == false ? tools[toolID]!.aliases : [SpotlightCatalog.defaultAlias(for: toolID)]
  }
  public mutating func setEnabled(_ value: Bool, for toolID: String) {
    var entry = tools[toolID] ?? SpotlightToolPreference()
    entry.enabled = value; tools[toolID] = entry
  }
  public static func load(from defaults: UserDefaults = .standard) -> Self {
    guard let data = defaults.data(forKey: storageKey), let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
    return value
  }
  public func save(to defaults: UserDefaults = .standard) throws {
    defaults.set(try JSONEncoder().encode(self), forKey: Self.storageKey)
  }
}
