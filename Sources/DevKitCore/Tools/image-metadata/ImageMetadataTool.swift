import Foundation
import ImageIO

public enum ImageMetadataTool: ToolModule {
  public struct Options: ToolOptions {
    public var strip: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-metadata", "Image Information", .assets, "Inspect dimensions, EXIF, and color information. Export a new PNG with metadata removed.", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("strip", L10n.tr("Export PNG without Metadata"), \.strip)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let source = try ImageCodec.source(input)
    let values = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] ?? [:]
    let text = try prettyJSON(jsonValue(values))
    let artifacts =
      options.strip
      ? [try ImageCodec.encode(ImageCodec.decode(input), name: "metadata-removed")] : []
    let keys = [(kCGImagePropertyPixelWidth as String, L10n.tr("Width (px)")), (kCGImagePropertyPixelHeight as String, L10n.tr("Height (px)")),
      (kCGImagePropertyColorModel as String, L10n.tr("Color Model")), (kCGImagePropertyDepth as String, L10n.tr("Bit Depth")),
      (kCGImagePropertyHasAlpha as String, L10n.tr("Alpha Channel"))]
    let rows = keys.compactMap { key, label in values[key].map { ResultRow(label, key == kCGImagePropertyHasAlpha as String ? (($0 as? NSNumber)?.boolValue == true ? L10n.tr("Yes") : L10n.tr("No")) : String(describing: $0)) } }
    return ToolOutput(text, rows: rows, artifacts: artifacts, note: options.strip ? L10n.tr("Generated a PNG with metadata removed.") : nil)
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
