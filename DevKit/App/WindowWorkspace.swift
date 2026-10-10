import DevKitCore
import SwiftUI

@MainActor final class ToolTab: Identifiable {
  let id: UUID
  let metadata: ToolMetadata
  let bridge = WorkspaceBridge()
  let view: AnyView
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
      view = AnyView(WebSocketWorkspace(bridge: bridge, model: model))
      primaryControl = AnyView(EmptyView())
      configuration = AnyView(SocketConfiguration(model: model))
      footer = AnyView(SocketFooter(model: model))
      hasConfiguration = true
      sourceClosed = {}
    } else {
      let session = ToolSession<T>(id: id, bridge: bridge)
      view = AnyView(ToolWorkspace<T>(session: session))
      primaryControl = AnyView(ToolPrimaryControl(session: session))
      configuration = AnyView(ToolConfiguration(session: session))
      footer = AnyView(ToolFooter(session: session))
      hasConfiguration = T.fields.contains { $0.id != primaryToolField(T.self)?.id }
      sourceClosed = { session.sourceClosed() }
    }
  }
}

@MainActor @Observable final class WindowWorkspace {
  private(set) var navigation = WorkspaceNavigation()
  private var sessions: [UUID: ToolTab] = [:]
  var tabs: [ToolTab] { navigation.tabs.compactMap { sessions[$0.id] } }
  var active: ToolTab? { navigation.selectedID.flatMap { sessions[$0] } }
  func open(_ toolID: String, newInstance: Bool = false) {
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
