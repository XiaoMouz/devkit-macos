import Foundation

public enum CssUnitTool: ToolModule {
  public struct Options: ToolOptions {
    public var from: String = "px"
    public var to: String = "rem"
    public var root: Int = 16
    public var parent: Int = 16
    public var width: Int = 1440
    public var height: Int = 900
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "css-unit", "CSS Units", .css, "Convert px, rem, em, vw, and vh with explicit, adjustable base dimensions.", sample: "24", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("from", L10n.tr("Source Unit"), \.from, choices: ["px", "rem", "em", "vw", "vh"]),
      .init("to", L10n.tr("Target Unit"), \.to, choices: ["px", "rem", "em", "vw", "vh"]),
      .init("root", L10n.tr("Root Font Size (px)"), \.root, range: 1...256),
      .init("parent", L10n.tr("Parent Font Size (px)"), \.parent, range: 1...256),
      .init("width", L10n.tr("Viewport Width (px)"), \.width, range: 1...20000),
      .init("height", L10n.tr("Viewport Height (px)"), \.height, range: 1...20000),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in !(["root": "rem", "parent": "em", "width": "vw", "height": "vh"].keys.contains(field.id)) || [options.from, options.to].contains(["root": "rem", "parent": "em", "width": "vw", "height": "vh"][field.id]!) }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let value = Double(input.text.trimmingCharacters(in: .whitespacesAndNewlines)),
      value.isFinite
    else { throw ToolFailure(L10n.tr("Enter a finite number.")) }
    try require(
      (1...256).contains(options.root) && (1...256).contains(options.parent)
        && (1...20000).contains(options.width) && (1...20000).contains(options.height),
      L10n.tr("Root and parent font sizes must be 1–256 px; viewport dimensions must be 1–20,000 px."))
    let scales = [
      "px": 1.0, "rem": Double(options.root), "em": Double(options.parent),
      "vw": Double(options.width) / 100, "vh": Double(options.height) / 100,
    ]
    guard let from = scales[options.from], let to = scales[options.to] else {
      throw ToolFailure(L10n.tr("Invalid unit."))
    }
    let result = value * from / to
    try require(result.isFinite, L10n.tr("The result is out of range."))
    return ToolOutput(String(format: "%.8g", result) + options.to)
  }
}
