import Foundation
import UniformTypeIdentifiers

public enum HttpClientTool: ToolModule {
  public struct Options: ToolOptions {
    public var method: String = "GET"
    public var headers: String = "{}"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "http-client", "HTTP 调试", .web, "显式发送请求；响应、状态与耗时仅留在当前会话。", sample: "https://example.com",
    secondary: "", input: .pair, network: true)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "method", "方法", \.method,
        choices: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]),
      .init("headers", "请求头 JSON", \.headers),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    do { return try await request(input, options: options) }
    catch is CancellationError { throw CancellationError() }
    catch { throw ToolFailure(NetworkSupport.message(for: error)) }
  }
  private static func request(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let url = URL(string: input.text.trimmingCharacters(in: .whitespacesAndNewlines)),
      ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil, url.user == nil,
      url.password == nil
    else { throw ToolFailure("需要 HTTP / HTTPS URL，凭证请显式放入请求头。") }
    let headers = try NetworkSupport.headers(options.headers)
    var request = URLRequest(url: url)
    request.httpMethod = options.method
    request.timeoutInterval = 15
    request.allHTTPHeaderFields = headers
    if !input.secondary.isEmpty { request.httpBody = Data(input.secondary.utf8) }
    let session = NetworkSupport.session()
    defer { session.invalidateAndCancel() }
    let start = Date()
    let (stream, response) = try await session.bytes(for: request)
    var body = Data()
    for try await byte in stream {
      try Task.checkCancellation()
      try require(body.count < 5 * 1024 * 1024, "响应超过 5 MiB，已停止读取。")
      body.append(byte)
    }
    guard let http = response as? HTTPURLResponse else { throw ToolFailure("响应不是 HTTP。") }
    var rows = [
      ResultRow(
        "状态",
        "\(http.statusCode) \(HttpStatusTool.phrase(http.statusCode))"),
      ResultRow("耗时", String(format: "%.0f ms", Date().timeIntervalSince(start) * 1000)),
      ResultRow("最终 URL", response.url?.absoluteString ?? ""),
    ]
    rows += http.allHeaderFields.map {
      ResultRow(String(describing: $0.key), String(describing: $0.value))
    }.sorted { $0.label < $1.label }
    let mime = response.mimeType ?? "application/octet-stream"
    let suffix = UTType(mimeType: mime)?.preferredFilenameExtension ?? "bin"
    let filename = "response." + suffix
    var output = textOrArtifact(body, name: filename, mime: mime)
    if !body.isEmpty && output.artifacts.isEmpty { output.artifacts = [Artifact(filename, mime, body)] }
    output.rows = rows
    output.note = "状态 \(http.statusCode) · \(body.count) 字节"
    return output
  }
}
