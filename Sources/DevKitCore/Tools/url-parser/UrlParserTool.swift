import Foundation
import Network

public enum UrlParserTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "url-parser", "URL Parser", .web, "Split URLs into scheme, host, port, path, query, and fragment.",
    sample: "https://example.com:8080/api/users?q=hello%20world#result", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let c = URLComponents(string: input.text), c.scheme != nil else {
      throw ToolFailure(L10n.tr("Enter a valid URL with a scheme."))
    }
    if let host = c.host, host.hasPrefix("[") || host.hasSuffix("]") {
      let literal = String(host.dropFirst().dropLast())
      try require(host.hasPrefix("[") && host.hasSuffix("]") && IPv6Address(literal) != nil,
        L10n.tr("A host in square brackets must be a valid IPv6 address."))
    }
    if ["http", "https", "ws", "wss", "ftp"].contains(c.scheme?.lowercased() ?? "") {
      try require(!(c.host ?? "").isEmpty, L10n.tr("This scheme requires a valid host name."))
    }
    let rows = [
      ResultRow(L10n.tr("Scheme"), c.scheme ?? ""), ResultRow(L10n.tr("Host"), c.host ?? ""),
      ResultRow(L10n.tr("Port"), c.port.map(String.init) ?? ""), ResultRow(L10n.tr("Path"), c.path),
      ResultRow(L10n.tr("Query"), c.percentEncodedQuery ?? ""), ResultRow(L10n.tr("Fragment"), c.fragment ?? ""),
      ResultRow(L10n.tr("Full URL"), c.string ?? ""),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
