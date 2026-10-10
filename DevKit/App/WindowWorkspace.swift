import DevKitCore
import SwiftUI

@MainActor final class ToolTab: Identifiable {
  let id: UUID
  let metadata: ToolMetadata
  let bridge = WorkspaceBridge()
  private let makeView: @MainActor () -> AnyView
  var view: AnyView { makeView() }
  let primaryControl: AnyView
  let configuration: AnyView
  let footer: AnyView
  let hasConfiguration: Bool
  let sourceClosed: @MainActor @Sendable () -> Void
  deinit {
    let close = sourceClosed
    Task { @MainActor in close() }
  }
  init<T: ToolModule>(id: UUID, type: T.Type) {
    self.id = id
    metadata = T.metadata
    if T.metadata.id == "websocket" {
      let model = SocketSession()
      let bridge = bridge
      makeView = { AnyView(WebSocketWorkspace(bridge: bridge, model: model)) }
      primaryControl = AnyView(EmptyView())
      configuration = AnyView(SocketConfiguration(model: model))
      footer = AnyView(SocketFooter(model: model))
      hasConfiguration = true
      sourceClosed = { model.disconnect() }
    } else {
      let session = ToolSession<T>(id: id, bridge: bridge)
      makeView = { AnyView(ToolWorkspace<T>(session: session)) }
      primaryControl = AnyView(ToolPrimaryControl(session: session))
      configuration = AnyView(ToolConfiguration(session: session))
      footer = AnyView(ToolFooter(session: session))
      hasConfiguration = false
      sourceClosed = { session.sourceClosed() }
    }
  }
}

@MainActor @Observable final class WindowWorkspace {
  var searchRequest = 0
  // Publish one command object for the lifetime of this window, not new closures
  // for every layout pass. Actions resolve the selected session when invoked.
  @ObservationIgnored lazy var commands = WorkspaceActions(
    run: { [weak self] in self?.active?.bridge.execute() },
    copy: { [weak self] in self?.active?.bridge.copy() },
    search: { [weak self] in self?.searchRequest += 1 },
    selectPane: { [weak self] in self?.active?.bridge.selectPane($0) },
    canSelectPane: { [weak self] in
      guard let active = self?.active else { return false }
      return active.metadata.id != "websocket"
    })
  private(set) var navigation = WorkspaceNavigation()
  private var sessions: [UUID: ToolTab] = [:]
  init() { open("base64") }
  var tabs: [ToolTab] { navigation.tabs.compactMap { sessions[$0.id] } }
  var active: ToolTab? { navigation.selectedID.flatMap { sessions[$0] } }
  func open(_ toolID: String, newInstance: Bool = false) {
    if !newInstance && navigation.selectedToolID == toolID { return }
    guard let type = ToolRegistry.find(toolID) else { return }
    let tab = navigation.open(toolID, newInstance: newInstance)
    if sessions[tab.id] == nil { sessions[tab.id] = ToolTab(id: tab.id, type: type) }
  }
  func select(_ id: UUID) { navigation.select(id) }
  func showOverview() { navigation.showOverview() }
  func close(_ id: UUID) {
    sessions[id]?.sourceClosed()
    navigation.close(id)
    sessions[id] = nil
  }
}
