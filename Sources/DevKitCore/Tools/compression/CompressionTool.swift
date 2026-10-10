import Foundation

public enum CompressionTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "compress"
    public var format: String = "gzip"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "compression", "压缩与解压", .encoding, "Gzip / Zlib / raw Deflate；文本输出 Base64，文件可导出。",
    sample: "hello hello hello", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["compress", "decompress"]),
      .init("format", "格式", \.format, choices: ["gzip", "zlib", "deflate"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let decoding = options.operation == "decompress"
    let data = decoding ? try (input.file ?? Base64Codec.decode(input.text)) : input.bytes
    let output = try ZlibCodec.process(data, decompress: decoding, format: options.format)
    if decoding { return textOrArtifact(output) }
    return ToolOutput(
      output.base64EncodedString(),
      artifacts: [
        Artifact(
          "compressed." + (options.format == "gzip" ? "gz" : "bin"), "application/octet-stream",
          output)
      ], note: "文本区显示压缩字节的 Base64；导出为原始压缩文件。")
  }
}
