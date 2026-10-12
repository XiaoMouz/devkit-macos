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
    "qr-code", "QR Code", .generators, "Generate QR codes from text or scan an image. Export as PNG.", sample: "https://example.com",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", L10n.tr("Operation"), \.operation, choices: ["generate", "scan"]),
      .init("correction", L10n.tr("Error Correction"), \.correction, choices: ["L", "M", "Q", "H"]),
      .init("scale", L10n.tr("Pixel Scale"), \.scale, range: 2...30),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.operation != "scan" || field.id == "operation" }
  }
  public static func inputStyle(for options: Options) -> InputStyle { options.operation == "scan" ? .file : .text }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(["generate", "scan"].contains(options.operation), L10n.tr("Invalid QR operation."))
    try require(["L", "M", "Q", "H"].contains(options.correction), L10n.tr("Invalid error correction level."))
    if options.operation == "scan" {
      let image = try ImageCodec.decode(input)
      let request = VNDetectBarcodesRequest()
      request.symbologies = [.qr]
      try VNImageRequestHandler(cgImage: image).perform([request])
      let values = (request.results ?? []).compactMap(\.payloadStringValue)
      try require(!values.isEmpty, L10n.tr("No text QR code was recognized in the image."))
      return ToolOutput(
        values.joined(separator: "\n"),
        rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
    }
    try require(
      !input.text.isEmpty && input.text.utf8.count <= 2000 && (2...30).contains(options.scale), L10n.tr("Enter content up to 2,000 bytes, with a scale from 2 to 30."))
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { throw ToolFailure(L10n.tr("The QR generator is unavailable.")) }
    filter.setValue(Data(input.text.utf8), forKey: "inputMessage")
    filter.setValue(options.correction, forKey: "inputCorrectionLevel")
    guard let raw = filter.outputImage else { throw ToolFailure(L10n.tr("Content exceeds the capacity at error correction level \(options.correction). Reduce the content or lower the correction level. 2,000 bytes is the tool’s overall limit.")) }
    let quiet = raw.extent.insetBy(dx: -4, dy: -4)
    let background = CIImage(color: CIColor.white).cropped(to: quiet)
    let image = raw.composited(over: background).transformed(
      by: CGAffineTransform(scaleX: CGFloat(options.scale), y: CGFloat(options.scale)))
    guard let cg = CIContext().createCGImage(image, from: image.extent) else {
      throw ToolFailure(L10n.tr("Could not generate the QR image."))
    }
    let artifact = try ImageCodec.encode(cg, name: "qrcode")
    return ToolOutput(input.text, artifacts: [artifact])
  }
}
