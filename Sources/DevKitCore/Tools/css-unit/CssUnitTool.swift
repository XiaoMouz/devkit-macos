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
    "css-unit", "CSS 单位", .css, "px / rem / em / vw / vh，基准尺寸明确可调。", sample: "24", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("from", "源单位", \.from, choices: ["px", "rem", "em", "vw", "vh"]),
      .init("to", "目标单位", \.to, choices: ["px", "rem", "em", "vw", "vh"]),
      .init("root", "根字号 px", \.root, range: 1...256),
      .init("parent", "父字号 px", \.parent, range: 1...256),
      .init("width", "视口宽度 px", \.width, range: 1...20000),
      .init("height", "视口高度 px", \.height, range: 1...20000),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in !(["root": "rem", "parent": "em", "width": "vw", "height": "vh"].keys.contains(field.id)) || [options.from, options.to].contains(["root": "rem", "parent": "em", "width": "vw", "height": "vh"][field.id]!) }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let value = Double(input.text.trimmingCharacters(in: .whitespacesAndNewlines)),
      value.isFinite
    else { throw ToolFailure("请输入有限数字。") }
    try require(
      options.root > 0 && options.parent > 0 && options.width > 0 && options.height > 0,
      "所有基准尺寸必须大于零。")
    let scales = [
      "px": 1.0, "rem": Double(options.root), "em": Double(options.parent),
      "vw": Double(options.width) / 100, "vh": Double(options.height) / 100,
    ]
    guard let from = scales[options.from], let to = scales[options.to] else {
      throw ToolFailure("单位无效。")
    }
    let result = value * from / to
    try require(result.isFinite, "计算结果超出范围。")
    return ToolOutput(String(format: "%.8g", result) + options.to)
  }
}
