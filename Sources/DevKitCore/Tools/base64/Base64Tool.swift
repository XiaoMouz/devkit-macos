import Foundation

public enum Base64Tool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var urlSafe: Bool = false
    public var padding: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "base64", "Base64", .encoding, "UTF-8 与二进制编码转换；标准 / URL Safe。", sample: "hello", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"]),
      .init("urlSafe", "URL Safe", \.urlSafe),
      .init("padding", "编码保留填充", \.padding),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.operation == "encode" || field.id != "padding" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    if options.operation == "encode" {
      var value = input.bytes.base64EncodedString()
      if options.urlSafe {
        value = value.replacingOccurrences(of: "+", with: "-").replacingOccurrences(
          of: "/", with: "_")
      }
      if !options.padding { value = value.replacingOccurrences(of: "=", with: "") }
      return ToolOutput(value)
    }
    return textOrArtifact(try Base64Codec.decode(input.text, urlSafe: options.urlSafe))
  }
}
