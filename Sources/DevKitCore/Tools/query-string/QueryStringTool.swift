import Foundation

public enum QueryStringTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "parse"
    public var form: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "query-string", "查询参数", .web, "保留重复键和空值，JSON 键值对与查询字符串互转。",
    sample: "tag=swift&tag=web&q=hello+world", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["parse", "build", "sort"]),
      .init("form", "表单 + 代表空格", \.form),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    var c = URLComponents()
    if options.operation == "build" {
      guard let pairs = try jsonObject(input.text) as? [[String: Any]] else {
        throw ToolFailure("请输入 [{\"name\":\"q\",\"value\":\"hello\"}]。")
      }
      c.queryItems = try pairs.map { pair in
        guard let name = pair["name"] as? String else { throw ToolFailure("每项需要 name 字段。") }
        return URLQueryItem(name: name, value: pair["value"] as? String)
      }
      let value = c.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B") ?? ""
      return ToolOutput(options.form ? value.replacingOccurrences(of: "%20", with: "+") : value)
    }
    var text = input.text.hasPrefix("?") ? String(input.text.dropFirst()) : input.text
    if options.form { text = text.replacingOccurrences(of: "+", with: "%20") }
    guard text.removingPercentEncoding != nil else { throw ToolFailure("百分号编码无效。") }
    c.percentEncodedQuery = text
    var items = c.queryItems ?? []
    if options.operation == "sort" {
      items = items.enumerated().sorted {
        $0.element.name == $1.element.name
          ? $0.offset < $1.offset : $0.element.name < $1.element.name
      }.map(\.element)
      c.queryItems = items
      return ToolOutput(c.percentEncodedQuery ?? "")
    }
    let values: [[String: Any]] = items.map {
      ["name": $0.name, "value": $0.value as Any? ?? NSNull()]
    }
    return ToolOutput(
      try prettyJSON(values), rows: items.map { ResultRow($0.name, $0.value ?? "(无值)") })
  }
}
