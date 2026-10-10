import Foundation

public enum CssGradientTool: ToolModule {
  public struct Options: ToolOptions {
    public var kind: String = "linear"
    public var start: String = "#3478F6"
    public var end: String = "#A66BFF"
    public var angle: Int = 135
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "css-gradient", "渐变生成", .css, "两色线性 / 径向渐变，生成 CSS 并预览。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("kind", "类型", \.kind, choices: ["linear", "radial"]),
      .init("start", "起始颜色", \.start),
      .init("end", "结束颜色", \.end),
      .init("angle", "角度", \.angle, range: -360...360),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let a = try ColorValue.parse(options.start)
    let b = try ColorValue.parse(options.end)
    try require((-360...360).contains(options.angle), "角度范围为 -360–360。")
    let css =
      "background: "
      + (options.kind == "radial"
        ? "radial-gradient(circle, \(a.css) 0%, \(b.css) 100%);"
        : "linear-gradient(\(options.angle)deg, \(a.css) 0%, \(b.css) 100%);")
    return ToolOutput(css, html: cssPreview(css + "border-radius:24px;"))
  }
}
