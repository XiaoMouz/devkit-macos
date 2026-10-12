import Foundation

public enum ContrastTool: ToolModule {
  public struct Options: ToolOptions {
    public var background: String = "#3478F6"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "contrast", "Color Contrast", .css, "WCAG 2.2 relative luminance contrast, with separate results for normal and large text.", sample: "#FFFFFF", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("background", L10n.tr("Background Color"), \.background)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let foreground = try ColorValue.parse(input.text)
    let background = try ColorValue.parse(options.background)
    try require(foreground.a == 1 && background.a == 1, L10n.tr("Composite transparent colors first. This tool requires opaque foreground and background colors."))
    let ratio =
      (max(foreground.luminance, background.luminance) + 0.05)
      / (min(foreground.luminance, background.luminance) + 0.05)
    let displayRatio = String(format: "%.4f:1", ratio)
    let nearThreshold = [3.0, 4.5, 7.0].first { ratio < $0 && $0 - ratio < 0.005 }
    let precisionNote = nearThreshold.map { L10n.tr("The actual ratio is just below \($0):1. Evaluation uses the unrounded value.") } ?? L10n.tr("Evaluation uses the unrounded value.")
    let rows = [
      ResultRow(L10n.tr("Contrast Ratio"), displayRatio),
      ResultRow(L10n.tr("AA Normal Text ≥4.5"), ratio >= 4.5 ? L10n.tr("Pass") : L10n.tr("Failed")),
      ResultRow(L10n.tr("AA Large Text ≥3"), ratio >= 3 ? L10n.tr("Pass") : L10n.tr("Failed")),
      ResultRow(L10n.tr("AAA Normal Text ≥7"), ratio >= 7 ? L10n.tr("Pass") : L10n.tr("Failed")),
      ResultRow(L10n.tr("AAA Large Text ≥4.5"), ratio >= 4.5 ? L10n.tr("Pass") : L10n.tr("Failed")),
    ]
    return ToolOutput(
      rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows,
      html: cssPreview(
        "background:\(background.css);color:\(foreground.css);border-radius:16px;",
        content: L10n.tr("Aa Contrast Preview")), note: L10n.tr("WCAG 2.2. Large text is at least 18 pt, or 14 pt bold.") + precisionNote,
      report: ResultReport(ratio >= 4.5 ? "success" : "failure", ratio >= 4.5 ? L10n.tr("Normal Text Passes AA Contrast") : L10n.tr("Normal Text Fails AA Contrast"),
        ratio >= 4.5 ? L10n.tr("These colors meet AA for normal text. See the results for each level below.") : L10n.tr("Darken the foreground or lighten the background to reach a contrast ratio of 4.5:1."),
        metrics: [ResultRow(L10n.tr("Current Contrast Ratio"), displayRatio), ResultRow(L10n.tr("Normal Text AA"), "≥ 4.5:1")]))
  }
}
