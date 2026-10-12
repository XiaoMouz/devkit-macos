import Foundation

public enum CookieTool: ToolModule {
  public struct Options: ToolOptions {
    public var mode: String = "set-cookie"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "cookie", "Cookie", .web, "Parse Cookie and Set-Cookie fields without modifying your browser.",
    sample: "session=example; Path=/; HttpOnly; Secure; SameSite=Lax", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("mode", L10n.tr("Type"), \.mode, choices: ["set-cookie", "cookie"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(["set-cookie", "cookie"].contains(options.mode), L10n.tr("Invalid Cookie type."))
    let lines = input.text.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    try require(!lines.isEmpty, L10n.tr("Enter a Cookie field."))
    var rows = [ResultRow]()
    var values = [[String: String]]()
    for (lineIndex, line) in lines.enumerated() {
      let prefix = options.mode == "set-cookie" ? "Set-Cookie:" : "Cookie:"
      let content = line.lowercased().hasPrefix(prefix.lowercased()) ? String(line.dropFirst(prefix.count)) : line
      let parts = content.components(separatedBy: ";")
      for (index, part) in parts.enumerated() {
        let item = part.trimmingCharacters(in: .whitespaces)
        guard !item.isEmpty else { continue }
        let pair = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        let name = String(pair[0]).trimmingCharacters(in: .whitespaces)
        try require(!name.isEmpty, L10n.tr("Cookie names cannot be empty."))
        if options.mode == "set-cookie" && index == 0 {
          try require(pair.count == 2, L10n.tr("Each Set-Cookie entry must start with name=value."))
        }
        let value = pair.count == 2 ? String(pair[1]) : options.mode == "set-cookie" && index > 0 ? "true" : ""
        let label = lines.count > 1 ? L10n.tr("Entry \(lineIndex + 1) · \(name)") : name
        rows.append(ResultRow(label, value))
        var entry = ["name": name, "value": value]
        if lines.count > 1 { entry["header"] = String(lineIndex + 1) }
        values.append(entry)
      }
    }
    try require(!rows.isEmpty, L10n.tr("Enter a Cookie field."))
    return ToolOutput(try prettyJSON(values), rows: rows,
      note: L10n.tr("Each line is parsed separately. Commas in Expires are preserved. Values are not URL-decoded; duplicate keys keep their original order."))
  }
}
