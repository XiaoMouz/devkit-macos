import Foundation

public enum Base64Tool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var urlSafe: Bool = false
    public var padding: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "base64", "Base64", .encoding, "UTF-8 文本编解码；标准 / URL Safe，支持文本导出。", sample: "hello", secondary: "",
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
    try require(input.file == nil, "请导入 UTF-8 文本。Base64 工具仅处理文本。")
    if options.operation == "encode" {
      var value = input.bytes.base64EncodedString()
      if options.urlSafe {
        value = value.replacingOccurrences(of: "+", with: "-").replacingOccurrences(
          of: "/", with: "_")
      }
      if !options.padding { value = value.replacingOccurrences(of: "=", with: "") }
      return ToolOutput(value)
    }
    let data = try Base64Codec.decode(input.text, urlSafe: options.urlSafe)
    guard let text = String(data: data, encoding: .utf8) else {
      throw ToolFailure("解码结果不是 UTF-8 文本。Base64 工具仅支持文本编解码。")
    }
    return ToolOutput(text)
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: options.operation == "decode" ? "aGVsbG8=" : "hello")
  }
}
