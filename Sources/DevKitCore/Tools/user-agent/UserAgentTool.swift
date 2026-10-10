import Foundation

public enum UserAgentTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "user-agent", "User Agent", .web, "解析常见浏览器和系统标记，保留未知字段。",
    sample:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/18.0 Safari/605.1.15",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let markers = [
      ("Edge", "Edg/"), ("Opera", "OPR/"), ("Chrome", "Chrome/"), ("Firefox", "Firefox/"),
      ("Safari", "Version/"),
    ]
    var browser = "未识别"
    var version = "未知"
    for (name, marker) in markers {
      if let range = input.text.range(of: marker) {
        browser = name
        version = String(input.text[range.upperBound...].prefix { $0.isNumber || $0 == "." })
        break
      }
    }
    let platform =
      input.text.contains("Android")
      ? "Android"
      : input.text.contains("iPhone") || input.text.contains("iPad")
        ? "iOS / iPadOS"
        : input.text.contains("Windows")
          ? "Windows"
          : input.text.contains("Macintosh")
            ? "macOS" : input.text.contains("Linux") ? "Linux" : "未识别"
    let rows = [ResultRow("浏览器", browser), ResultRow("标记版本", version), ResultRow("平台", platform)]
    return ToolOutput(
      rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows,
      note: "基于常见 UA 标记的启发式解析 v1；UA 可伪造或冻结，不推断真实设备身份。")
  }
}
