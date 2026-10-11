import Foundation
import Network

public enum UrlParserTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "url-parser", "URL 解析", .web, "分解协议、主机、端口、路径、查询与片段。",
    sample: "https://example.com:8080/api/users?q=hello%20world#result", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let c = URLComponents(string: input.text), c.scheme != nil else {
      throw ToolFailure("请输入带协议的有效 URL。")
    }
    if let host = c.host, host.hasPrefix("[") || host.hasSuffix("]") {
      let literal = String(host.dropFirst().dropLast())
      try require(host.hasPrefix("[") && host.hasSuffix("]") && IPv6Address(literal) != nil,
        "方括号中的主机必须是有效的 IPv6 地址。")
    }
    if ["http", "https", "ws", "wss", "ftp"].contains(c.scheme?.lowercased() ?? "") {
      try require(!(c.host ?? "").isEmpty, "此协议需要有效的主机名。")
    }
    let rows = [
      ResultRow("协议", c.scheme ?? ""), ResultRow("主机", c.host ?? ""),
      ResultRow("端口", c.port.map(String.init) ?? ""), ResultRow("路径", c.path),
      ResultRow("查询", c.percentEncodedQuery ?? ""), ResultRow("片段", c.fragment ?? ""),
      ResultRow("完整 URL", c.string ?? ""),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
