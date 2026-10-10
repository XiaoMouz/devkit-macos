import CoreGraphics
import CoreImage
import Foundation
import Vision

public enum QrCodeTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "generate"
    public var correction: String = "M"
    public var scale: Int = 10
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "qr-code", "二维码", .generators, "文本生成 QR，或选择图片识别；PNG 导出。", sample: "https://example.com",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["generate", "scan"]),
      .init("correction", "纠错级别", \.correction, choices: ["L", "M", "Q", "H"]),
      .init("scale", "像素倍率", \.scale, range: 2...30),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    if options.operation == "scan" {
      let image = try ImageCodec.decode(input)
      let request = VNDetectBarcodesRequest()
      request.symbologies = [.qr]
      try VNImageRequestHandler(cgImage: image).perform([request])
      let values = (request.results ?? []).compactMap(\.payloadStringValue)
      try require(!values.isEmpty, "图片中没有识别到文本二维码。")
      return ToolOutput(
        values.joined(separator: "\n"),
        rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
    }
    try require(
      input.text.utf8.count <= 2000 && (2...30).contains(options.scale), "文本最多 2000 字节，倍率 2–30。")
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { throw ToolFailure("QR 生成器不可用。") }
    filter.setValue(Data(input.text.utf8), forKey: "inputMessage")
    filter.setValue(options.correction, forKey: "inputCorrectionLevel")
    guard let raw = filter.outputImage else { throw ToolFailure("文本过长或二维码参数无效。") }
    let quiet = raw.extent.insetBy(dx: -4, dy: -4)
    let background = CIImage(color: CIColor.white).cropped(to: quiet)
    let image = raw.composited(over: background).transformed(
      by: CGAffineTransform(scaleX: CGFloat(options.scale), y: CGFloat(options.scale)))
    guard let cg = CIContext().createCGImage(image, from: image.extent) else {
      throw ToolFailure("无法生成二维码图片。")
    }
    let artifact = try ImageCodec.encode(cg, name: "qrcode")
    return ToolOutput(input.text, artifacts: [artifact], note: "包含四模块静区；导出 PNG 后请实际扫码验证。")
  }
}
