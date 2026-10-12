import Foundation

public struct SpotlightToolPreference: Codable, Equatable, Sendable {
  public var enabled = false
  public var aliases: [String] = []
  public init(enabled: Bool = false, aliases: [String] = []) {
    self.enabled = enabled; self.aliases = aliases
  }
}
public struct SpotlightPreferences: Codable, Equatable, Sendable {
  public static let storageKey = "spotlightPreferencesV1"
  public var enabled = false
  public var tools: [String: SpotlightToolPreference] = [:]
  /// A reminder only: macOS owns the actual Quick Key assignment.
  public var quickKeyReminder = "dk"
  public init() {}
  public func allows(_ toolID: String) -> Bool { enabled && tools[toolID]?.enabled == true }
  public func aliases(for toolID: String) -> [String] {
    tools[toolID]?.aliases.isEmpty == false ? tools[toolID]!.aliases : [SpotlightCatalog.defaultAlias(for: toolID)]
  }
  public mutating func setEnabled(_ value: Bool, for toolID: String) {
    var entry = tools[toolID] ?? SpotlightToolPreference()
    entry.enabled = value; tools[toolID] = entry
  }
  public mutating func setAliases(_ text: String, for toolID: String) throws {
    let aliases = text.lowercased().split(whereSeparator: { $0 == "," || $0 == "，" || $0.isWhitespace }).map(String.init)
    try require(!aliases.isEmpty, L10n.tr("Keep at least one command alias."))
    try require(Set(aliases).count == aliases.count, L10n.tr("Aliases must be unique."))
    for alias in aliases {
      try require(alias.range(of: "^[a-z][a-z0-9-]{0,23}$", options: .regularExpression) != nil,
        L10n.tr("Aliases must start with an English letter and contain only letters, digits, and hyphens, up to 24 characters."))
      for other in SpotlightCatalog.tools where other.id != toolID {
        try require(other.id != alias && !self.aliases(for: other.id).contains(alias), L10n.tr("Alias \(alias) is already used by \(other.name)."))
      }
    }
    var entry = tools[toolID] ?? SpotlightToolPreference()
    entry.aliases = aliases; tools[toolID] = entry
  }
  public static func load(from defaults: UserDefaults = .standard) -> Self {
    guard let data = defaults.data(forKey: storageKey), let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
    return value
  }
  public func save(to defaults: UserDefaults = .standard) throws {
    defaults.set(try JSONEncoder().encode(self), forKey: Self.storageKey)
  }
}
