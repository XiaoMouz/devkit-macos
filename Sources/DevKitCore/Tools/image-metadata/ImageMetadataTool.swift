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
    let text = try prettyJSON(jsonValue(values))
    let artifacts =
      options.strip
      ? [try ImageCodec.encode(ImageCodec.decode(input), name: "metadata-removed")] : []
    let keys = [(kCGImagePropertyPixelWidth as String, "宽度（px）"), (kCGImagePropertyPixelHeight as String, "高度（px）"),
      (kCGImagePropertyColorModel as String, "颜色模型"), (kCGImagePropertyDepth as String, "位深度"),
      (kCGImagePropertyHasAlpha as String, "透明通道")]
    let rows = keys.compactMap { key, label in values[key].map { ResultRow(label, key == kCGImagePropertyHasAlpha as String ? (($0 as? NSNumber)?.boolValue == true ? "是" : "否") : String(describing: $0)) } }
    return ToolOutput(text, rows: rows, artifacts: artifacts, note: options.strip ? "已生成移除元数据的 PNG。" : nil)
  }
  private static func jsonValue(_ value: Any) -> Any {
    switch value {
    case let date as Date: return Dates.display(date)
    case let data as Data: return data.base64EncodedString()
    case let dictionary as [String: Any]: return dictionary.mapValues(jsonValue)
    case let array as [Any]: return array.map(jsonValue)
    case is String, is NSNumber, is NSNull: return value
    default: return String(describing: value)
    }
  }

}
