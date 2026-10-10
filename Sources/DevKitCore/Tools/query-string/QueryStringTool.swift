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
    try convert(input, options: options)
  }
  public static func convert(_ input: ToolInput, options: Options) throws -> ToolOutput {
    try require(["parse", "build", "sort"].contains(options.operation), "查询参数操作无效。")
    var c = URLComponents()
    if options.operation == "build" {
      guard let pairs = try jsonObject(input.text) as? [[String: Any]] else {
        throw ToolFailure("请输入 [{\"name\":\"q\",\"value\":\"hello\"}]。")
      }
      c.queryItems = try pairs.map { pair in
        guard let name = pair["name"] as? String else { throw ToolFailure("每项需要 name 字段。") }
        try require(pair["value"] == nil || pair["value"] is NSNull || pair["value"] is String, "参数值必须是文本或无值。")
        return URLQueryItem(name: name, value: pair["value"] as? String)
      }
      return ToolOutput(serialize(c.queryItems ?? [], form: options.form))
    }
    let raw = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    var text: String
    if let url = URLComponents(string: raw), url.scheme != nil {
      text = url.percentEncodedQuery ?? ""
    } else { text = raw.hasPrefix("?") ? String(raw.dropFirst()) : raw }
    if options.form { text = text.replacingOccurrences(of: "+", with: "%20") }
    guard text.removingPercentEncoding != nil else { throw ToolFailure("百分号编码无效。") }
    var allowed = CharacterSet.urlQueryAllowed
    allowed.insert(charactersIn: "%")
    allowed.remove(charactersIn: "#")
    c.percentEncodedQuery = text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    var items = c.queryItems ?? []
    if options.operation == "sort" {
      items = items.enumerated().sorted {
        $0.element.name == $1.element.name
          ? $0.offset < $1.offset : $0.element.name < $1.element.name
      }.map(\.element)
      c.queryItems = items
      return ToolOutput(serialize(items, form: options.form))
    }
    let values: [[String: Any]] = items.map {
      ["name": $0.name, "value": $0.value as Any? ?? NSNull()]
    }
    return ToolOutput(
      try prettyJSON(values), rows: items.map { ResultRow($0.name, $0.value ?? "(无值)") })
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: options.operation == "build" ? "[{\"name\":\"q\",\"value\":\"hello world\"},{\"name\":\"tag\",\"value\":\"swift\"}]" : metadata.sample)
  }
  private static func serialize(_ items: [URLQueryItem], form: Bool) -> String {
    let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    func encode(_ value: String) -> String {
      let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
      return form ? encoded.replacingOccurrences(of: "%20", with: "+") : encoded
    }
    return items.map { encode($0.name) + ($0.value.map { "=" + encode($0) } ?? "") }.joined(separator: "&")
  }

}
