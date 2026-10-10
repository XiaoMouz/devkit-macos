import Foundation

/// Business ordering is separate from available space. Every relevant field is
/// visible when it fits; only width overflow goes into More.
public struct WorkspaceParameterPlan: Equatable, Sendable {
  public let fieldIDs: [String]

  public init(toolID: String, availableFields: [String]) {
    let priority: [String]
    switch toolID {
    case "json": priority = ["syntax", "path", "name"]
    case "regex": priority = ["pattern", "flags", "replacement"]
    case "text-replace": priority = ["search", "replacement", "regex", "flags"]
    case "hmac": priority = ["algorithm", "keyFormat", "key", "output"]
    case "jwt": priority = ["verify", "key"]
    case "code-format": priority = ["dialect", "indent"]
    default: priority = []
    }
    var placed = Set<String>()
    fieldIDs = (priority + availableFields).filter {
      availableFields.contains($0) && placed.insert($0).inserted
    }
  }

  public func layout(availableWidth: Double, minimumWidths: [String: Double],
    spacing: Double = 14, moreWidth: Double = 104) -> WorkspaceParameterLayout {
    guard !fieldIDs.isEmpty else { return WorkspaceParameterLayout(rows: [], overflow: []) }
    let width = max(0, availableWidth)
    func pack(reserveMore: Bool) -> [[String]] {
      var rows: [[String]] = [[]]
      var used = 0.0
      for id in fieldIDs {
        let needed = max(0, minimumWidths[id] ?? 180)
        var limit = width - (reserveMore && rows.count == 2 ? moreWidth + spacing : 0)
        var gap = rows.last!.isEmpty ? 0 : spacing
        if used + gap + needed > limit {
          guard rows.count < 2 else { break }
          rows.append([])
          used = 0; gap = 0
          limit = width - (reserveMore ? moreWidth + spacing : 0)
        }
        guard needed <= limit else { break }
        rows[rows.count - 1].append(id)
        used += gap + needed
      }
      // Preserve an empty second row when it is needed to hold More itself.
      return rows.allSatisfy(\.isEmpty) ? [[]] : rows
    }
    let all = pack(reserveMore: false)
    if all.flatMap({ $0 }).count == fieldIDs.count {
      return WorkspaceParameterLayout(rows: all, overflow: [])
    }
    let rows = pack(reserveMore: true)
    return WorkspaceParameterLayout(rows: rows, overflow: Array(fieldIDs.dropFirst(rows.flatMap { $0 }.count)))
  }
}

public struct WorkspaceParameterLayout: Equatable, Sendable {
  public let rows: [[String]]
  public let overflow: [String]
}
