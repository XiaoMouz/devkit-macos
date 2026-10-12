import Foundation
import UniformTypeIdentifiers

public enum HttpClientTool: ToolModule {
  public struct Options: ToolOptions {
    public var method: String = "GET"
    public var headers: String = "{}"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "http-client", "HTTP Client", .web, "Send requests explicitly. Responses, status, and timing stay in the current session.", sample: "https://example.com",
    secondary: "", input: .pair, network: true)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "method", L10n.tr("Method"), \.method,
        choices: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]),
      .init("headers", L10n.tr("Headers JSON"), \.headers),
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
    else { throw ToolFailure(L10n.tr("An HTTP or HTTPS URL is required. Put credentials explicitly in headers.")) }
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
      try require(body.count < 5 * 1024 * 1024, L10n.tr("Response exceeds 5 MiB. Reading has stopped."))
      body.append(byte)
    }
    guard let http = response as? HTTPURLResponse else { throw ToolFailure(L10n.tr("The response is not HTTP.")) }
    var rows = [
      ResultRow(
        L10n.tr("Status"),
        "\(http.statusCode) \(HttpStatusTool.phrase(http.statusCode))"),
      ResultRow(L10n.tr("Duration"), String(format: "%.0f ms", Date().timeIntervalSince(start) * 1000)),
      ResultRow(L10n.tr("Final URL"), response.url?.absoluteString ?? ""),
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
    output.note = L10n.tr("Status \(http.statusCode) · \(body.count) bytes")
    return output
  }
}
