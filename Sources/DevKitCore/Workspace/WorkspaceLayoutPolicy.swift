import Foundation

public enum WorkspaceLayoutPreference: String, CaseIterable, Sendable {
  case automatic, split, focused
}
public enum WorkspaceLayoutMode: Sendable { case split, focused }

/// Content decisions are committed at paste/import, editing boundaries, or execution.
/// Width is resolved per window; a manual preference is never overwritten by content.
public struct WorkspaceLayoutPolicy: Sendable {
  public static let minimumSplitWidth = 560.0
  public var preference: WorkspaceLayoutPreference = .automatic
  public private(set) var contentMode: WorkspaceLayoutMode = .split
  public init() {}
  public mutating func evaluate(texts: [String], fileBytes: Int = 0) {
    if fileBytes > 2048 || texts.contains(where: Self.isLarge) {
      contentMode = .focused
    } else if fileBytes <= 1024 && texts.allSatisfy(Self.isSmall) {
      contentMode = .split
    }
  }
  public func mode(width: Double) -> WorkspaceLayoutMode {
    guard width >= Self.minimumSplitWidth else { return .focused }
    switch preference {
    case .automatic: return contentMode
    case .split: return .split
    case .focused: return .focused
    }
  }
  private static func isLarge(_ value: String) -> Bool {
    if value.utf8.count > 2048 { return true }
    let lines = value.split(separator: "\n", omittingEmptySubsequences: false)
    return lines.count > 24 || lines.contains { $0.count > 512 }
  }
  private static func isSmall(_ value: String) -> Bool {
    if value.utf8.count > 1024 { return false }
    let lines = value.split(separator: "\n", omittingEmptySubsequences: false)
    return lines.count <= 12 && lines.allSatisfy { $0.count <= 256 }
  }
}
