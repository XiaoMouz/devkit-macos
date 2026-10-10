import Foundation

/// A window has one selected tab. Sidebar selection is derived, never synchronized by callbacks.
public struct WorkspaceNavigation: Sendable {
  public struct Tab: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let toolID: String
  }
  public private(set) var tabs: [Tab] = []
  public private(set) var selectedID: UUID?
  public var selectedToolID: String? { tabs.first { $0.id == selectedID }?.toolID }
  public init() {}

  @discardableResult public mutating func open(_ toolID: String, newInstance: Bool = false) -> Tab {
    if !newInstance, let existing = tabs.first(where: { $0.toolID == toolID }) {
      selectedID = existing.id
      return existing
    }
    let tab = Tab(id: UUID(), toolID: toolID)
    tabs.append(tab)
    selectedID = tab.id
    return tab
  }
  public mutating func select(_ id: UUID) {
    guard tabs.contains(where: { $0.id == id }) else { return }
    selectedID = id
  }
  public mutating func showOverview() { selectedID = nil }
  public mutating func close(_ id: UUID) {
    guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
    tabs.remove(at: index)
    if selectedID == id { selectedID = tabs.isEmpty ? nil : tabs[min(index, tabs.count - 1)].id }
  }
}
