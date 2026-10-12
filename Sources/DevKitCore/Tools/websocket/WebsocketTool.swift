import Foundation

public enum WebsocketTool: ToolModule {
  public struct Options: ToolOptions {
    public var message: String = "hello DevKit"
    public var count: Int = 1
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "websocket", "WebSocket Client", .web, "Connect, send, and receive manually. Sessions are not saved after disconnection.", sample: "wss://echo.websocket.org",
    secondary: "", input: .text, network: true)
  public static var fields: [OptionField<Options>] {
    [
      .init("message", L10n.tr("Send Text"), \.message),
      .init("count", L10n.tr("Messages to Receive"), \.count, range: 1...100),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let url = URL(string: input.text), ["ws", "wss"].contains(url.scheme ?? ""),
      url.host != nil
    else { throw ToolFailure(L10n.tr("A ws:// or wss:// URL is required.")) }
    try require((1...100).contains(options.count), L10n.tr("Message count must be between 1 and 100."))
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
      try require(messages.reduce(0, { $0 + $1.utf8.count }) <= 5 * 1024 * 1024, L10n.tr("Session results exceed 5 MiB."))
    }
    return ToolOutput(
      messages.joined(separator: "\n"),
      rows: messages.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
  }
}
