import Foundation

public enum UnitConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var from: String = "KiB"
    public var to: String = "B"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "unit-convert", "单位转换", .numbers, "文件大小、时长和速率，明确 SI 与 IEC。", sample: "1024", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "from", "源单位", \.from,
        choices: [
          "B", "KB", "MB", "GB", "KiB", "MiB", "GiB", "ms", "s", "min", "h", "bit/s", "Kbit/s",
          "Mbit/s", "MB/s",
        ]),
      .init(
        "to", "目标单位", \.to,
        choices: [
          "B", "KB", "MB", "GB", "KiB", "MiB", "GiB", "ms", "s", "min", "h", "bit/s", "Kbit/s",
          "Mbit/s", "MB/s",
        ]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let units: [String: (String, Decimal)] = [
      "B": ("size", 1), "KB": ("size", 1000), "MB": ("size", 1_000_000),
      "GB": ("size", 1_000_000_000), "KiB": ("size", 1024), "MiB": ("size", 1_048_576),
      "GiB": ("size", 1_073_741_824), "ms": ("time", 1), "s": ("time", 1000),
      "min": ("time", 60000), "h": ("time", 3_600_000), "bit/s": ("rate", 1),
      "Kbit/s": ("rate", 1000), "Mbit/s": ("rate", 1_000_000), "MB/s": ("rate", 8_000_000),
    ]
    guard let from = units[options.from], let to = units[options.to], from.0 == to.0 else {
      throw ToolFailure("源与目标必须属于同类单位。")
    }
    let value = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      value.range(of: "^[+-]?[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil,
      "请输入十进制数字。")
    guard let n = Decimal(string: value), !n.isNaN else { throw ToolFailure("数字无效。") }
    let result = n * from.1 / to.1
    try require(!result.isNaN, "结果超出范围。")
    return ToolOutput(NSDecimalNumber(decimal: result).stringValue + " " + options.to)
  }
}
