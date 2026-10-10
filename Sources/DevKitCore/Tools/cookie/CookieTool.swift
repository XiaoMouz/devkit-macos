import Foundation

public enum CookieTool: ToolModule {
  public struct Options: ToolOptions {
    public var mode: String = "set-cookie"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "cookie", "Cookie", .web, "Cookie / Set-Cookie 字段解析，不修改浏览器。",
    sample: "session=example; Path=/; HttpOnly; Secure; SameSite=Lax", secondary: "", input: .text,
    network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("mode", "类型", \.mode, choices: ["set-cookie", "cookie"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let parts = input.text.components(separatedBy: ";")
    var rows = [ResultRow]()
    for (index, part) in parts.enumerated() {
      let item = part.trimmingCharacters(in: .whitespaces)
      if let equals = item.firstIndex(of: "=") {
        rows.append(ResultRow(String(item[..<equals]), String(item[item.index(after: equals)...])))
      } else if !item.isEmpty {
        rows.append(ResultRow(item, options.mode == "set-cookie" && index > 0 ? "true" : ""))
      }
    }
    try require(!rows.isEmpty, "请输入 Cookie 字段；多个 Set-Cookie 请逐条处理。")
    return ToolOutput(
      try prettyJSON(rows.map { ["name": $0.label, "value": $0.value] }), rows: rows,
      note: "值不自动 URL 解码；重复键按原顺序保留。")
  }
}
