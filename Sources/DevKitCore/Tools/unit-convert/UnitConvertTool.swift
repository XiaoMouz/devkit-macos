import Foundation

public enum UnitConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var from: String = "KiB" {
      didSet { if !UnitConvertTool.compatibleUnits(from).contains(to) { to = UnitConvertTool.compatibleUnits(from).first ?? from } }
    }
    public var to: String = "B"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "unit-convert", "Unit Conversion", .numbers, "File sizes, durations, and rates, with explicit SI and IEC units.", sample: "1024", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "from", L10n.tr("Source Unit"), \.from,
        choices: [
          "B", "KB", "MB", "GB", "KiB", "MiB", "GiB", "ms", "s", "min", "h", "bit/s", "Kbit/s",
          "Mbit/s", "MB/s",
        ]),
      .init(
        "to", L10n.tr("Target Unit"), \.to,
        choices: [
          "B", "KB", "MB", "GB", "KiB", "MiB", "GiB", "ms", "s", "min", "h", "bit/s", "Kbit/s",
          "Mbit/s", "MB/s",
        ]),
    ]
  }
  public static func compatibleUnits(_ unit: String) -> [String] {
    let groups = [["B", "KB", "MB", "GB", "KiB", "MiB", "GiB"], ["ms", "s", "min", "h"], ["bit/s", "Kbit/s", "Mbit/s", "MB/s"]]
    return groups.first { $0.contains(unit) } ?? []
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    [fields[0], .init("to", L10n.tr("Target Unit"), \.to, choices: compatibleUnits(options.from))]
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
      throw ToolFailure(L10n.tr("Source and target must belong to the same unit category."))
    }
    let value = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      value.range(of: "^[+-]?[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil,
      L10n.tr("Enter a decimal number."))
    guard let n = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")), !n.isNaN else { throw ToolFailure(L10n.tr("Invalid number.")) }
    let result = n * from.1 / to.1
    try require(!result.isNaN, L10n.tr("Result is out of range."))
    return ToolOutput(NSDecimalNumber(decimal: result).stringValue + " " + options.to)
  }
}
