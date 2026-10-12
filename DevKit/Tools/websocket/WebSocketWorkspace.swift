import DevKitCore
import SwiftUI

@MainActor @Observable final class SocketSession {
  struct Message: Identifiable {
    let id = UUID()
    let direction: String
    let text: String
    let time = Date()
  }
  var url = ""
  var draft = ""
  var headers = "{}"
  var connected = false
  var connecting = false
  var messages: [Message] = []
  var error: String?
  var status = L10n.tr("Not Connected")
  private var session: URLSession?
  private var socket: URLSessionWebSocketTask?
  private var receiver: Task<Void, Never>?
  private var generation = UUID()
  private var totalBytes = 0
  func connect() {
    disconnect()
    do {
      guard let endpoint = URL(string: url),
        ["ws", "wss"].contains(endpoint.scheme?.lowercased() ?? ""), endpoint.host != nil,
        endpoint.user == nil, endpoint.password == nil
      else { throw ToolFailure(L10n.tr("Enter a ws:// or wss:// URL.")) }
      var request = URLRequest(url: endpoint)
      request.allHTTPHeaderFields = try NetworkSupport.headers(headers)
      let session = NetworkSupport.session(persistentConnection: true)
      self.session = session
      let socket = session.webSocketTask(with: request)
      socket.maximumMessageSize = 1024 * 1024
      self.socket = socket
      socket.resume()
      connecting = true
      status = L10n.tr("Connecting…")
      error = nil
      let current = generation
      receiver = Task {
        do {
          try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, any Error>) in
            socket.sendPing { error in
              if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
          }
          guard generation == current else { return }
          connected = true
          connecting = false
          status = L10n.tr("Connected")
          while !Task.isCancelled {
            let message = try await socket.receive()
            guard generation == current else { return }
            switch message {
            case .string(let value): try append(L10n.tr("Received"), value)
            case .data(let bytes): try append(L10n.tr("Received · Hex"), hex(bytes))
            @unknown default: break
            }
          }
        } catch {
          guard generation == current else { return }
          let code = socket.closeCode
          let reason = socket.closeReason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
          disconnect()
          if code == .normalClosure || code == .goingAway {
            self.error = nil
            status = L10n.tr("Remote closed normally (\(code.rawValue))") + (reason.isEmpty ? "" : "：" + reason)
          } else {
            self.error = NetworkSupport.message(for: error)
            status = code == .invalid ? L10n.tr("Connection interrupted unexpectedly") : L10n.tr("Remote closed (\(code.rawValue))") + (reason.isEmpty ? "" : "：" + reason)
          }
        }
      }
    } catch { self.error = NetworkSupport.message(for: error) }
  }
  func send() {
    guard connected, let socket else { return }
    let text = draft
    let current = generation
    guard text.utf8.count <= 1024 * 1024 else {
      error = L10n.tr("Each message is limited to 1 MiB.")
      return
    }
    Task {
      do {
        try await socket.send(.string(text))
        guard generation == current else { return }
        try append(L10n.tr("Send"), text)
      } catch { if generation == current { self.error = NetworkSupport.message(for: error) } }
    }
  }
  func disconnect() {
    generation = UUID()
    receiver?.cancel()
    receiver = nil
    socket?.cancel(with: .normalClosure, reason: nil)
    socket = nil
    session?.invalidateAndCancel()
    session = nil
    connected = false
    connecting = false
    status = L10n.tr("Disconnected")
  }
  func clear() {
    messages = []
    totalBytes = 0
  }
  private func append(_ direction: String, _ text: String) throws {
    try require(
      messages.count < 1000 && totalBytes + text.utf8.count <= 5 * 1024 * 1024,
      L10n.tr("The session reached 1,000 messages or 5 MiB. Clear it and reconnect."))
    totalBytes += text.utf8.count
    messages.append(Message(direction: direction, text: text))
  }
}

