import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum DataUrlTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "data-url", "Data URL", .encoding, "Convert between images and Data URLs.", input: .file)
  public static var fields: [OptionField<Options>] {
    [.init("operation", L10n.tr("Operation"), \.operation, choices: ["encode", "decode"])]
  }
  public static func inputStyle(for options: Options) -> InputStyle {
    options.operation == "decode" ? .text : .file
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    switch options.operation {
    case "encode":
      guard let data = input.file else { throw ToolFailure(L10n.tr("Choose an image.")) }
      let type = try imageType(data)
      let text = "data:\(type.mime);base64," + data.base64EncodedString()
      try require(text.utf8.count <= Limits.textBytes, L10n.tr("The encoded image exceeds 5 MiB. Choose a smaller image."))
      return ToolOutput(text)
    case "decode":
      let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard text.lowercased().hasPrefix("data:"), let comma = text.firstIndex(of: ",") else {
        throw ToolFailure(L10n.tr("Enter a complete image Data URL."))
      }
      let header = text[text.index(text.startIndex, offsetBy: 5)..<comma]
        .split(separator: ";", omittingEmptySubsequences: false).map { $0.lowercased() }
      guard let mime = header.first, mime.hasPrefix("image/") else {
        throw ToolFailure(L10n.tr("The Data URL must have an image type."))
      }
      let payload = String(text[text.index(after: comma)...])
      let bytes = try percentDecodedBytes(payload)
      let data: Data
      if header.last == "base64" {
        guard let base64 = String(data: bytes, encoding: .ascii) else {
          throw ToolFailure(L10n.tr("Invalid Base64 content."))
        }
        data = try Base64Codec.decode(base64)
      } else {
        data = bytes
      }
      let type = try imageType(data)
      let declaredType = UTType(mimeType: mime == "image/jpg" ? "image/jpeg" : mime)
      try require(declaredType == type.type, L10n.tr("The image type declared in the Data URL does not match its actual content."))
      let artifact = Artifact("image.\(type.extensionName)", type.mime, data)
      return ToolOutput(artifact.name, artifacts: [artifact])
    default:
      throw ToolFailure(L10n.tr("Unsupported Data URL operation."))
    }
  }

  private static func imageType(_ data: Data) throws -> (type: UTType, mime: String, extensionName: String) {
    let source = try ImageCodec.source(ToolInput(file: data))
    guard let identifier = CGImageSourceGetType(source) as String?,
      let type = UTType(identifier), type.conforms(to: .image),
      let mime = type.preferredMIMEType, mime.hasPrefix("image/"),
      let extensionName = type.preferredFilenameExtension,
      CGImageSourceCreateImageAtIndex(source, 0, nil) != nil,
      CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
    else { throw ToolFailure(L10n.tr("Invalid image or unsupported format.")) }
    return (type, mime, type == .jpeg ? "jpg" : extensionName)
  }

  private static func percentDecodedBytes(_ payload: String) throws -> Data {
    var bytes = [UInt8]()
    let raw = Array(payload.utf8)
    var index = 0
    while index < raw.count {
      if raw[index] == 37 {
        try require(index + 2 < raw.count, L10n.tr("Incomplete percent encoding."))
        try require(raw[(index + 1)...(index + 2)].allSatisfy {
          (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
        }, L10n.tr("Invalid percent encoding."))
        guard let byte = UInt8(String(decoding: raw[(index + 1)...(index + 2)], as: UTF8.self), radix: 16)
        else { throw ToolFailure(L10n.tr("Invalid percent encoding.")) }
        bytes.append(byte)
        index += 3
      } else {
        bytes.append(raw[index])
        index += 1
      }
    }
    return Data(bytes)
  }
}
