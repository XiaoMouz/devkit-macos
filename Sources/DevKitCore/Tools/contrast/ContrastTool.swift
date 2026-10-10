import Foundation

public enum ContrastTool: ToolModule {
  public struct Options: ToolOptions {
    public var background: String = "#3478F6"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "contrast", "颜色对比度", .css, "WCAG 2.2 相对亮度对比值，普通和大号文字分开。", sample: "#FFFFFF", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("background", "背景颜色", \.background)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let foreground = try ColorValue.parse(input.text)
    let background = try ColorValue.parse(options.background)
    try require(foreground.a == 1 && background.a == 1, "请先合成透明颜色；此工具要求不透明前景与背景。")
    let ratio =
      (max(foreground.luminance, background.luminance) + 0.05)
      / (min(foreground.luminance, background.luminance) + 0.05)
    let rows = [
      ResultRow("对比值", String(format: "%.2f:1", ratio)),
      ResultRow("AA 普通文字 ≥4.5", ratio >= 4.5 ? "通过" : "未通过"),
      ResultRow("AA 大号文字 ≥3", ratio >= 3 ? "通过" : "未通过"),
      ResultRow("AAA 普通文字 ≥7", ratio >= 7 ? "通过" : "未通过"),
    ]
    return ToolOutput(
      rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows,
      html: cssPreview(
        "background:\(background.css);color:\(foreground.css);border-radius:16px;",
        content: "Aa 对比预览"), note: "WCAG 2.2；大号文字为 ≥18pt 或 ≥14pt 粗体。",
      report: ResultReport(ratio >= 4.5 ? "success" : "failure", ratio >= 4.5 ? "普通文字 AA 对比度通过" : "普通文字 AA 对比度未通过",
        ratio >= 4.5 ? "当前颜色达到普通文字 AA 标准，各等级结果见下方。" : "建议加深前景色或提高背景亮度，使对比值达到 4.5:1。",
        metrics: [ResultRow("当前对比值", String(format: "%.2f:1", ratio)), ResultRow("普通文字 AA", "≥ 4.5:1")]))
  }
}
