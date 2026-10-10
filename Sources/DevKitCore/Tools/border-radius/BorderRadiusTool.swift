import Foundation

public enum BorderRadiusTool: ToolModule {
  public struct Options: ToolOptions {
    public var topLeft: Int = 32
    public var topRight: Int = 8
    public var bottomRight: Int = 32
    public var bottomLeft: Int = 8
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "border-radius", "圆角生成", .css, "分别控制四角半径，预览并复制 CSS。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("topLeft", "左上 px", \.topLeft, range: 0...1000),
      .init("topRight", "右上 px", \.topRight, range: 0...1000),
      .init("bottomRight", "右下 px", \.bottomRight, range: 0...1000),
      .init("bottomLeft", "左下 px", \.bottomLeft, range: 0...1000),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let values = [options.topLeft, options.topRight, options.bottomRight, options.bottomLeft]
    try require(values.allSatisfy { (0...1000).contains($0) }, "圆角范围为 0–1000 px。")
    let css = "border-radius: " + values.map { "\($0)px" }.joined(separator: " ") + ";"
    return ToolOutput(css, html: cssPreview(css))
  }
}
