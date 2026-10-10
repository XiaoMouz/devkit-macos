import Foundation
import ImageIO

public enum ImageMetadataTool: ToolModule {
  public struct Options: ToolOptions {
    public var strip: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-metadata", "图片信息", .assets, "查看尺寸、EXIF 与色彩信息；可导出移除元数据的新 PNG。", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("strip", "导出移除元数据的 PNG", \.strip)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let source = try ImageCodec.source(input)
    let values = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
    let text =
      JSONSerialization.isValidJSONObject(values)
      ? try prettyJSON(values) : String(describing: values)
    let artifacts =
      options.strip
      ? [try ImageCodec.encode(ImageCodec.decode(input), name: "metadata-removed")] : []
    return ToolOutput(text, artifacts: artifacts, note: "元数据可能包含定位与设备信息；不会上传。清理导出重新编码首帧，保留必要的色彩信息。")
  }
}
