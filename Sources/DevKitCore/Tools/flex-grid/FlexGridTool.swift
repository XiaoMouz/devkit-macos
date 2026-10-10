import Foundation

public enum FlexGridTool: ToolModule {
  public struct Options: ToolOptions {
    public var layout: String = "grid"
    public var columns: Int = 3
    public var gap: Int = 12
    public var items: Int = 6
    public var direction: String = "row"
    public var justify: String = "space-between"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "flex-grid", "Flex 与 Grid", .css, "常用布局参数、预览与 CSS 导出。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("layout", "布局", \.layout, choices: ["grid", "flex"]),
      .init("columns", "Grid 列数", \.columns, range: 1...12),
      .init("gap", "间距 px", \.gap, range: 0...100),
      .init("items", "元素数量", \.items, range: 1...36),
      .init("direction", "Flex 方向", \.direction, choices: ["row", "column"]),
      .init(
        "justify", "主轴分布", \.justify,
        choices: ["flex-start", "center", "space-between", "space-around"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (1...12).contains(options.columns) && (0...100).contains(options.gap)
        && (1...36).contains(options.items), "布局参数超出范围。")
    try require(
      ["row", "column"].contains(options.direction)
        && ["flex-start", "center", "space-between", "space-around"].contains(options.justify),
      "布局选项无效。")
    let css =
      options.layout == "grid"
      ? "display: grid;\ngrid-template-columns: repeat(\(options.columns), 1fr);\ngap: \(options.gap)px;"
      : "display: flex;\nflex-direction: \(options.direction);\nflex-wrap: wrap;\njustify-content: \(options.justify);\ngap: \(options.gap)px;"
    let items = (1...options.items).map {
      "<div style='background:#3478f6;color:white;border-radius:12px;padding:24px;text-align:center;min-width:70px'>\($0)</div>"
    }.joined()
    return ToolOutput(css, html: "<div style='\(css)'>\(items)</div>")
  }
}
