import Foundation

public enum ImageConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var format: String = "png"
    public var quality: Int = 85
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-convert", "图片格式转换", .assets, "系统编码器转换 PNG / JPEG / HEIC；首帧，默认移除元数据。", sample: "",
    secondary: "", input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("format", "格式", \.format, choices: ["png", "jpeg", "heic"]),
      .init("quality", "有损质量 %", \.quality, range: 1...100),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.format != "png" || field.id != "quality" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...100).contains(options.quality), "质量范围为 1–100。")
    let image = try ImageCodec.decode(input)
    let file = try ImageCodec.encode(
      image, format: options.format, quality: Double(options.quality) / 100)
    return ToolOutput(
      "\(image.width) × \(image.height) · \(file.data.count) 字节", artifacts: [file],
      note: "使用首帧并按方向标记旋转；JPEG 透明区域合成为白色，原文件不修改。")
  }
}
