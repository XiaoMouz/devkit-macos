import Foundation

public enum ImageResizeTool: ToolModule {
  public struct Options: ToolOptions {
    public var width: Int = 800
    public var height: Int = 600
    public var mode: String = "scale"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-resize", "图片尺寸", .assets, "缩放或居中裁剪到目标尺寸；PNG 导出。", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("width", "宽 px", \.width, range: 1...10000),
      .init("height", "高 px", \.height, range: 1...10000),
      .init("mode", "方式", \.mode, choices: ["scale", "fit", "fill"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...10000).contains(options.width) && (1...10000).contains(options.height), "宽高范围为 1–10000。")
    try require(["scale", "fit", "fill"].contains(options.mode), "缩放方式无效。")
    let image = try ImageCodec.decode(input)
    let ratio = min(Double(options.width) / Double(image.width), Double(options.height) / Double(image.height))
    let width = options.mode == "scale" ? max(1, Int((Double(image.width) * ratio).rounded())) : options.width
    let height = options.mode == "scale" ? max(1, Int((Double(image.height) * ratio).rounded())) : options.height
    let resized = try ImageCodec.resize(
      image, width: width, height: height, fill: options.mode == "fill")
    return ToolOutput(
      "\(image.width) × \(image.height) → \(resized.width) × \(resized.height)",
      artifacts: [try ImageCodec.encode(resized)],
      note: options.mode == "scale" ? "保持原图比例，尺寸不超过设定宽高。" : options.mode == "fill" ? "居中裁剪到目标宽高。" : "保持比例放入目标画布，空白区域透明。")
  }
}
