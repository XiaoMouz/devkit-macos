import Foundation

public enum ImageCompressTool: ToolModule {
  public struct Options: ToolOptions {
    public var quality: Int = 85
    public var targetKB: Int = 0
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "image-compress", "图片压缩", .assets, "JPEG 有损质量与目标大小；原文件不覆盖。", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("quality", "质量上限 %", \.quality, range: 10...100),
      .init("targetKB", "目标 KB（0 为不限）", \.targetKB, range: 0...32000),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (10...100).contains(options.quality) && (0...32000).contains(options.targetKB), "压缩参数超出范围。")
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
    let sizeNote = larger ? "结果比原文件更大，建议保留原文件或更换格式。" : ""
    return ToolOutput(
      "原文件 \(input.file?.count ?? 0) 字节 → \(file.data.count) 字节", artifacts: [file],
      note: "JPEG 有损编码；透明背景合成白色。",

      report: ResultReport(warning ? "warning" : "success",
        !reached ? "未达到目标大小" : larger ? "结果体积增大" : "压缩完成",
        sizeNote + (reached ? "原文件不会被修改。" : "请降低目标尺寸或调整目标大小。"),
        metrics: [ResultRow("原文件", "\(originalBytes) 字节"), ResultRow("输出 JPEG", "\(file.data.count) 字节"),
          ResultRow("体积变化", String(format: "%+.1f%%", originalBytes > 0 ? (Double(file.data.count) / Double(originalBytes) - 1) * 100 : 0))]))
  }
}
