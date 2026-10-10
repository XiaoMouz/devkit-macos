import Foundation

public enum WebsocketTool: ToolModule {
  public struct Options: ToolOptions {
    public var message: String = "hello DevKit"
    public var count: Int = 1
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "websocket", "WebSocket 调试", .web, "手动连接、发送与接收，断开后不保存会话。", sample: "wss://echo.websocket.org",
    secondary: "", input: .text, network: true)
  public static var fields: [OptionField<Options>] {
    [
      .init("message", "发送文本", \.message),
      .init("count", "接收消息数", \.count, range: 1...100),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let url = URL(string: input.text), ["ws", "wss"].contains(url.scheme ?? ""),
      url.host != nil
    else { throw ToolFailure("需要 ws:// 或 wss:// 地址。") }
    try require((1...100).contains(options.count), "消息数量必须为 1–100。")
    let session = NetworkSupport.session()
    defer { session.invalidateAndCancel() }
    let socket = session.webSocketTask(with: url)
    socket.maximumMessageSize = 1024 * 1024
    socket.resume()
    defer { socket.cancel(with: .normalClosure, reason: nil) }
    try await socket.send(.string(options.message))
    var messages = [String]()
    for _ in 0..<options.count {
      let message = try await socket.receive()
      switch message {
      case .string(let value): messages.append(value)
      case .data(let value): messages.append(hex(value))
      @unknown default: break
      }
      try require(messages.reduce(0, { $0 + $1.utf8.count }) <= 5 * 1024 * 1024, "会话结果超过 5 MiB。")
    }
    return ToolOutput(
      messages.joined(separator: "\n"),
      rows: messages.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
  }
}