struct WebSocketWorkspace: View {
  @Bindable var bridge: WorkspaceBridge
  @Bindable var model: SocketSession
  @State private var pane = "send"
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        TextField(L10n.tr("wss:// or ws:// URL"), text: $model.url).textFieldStyle(.roundedBorder).disabled(
          model.connected || model.connecting)
        Button { model.send() } label: { Label(L10n.tr("Send Message"), systemImage: "paperplane") }
          .buttonStyle(.bordered).buttonBorderShape(.capsule).disabled(!model.connected)
        Menu {
          Button(L10n.tr("Copy All Messages")) { copy() }
          Button(L10n.tr("Clear Messages")) { model.clear() }
        } label: { Label(L10n.tr("More"), systemImage: "ellipsis") }.labelStyle(.iconOnly).menuStyle(.button)
          .buttonStyle(.bordered).buttonBorderShape(.capsule).fixedSize().help(L10n.tr("More Actions"))
      }.padding(.bottom, 8)
      GeometryReader { bounds in
        let split = bounds.size.width >= 720
        VStack(spacing: 8) {
          if !split {
            WorkspaceSegments(items: [(L10n.tr("Send"), "send"), (L10n.tr("Messages (\(model.messages.count))"), "messages")], selection: $pane)
          }
          WorkspacePaneDeck(roles: [.input, .output],
            visible: split ? [.input, .output] : [pane == "send" ? .input : .output],
            titles: [.input: L10n.tr("Send Message"), .output: L10n.tr("Session Messages")], actions: { _ in EmptyView() }) { role in
            if role == .input { sendPane } else { messagesPane }
          }
        }.animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: split)
      }
      HStack {
        Text(model.status)
        Spacer()
        Text(L10n.tr("Messages: \(model.messages.count)"))
      }.font(.caption).foregroundStyle(.secondary)
      if let error = model.error {
        Text(error).font(.callout).foregroundStyle(.orange).padding(14).frame(
          maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(WorkspaceMetrics.inset).background(Color(nsColor: .workspaceBase))
    .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: model.error != nil)
    .onChange(of: bridge.runRequest) { toggle() }
    .onChange(of: bridge.copyRequest) { copy() }
    .onChange(of: model.connected || model.connecting, initial: true) { _, active in
      if bridge.running != active { bridge.running = active }
    }
  }
  private var sendPane: some View {
    VStack(spacing: 0) {
      CodeEditor(text: $model.draft, label: L10n.tr("WebSocket Message to Send"))
    }.frame(minWidth: 220, maxWidth: .infinity, maxHeight: .infinity)
  }
  private var messagesPane: some View {
    VStack(spacing: 0) {
      if model.messages.isEmpty {
        ContentUnavailableView(
          L10n.tr("Waiting for Messages"), systemImage: "network", description: Text(L10n.tr("Connect and send text manually. Results stay in this tab."))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(model.messages) { message in
          Button {
            if Clipboard.copy(message.text) { model.status = L10n.tr("Message Copied") }
          } label: {
            VStack(alignment: .leading, spacing: 7) {
              HStack {
                Text(message.direction)
                Spacer()
                Text(message.time, style: .time)
              }.font(.caption).foregroundStyle(.secondary)
              HighlightedText(text: String(message.text.prefix(5000)))
                .lineLimit(12)
            }.padding(.vertical, 6)
          }.buttonStyle(.plain).help(L10n.tr("Click to copy the full message"))
        }.listStyle(.plain).scrollContentBackground(.hidden)
      }
    }.frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
  }
  private func toggle() {
    if model.connected || model.connecting {
      model.disconnect()
      bridge.running = false
    } else {
      model.connect()
      bridge.running = model.connected || model.connecting
    }
  }
  private func copy() {
    if Clipboard.copy(model.messages.map { "[\($0.direction)] \($0.text)" }.joined(separator: "\n"))
    {
      model.status = L10n.tr("Session Copied")
    }
  }
}

struct SocketConfiguration: View {
  @Bindable var model: SocketSession
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text(L10n.tr("Tool Configuration")).font(.system(size: 12, weight: .semibold))
        Text(L10n.tr("Headers")).font(.callout).foregroundStyle(.secondary)
        KeyValueEditor(text: $model.headers, kind: .headers).disabled(model.connected || model.connecting)
          .textFieldStyle(.roundedBorder).disabled(model.connected || model.connecting)
      }.padding(18)
    }
  }
}
struct SocketFooter: View {
  @Bindable var model: SocketSession
  var body: some View {
    HStack {
      Text(model.status)
      Spacer()
      Text(L10n.tr("Messages: \(model.messages.count) · Session is not saved"))
    }.font(.system(size: 11)).foregroundStyle(.secondary)
  }
}
