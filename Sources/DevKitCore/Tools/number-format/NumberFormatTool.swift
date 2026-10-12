import Foundation

public enum NumberFormatTool: ToolModule {
  public struct Options: ToolOptions {
    public var scale: Int = 2
    public var rounding: String = "plain"
    public var grouping: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "number-format", "Number Format", .numbers, "Decimal rounding and grouping, with up to 38 significant digits.", sample: "1234567.895",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("scale", L10n.tr("Decimal Places"), \.scale, range: 0...20),
      .init("rounding", L10n.tr("Rounding Mode"), \.rounding, choices: ["plain", "bankers", "down", "up"]),
      .init("grouping", L10n.tr("Thousands Separator"), \.grouping),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let value = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      value.range(of: "^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$", options: .regularExpression)
        != nil, L10n.tr("Enter a plain decimal number without grouping separators."))
    try require(
      value.filter { $0.isNumber }.drop(while: { $0 == "0" }).count <= 38
        && (0...20).contains(options.scale), L10n.tr("Supports up to 38 significant digits and 0–20 decimal places."))
    guard var number = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")),
      !number.isNaN
    else { throw ToolFailure(L10n.tr("Number is outside the Decimal range.")) }
    var rounded = Decimal()
    let mode: Decimal.RoundingMode =
      options.rounding == "bankers"
      ? .bankers : options.rounding == "down" ? .down : options.rounding == "up" ? .up : .plain
    NSDecimalRound(&rounded, &number, options.scale, mode)
    // NumberFormatter can round NSDecimalNumber through a binary floating-point
    // representation. Format the rounded decimal digits without that conversion.
    let plain = NSDecimalString(&rounded, Locale(identifier: "en_US_POSIX"))
    let negative = plain.hasPrefix("-")
    let digits = negative ? String(plain.dropFirst()) : plain
    let parts = digits.split(separator: ".", omittingEmptySubsequences: false)
    var integer = String(parts[0])
    if options.grouping {
      integer = String(integer.reversed().enumerated().flatMap { index, digit -> [Character] in
        index > 0 && index % 3 == 0 ? [",", digit] : [digit]
      }.reversed())
    }
    let fraction = parts.count > 1 ? String(parts[1]) : ""
    let suffix = options.scale == 0 ? "" : "." + fraction
      + String(repeating: "0", count: max(0, options.scale - fraction.count))
    return ToolOutput((negative ? "-" : "") + integer + suffix)
  }
}
