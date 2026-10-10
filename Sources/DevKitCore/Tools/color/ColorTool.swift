import Foundation

public enum ColorTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "color", "颜色转换", .css, "sRGB HEX / RGB / HSL 与透明度，结果点一下复制。", sample: "#3478f6", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let c = try ColorValue.parse(input.text)
    let rows = [ResultRow("HEX", c.hexValue), ResultRow("RGB", c.css), ResultRow("HSL", c.hsl)]
    return ToolOutput(
      rows.map(\.value).joined(separator: "\n"), rows: rows,
      html: cssPreview("background: \(c.css);border-radius:24px;", content: htmlEscape(c.hexValue)),
      note: "色彩空间：sRGB")
  }
}
