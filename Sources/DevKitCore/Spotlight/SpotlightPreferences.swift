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
    try require(!aliases.isEmpty, "至少保留一个命令别名。")
    try require(Set(aliases).count == aliases.count, "别名不能重复。")
    for alias in aliases {
      try require(alias.range(of: "^[a-z][a-z0-9-]{0,23}$", options: .regularExpression) != nil,
        "别名以英文字母开头，可含字母、数字和连字符，最多 24 个字符。")
      for other in SpotlightCatalog.tools where other.id != toolID {
        try require(other.id != alias && !self.aliases(for: other.id).contains(alias), "别名 \(alias) 已用于\(other.name)。")
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
