import Foundation

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
    let rows = [
      ResultRow("协议", c.scheme ?? ""), ResultRow("主机", c.host ?? ""),
      ResultRow("端口", c.port.map(String.init) ?? ""), ResultRow("路径", c.path),
      ResultRow("查询", c.percentEncodedQuery ?? ""), ResultRow("片段", c.fragment ?? ""),
      ResultRow("完整 URL", c.string ?? ""),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
