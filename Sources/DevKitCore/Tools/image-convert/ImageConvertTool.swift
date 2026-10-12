import Foundation

public enum ImageConvertTool: ToolModule {
  public struct Options: ToolOptions {
    public var format: String = "png"
    public var quality: Int = 85
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-convert", "Image Format Conversion", .assets, "Convert PNG, JPEG, and HEIC using system encoders. Uses the first frame and removes metadata by default.", sample: "",
    secondary: "", input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("format", L10n.tr("Output Format"), \.format, choices: ["png", "jpeg", "heic"]),
      .init("quality", L10n.tr("Lossy Quality %"), \.quality, range: 1...100),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.format != "png" || field.id != "quality" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...100).contains(options.quality), L10n.tr("Quality must be between 1 and 100."))
    let image = try ImageCodec.decode(input)
    let file = try ImageCodec.encode(
      image, format: options.format, quality: Double(options.quality) / 100)
    return ToolOutput(
      L10n.tr("\(image.width) × \(image.height) · \(file.data.count) bytes"), artifacts: [file],
      note: L10n.tr("Uses the first frame and applies orientation. JPEG transparency is composited on white. The original file is not modified."))
  }
}
