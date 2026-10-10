import Foundation

public enum HexTextTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "hex-text", "Hex 文本", .encoding, "UTF-8 文本与十六进制字节互转，支持二进制导出。", sample: "Hello 世界",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    options.operation == "encode"
      ? ToolOutput(hex(input.bytes)) : textOrArtifact(try unhex(input.text))
  }
}
