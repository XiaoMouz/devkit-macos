import Foundation

public enum NumberFormatTool: ToolModule {
  public struct Options: ToolOptions {
    public var scale: Int = 2
    public var rounding: String = "plain"
    public var grouping: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "number-format", "数字格式", .numbers, "Decimal 十进制舍入与千分位，最多 38 位有效数字。", sample: "1234567.895",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("scale", "小数位", \.scale, range: 0...20),
      .init("rounding", "舍入方式", \.rounding, choices: ["plain", "bankers", "down", "up"]),
      .init("grouping", "千分位", \.grouping),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let value = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      value.range(of: "^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$", options: .regularExpression)
        != nil, "请输入普通十进制数字，不含分组符。")
    try require(
      value.filter { $0.isNumber }.drop(while: { $0 == "0" }).count <= 38
        && (0...20).contains(options.scale), "最多 38 位有效数字，小数位 0–20。")
    guard var number = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")),
      !number.isNaN
    else { throw ToolFailure("数字超出 Decimal 范围。") }
    var rounded = Decimal()
    let mode: Decimal.RoundingMode =
      options.rounding == "bankers"
      ? .bankers : options.rounding == "down" ? .down : options.rounding == "up" ? .up : .plain
    NSDecimalRound(&rounded, &number, options.scale, mode)
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.numberStyle = .decimal
    f.usesGroupingSeparator = options.grouping
    f.minimumFractionDigits = options.scale
    f.maximumFractionDigits = options.scale
    return ToolOutput(
      f.string(from: NSDecimalNumber(decimal: rounded))
        ?? NSDecimalNumber(decimal: rounded).stringValue)
  }
}
