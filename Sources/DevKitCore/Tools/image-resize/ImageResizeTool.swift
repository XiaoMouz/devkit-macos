import Foundation

public enum ImageResizeTool: ToolModule {
  public struct Options: ToolOptions {
    public var width: Int = 800
    public var height: Int = 600
    public var mode: String = "scale"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-resize", "Image Dimensions", .assets, "Scale or center-crop to target dimensions and export as PNG.", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("width", L10n.tr("Width in Pixels"), \.width, range: 1...10000),
      .init("height", L10n.tr("Height in Pixels"), \.height, range: 1...10000),
      .init("mode", L10n.tr("Resize Mode"), \.mode, choices: ["scale", "fit", "fill"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...10000).contains(options.width) && (1...10000).contains(options.height), L10n.tr("Width and height must be between 1 and 10,000."))
    try require(["scale", "fit", "fill"].contains(options.mode), L10n.tr("Invalid scaling mode."))
    let image = try ImageCodec.decode(input)
    let ratio = min(Double(options.width) / Double(image.width), Double(options.height) / Double(image.height))
    let width = options.mode == "scale" ? max(1, Int((Double(image.width) * ratio).rounded())) : options.width
    let height = options.mode == "scale" ? max(1, Int((Double(image.height) * ratio).rounded())) : options.height
    let resized = try ImageCodec.resize(
      image, width: width, height: height, fill: options.mode == "fill")
    return ToolOutput(
      "\(image.width) × \(image.height) → \(resized.width) × \(resized.height)",
      artifacts: [try ImageCodec.encode(resized)],
      note: options.mode == "scale" ? L10n.tr("Preserve the image’s aspect ratio within the specified dimensions.") : options.mode == "fill" ? L10n.tr("Center-crop to the target dimensions.") : L10n.tr("Fit proportionally on the target canvas, with transparent empty areas."))
  }
}
