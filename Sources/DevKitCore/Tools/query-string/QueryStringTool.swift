import Foundation

public enum QueryStringTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "parse"
    public var form: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "query-string", "Query Parameters", .web, "Convert JSON name-value pairs and query strings, preserving duplicate keys and empty values.",
    sample: "tag=swift&tag=web&q=hello+world", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", L10n.tr("Operation"), \.operation, choices: ["parse", "build", "sort"]),
      .init("form", L10n.tr("Treat + as Space in Forms"), \.form),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try convert(input, options: options)
  }
  public static func convert(_ input: ToolInput, options: Options) throws -> ToolOutput {
    try require(["parse", "build", "sort"].contains(options.operation), L10n.tr("Invalid query parameter operation."))
    var c = URLComponents()
    if options.operation == "build" {
      guard let pairs = try jsonObject(input.text) as? [[String: Any]] else {
        throw ToolFailure(L10n.tr("Enter [{\"name\":\"q\",\"value\":\"hello\"}]."))
      }
      c.queryItems = try pairs.map { pair in
        guard let name = pair["name"] as? String else { throw ToolFailure(L10n.tr("Each item requires a name field.")) }
        try require(pair["value"] == nil || pair["value"] is NSNull || pair["value"] is String, L10n.tr("Parameter values must be text or absent."))
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
    guard text.removingPercentEncoding != nil else { throw ToolFailure(L10n.tr("Invalid percent encoding.")) }
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
      try prettyJSON(values), rows: items.map { ResultRow($0.name, $0.value ?? L10n.tr("(No value)")) })
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
