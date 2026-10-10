import Foundation

public enum DataUrlTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var mime: String = "text/plain"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "data-url", "Data URL", .encoding, "生成或解析 Data URL，支持文件与二进制导出。", sample: "hello", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"]),
      .init("mime", "MIME", \.mime),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    if options.operation == "encode" {
      try require(
        options.mime.range(of: "^[A-Za-z0-9.+-]+/[A-Za-z0-9.+-]+$", options: .regularExpression)
          != nil, "MIME 格式无效。")
      return ToolOutput("data:\(options.mime);base64," + input.bytes.base64EncodedString())
    }
    guard input.text.hasPrefix("data:"), let comma = input.text.firstIndex(of: ",") else {
      throw ToolFailure("Data URL 必须以 data: 开始并包含逗号。")
    }
    let header = String(input.text[input.text.index(input.text.startIndex, offsetBy: 5)..<comma])
    let payload = String(input.text[input.text.index(after: comma)...])
    let mime = header.split(separator: ";").first.map(String.init) ?? "text/plain"
    let data: Data
    if header.hasSuffix(";base64") {
      data = try Base64Codec.decode(payload)
    } else {
      var bytes = [UInt8]()
      let raw = Array(payload.utf8)
      var index = 0
      while index < raw.count {
        if raw[index] == 37 {
          try require(index + 2 < raw.count, "百分号编码不完整。")
          guard
            let byte = UInt8(
              String(decoding: raw[(index + 1)...(index + 2)], as: UTF8.self), radix: 16)
          else { throw ToolFailure("百分号编码无效。") }
          bytes.append(byte)
          index += 3
        } else {
          bytes.append(raw[index])
          index += 1
        }
      }
      data = Data(bytes)
    }
    return textOrArtifact(data, name: "payload.bin", mime: mime)
  }
}
