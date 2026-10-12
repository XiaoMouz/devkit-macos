import Foundation

public enum Base64Tool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var urlSafe: Bool = false
    public var padding: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "base64", "Base64", .encoding, "Encode and decode UTF-8 text with standard or URL-safe Base64; export text results.", sample: "hello", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", L10n.tr("Operation"), \.operation, choices: ["encode", "decode"]),
      .init("urlSafe", "URL Safe", \.urlSafe),
      .init("padding", L10n.tr("Keep Encoding Padding"), \.padding),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.operation == "encode" || field.id != "padding" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(input.file == nil, L10n.tr("Import UTF-8 text. The Base64 tool only processes text."))
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
      throw ToolFailure(L10n.tr("The decoded result is not UTF-8 text. The Base64 tool only encodes and decodes text."))
    }
    return ToolOutput(text)
  }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: options.operation == "decode" ? "aGVsbG8=" : "hello")
  }
}
