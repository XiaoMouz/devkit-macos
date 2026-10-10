import Foundation

public enum UrlCodecTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var mode: String = "component"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "url-codec", "URL 编解码", .encoding, "组件、完整 URL 和表单模式，明确处理空格与加号。", sample: "hello 世界 + &",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"]),
      .init("mode", "模式", \.mode, choices: ["component", "url", "form"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    if options.operation == "decode" {
      let value =
        options.mode == "form" ? input.text.replacingOccurrences(of: "+", with: " ") : input.text
      guard let decoded = value.removingPercentEncoding else {
        throw ToolFailure("百分号编码无效，或解码字节不是 UTF-8。")
      }
      return ToolOutput(decoded)
    }
    var allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    if options.mode == "form" {
      allowed.remove(charactersIn: "~")
      allowed.insert(charactersIn: "*")
    }
    if options.mode == "url" { allowed.formUnion(CharacterSet(charactersIn: ":/?#[]@!$&'()*+,;=")) }
    var value = input.text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    if options.mode == "form" { value = value.replacingOccurrences(of: "%20", with: "+") }
    return ToolOutput(value)
  }
  public static func example(for options: Options) -> ToolInput {
    if options.mode == "url" {
      return ToolInput(text: options.operation == "decode"
        ? "https://example.com/search?q=%E4%BD%A0%E5%A5%BD%20world#%E7%BB%93%E6%9E%9C"
        : "https://example.com/search?q=你好 world#结果")
    }
    return ToolInput(text: options.operation != "decode" ? metadata.sample : options.mode == "form"
      ? "hello+%E4%B8%96%E7%95%8C+%2B+%26" : "hello%20%E4%B8%96%E7%95%8C%20%2B%20%26")
  }
}
