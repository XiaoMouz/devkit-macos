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
  var status = "尚未连接"
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
      else { throw ToolFailure("请输入 ws:// 或 wss:// 地址。") }
      var request = URLRequest(url: endpoint)
      request.allHTTPHeaderFields = try NetworkSupport.headers(headers)
      let session = NetworkSupport.session(persistentConnection: true)
      self.session = session
      let socket = session.webSocketTask(with: request)
      socket.maximumMessageSize = 1024 * 1024
      self.socket = socket
      socket.resume()
      connecting = true
      status = "连接中…"
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
          status = "已连接"
          while !Task.isCancelled {
            let message = try await socket.receive()
            guard generation == current else { return }
            switch message {
            case .string(let value): try append("接收", value)
            case .data(let bytes): try append("接收 · Hex", hex(bytes))
            @unknown default: break
            }
          }
        } catch {
          guard generation == current else { return }
          self.error = error.localizedDescription
          disconnect()
          status = "连接已结束"
        }
      }
    } catch { self.error = error.localizedDescription }
  }
  func send() {
    guard connected, let socket else { return }
    let text = draft
    let current = generation
    guard text.utf8.count <= 1024 * 1024 else {
      error = "单条消息上限 1 MiB。"
      return
    }
    Task {
      do {
        try await socket.send(.string(text))
        guard generation == current else { return }
        try append("发送", text)
      } catch { if generation == current { self.error = error.localizedDescription } }
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
    status = "已断开"
  }
  func clear() {
    messages = []
    totalBytes = 0
  }
  private func append(_ direction: String, _ text: String) throws {
    try require(
      messages.count < 1000 && totalBytes + text.utf8.count <= 5 * 1024 * 1024,
      "会话已达 1000 条或 5 MiB 上限；清空后重新连接。")
    totalBytes += text.utf8.count
    messages.append(Message(direction: direction, text: text))
  }
}

struct WebSocketWorkspace: View {
  @Bindable var bridge: WorkspaceBridge
  @Bindable var model: SocketSession
  @State private var pane = "send"
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        TextField("wss:// 或 ws:// 地址", text: $model.url).textFieldStyle(.roundedBorder).disabled(
          model.connected || model.connecting)
        Button { model.send() } label: { Label("发送消息", systemImage: "paperplane") }
          .buttonStyle(.bordered).disabled(!model.connected)
        Menu {
          Button("复制全部消息") { copy() }
          Button("清空消息") { model.clear() }
        } label: { Label("更多", systemImage: "ellipsis") }.labelStyle(.iconOnly).menuStyle(.button)
          .buttonStyle(.bordered).fixedSize().help("更多操作")
      }.padding(.bottom, 8)
      GeometryReader { bounds in
        if bounds.size.width >= 720 {
          WorkspaceColumns {
            sendPane.floatingPane()
          } second: {
            messagesPane.floatingPane()
          }
        } else {
          VStack(spacing: 0) {
            WorkspaceSegments(items: [("发送", "send"), ("消息（\(model.messages.count)）", "messages")], selection: $pane)
              .padding(10)
            if pane == "send" { sendPane } else { messagesPane }
          }.frame(maxWidth: .infinity, maxHeight: .infinity).floatingPane()
        }
      }
      HStack {
        Text(model.status)
        Spacer()
        Text("\(model.messages.count) 条消息")
      }.font(.caption).foregroundStyle(.secondary)
      if let error = model.error {
        Text(error).font(.callout).foregroundStyle(.orange).padding(14).frame(
          maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(16).background(Color(nsColor: .workspaceBase))
    .onChange(of: bridge.runRequest) { toggle() }
    .onChange(of: bridge.copyRequest) { copy() }
    .onChange(of: model.connected || model.connecting) { _, active in bridge.running = active }
    .onDisappear { model.disconnect() }
  }
  private var sendPane: some View {
    VStack(spacing: 0) {
      CodeEditor(text: $model.draft, label: "WebSocket 待发送消息")
    }.frame(minWidth: 220, maxWidth: .infinity, maxHeight: .infinity)
  }
  private var messagesPane: some View {
    VStack(spacing: 0) {
      if model.messages.isEmpty {
        ContentUnavailableView(
          "等待消息", systemImage: "network", description: Text("连接后手动发送文本；结果留在当前标签页。")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(model.messages) { message in
          Button {
            if Clipboard.copy(message.text) { model.status = "已复制消息" }
          } label: {
            VStack(alignment: .leading, spacing: 7) {
              HStack {
                Text(message.direction)
                Spacer()
                Text(message.time, style: .time)
              }.font(.caption).foregroundStyle(.secondary)
              Text(String(message.text.prefix(5000))).font(.system(.body, design: .monospaced))
                .lineLimit(12)
            }.padding(.vertical, 6)
          }.buttonStyle(.plain).help("点击复制完整消息")
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
      model.status = "已复制会话"
    }
  }
}

struct SocketConfiguration: View {
  @Bindable var model: SocketSession
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text("工具配置").font(.system(size: 12, weight: .semibold))
        Text("请求头").font(.callout).foregroundStyle(.secondary)
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
      Text("\(model.messages.count) 条消息 · 会话不保存")
    }.font(.system(size: 11)).foregroundStyle(.secondary)
  }
}
