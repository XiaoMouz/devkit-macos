import Foundation

public enum ImageResizeTool: ToolModule {
  public struct Options: ToolOptions {
    public var width: Int = 800
    public var height: Int = 600
    public var mode: String = "fit"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-resize", "图片尺寸", .assets, "缩放或居中裁剪到目标尺寸；PNG 导出。", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("width", "宽 px", \.width, range: 1...10000),
      .init("height", "高 px", \.height, range: 1...10000),
      .init("mode", "方式", \.mode, choices: ["fit", "fill"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let image = try ImageCodec.decode(input)
    let resized = try ImageCodec.resize(
      image, width: options.width, height: options.height, fill: options.mode == "fill")
    return ToolOutput(
      "\(image.width) × \(image.height) → \(resized.width) × \(resized.height)",
      artifacts: [try ImageCodec.encode(resized)],
      note: options.mode == "fill" ? "保持比例填满，居中裁剪超出区域。" : "保持比例完整放入，空白区域透明。")
  }
}
