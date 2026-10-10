import Foundation

public enum BoxShadowTool: ToolModule {
  public struct Options: ToolOptions {
    public var x: Int = 0
    public var y: Int = 12
    public var blur: Int = 30
    public var spread: Int = 0
    public var color: String = "#00000033"
    public var inset: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "box-shadow", "阴影生成", .css, "偏移、模糊、扩散与内阴影，预览后复制 CSS。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("x", "水平 px", \.x, range: -500...500),
      .init("y", "垂直 px", \.y, range: -500...500),
      .init("blur", "模糊 px", \.blur, range: 0...500),
      .init("spread", "扩散 px", \.spread, range: -500...500),
      .init("color", "阴影颜色", \.color),
      .init("inset", "内阴影", \.inset),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (-500...500).contains(options.x) && (-500...500).contains(options.y)
        && (0...500).contains(options.blur)
        && (-500...500).contains(options.spread), "阴影参数超出范围。")
    let color = try ColorValue.parse(options.color)
    let css =
      "box-shadow: \(options.inset ? "inset " : "")\(options.x)px \(options.y)px \(options.blur)px \(options.spread)px \(color.css);"
    return ToolOutput(css, html: cssPreview(css + "border-radius:20px;"))
  }
}
