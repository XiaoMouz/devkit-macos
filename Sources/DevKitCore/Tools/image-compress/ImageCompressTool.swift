import Foundation

public enum ImageCompressTool: ToolModule {
  public struct Options: ToolOptions {
    public var quality: Int = 85
    public var targetKB: Int = 0
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-compress", "Image Compression", .assets, "JPEG lossy quality and target size, without overwriting the original.", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("quality", L10n.tr("Maximum Quality %"), \.quality, range: 10...100),
      .init("targetKB", L10n.tr("Target KB (0 for unlimited)"), \.targetKB, range: 0...32000),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (10...100).contains(options.quality) && (0...32000).contains(options.targetKB), L10n.tr("Compression parameters are out of range."))
    let image = try ImageCodec.decode(input)
    var file = try ImageCodec.encode(image, format: "jpeg", quality: Double(options.quality) / 100)
    if options.targetKB > 0 && file.data.count > options.targetKB * 1000 {
      var low = 0.05
      var high = Double(options.quality) / 100
      var smallest = try ImageCodec.encode(image, format: "jpeg", quality: low)
      for _ in 0..<8 {
        let q = (low + high) / 2
        let candidate = try ImageCodec.encode(image, format: "jpeg", quality: q)
        if candidate.data.count <= options.targetKB * 1000 {
          low = q
          smallest = candidate
        } else {
          high = q
        }
      }
      file = smallest
    }
    let reached = options.targetKB == 0 || file.data.count <= options.targetKB * 1000
    let originalBytes = input.file?.count ?? 0
    let larger = file.data.count > originalBytes
    let warning = !reached || larger
    let sizeNote = larger ? L10n.tr("The result is larger than the original. Keep the original or choose another format.") : ""
    return ToolOutput(
      L10n.tr("Original \(input.file?.count ?? 0) bytes → \(file.data.count) bytes"), artifacts: [file],
      note: L10n.tr("Lossy JPEG encoding. Transparency is composited on white."),

      report: ResultReport(warning ? "warning" : "success",
        !reached ? L10n.tr("Target Size Not Reached") : larger ? L10n.tr("File Size Increased") : L10n.tr("Compression Complete"),
        sizeNote + (reached ? L10n.tr("The original file will not be modified.") : L10n.tr("Reduce the dimensions or adjust the target size.")),
        metrics: [ResultRow(L10n.tr("Original File"), L10n.tr("Bytes: \(originalBytes)")), ResultRow(L10n.tr("Output JPEG"), L10n.tr("Bytes: \(file.data.count)")),
          ResultRow(L10n.tr("Size Change"), String(format: "%+.1f%%", originalBytes > 0 ? (Double(file.data.count) / Double(originalBytes) - 1) * 100 : 0))]))
  }
}
