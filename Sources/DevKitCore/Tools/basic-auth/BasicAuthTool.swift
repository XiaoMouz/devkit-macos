import Foundation

public enum BasicAuthTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "encode"
    public var username: String = "developer"
    public var password: String = ""
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "basic-auth", "Basic Auth", .security, "生成或解析 Authorization；密码默认隐藏。", sample: "", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["encode", "decode"]),
      .init("username", "用户名", \.username),
      .init("password", "密码", \.password, secret: true),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    if options.operation == "encode" {
      try require(!options.username.contains(":"), "用户名不能包含冒号。")
      return ToolOutput(
        "Basic " + Data("\(options.username):\(options.password)".utf8).base64EncodedString())
    }
    let text = input.text.hasPrefix("Basic ") ? String(input.text.dropFirst(6)) : input.text
    let value = try utf8(Base64Codec.decode(text))
    guard value.contains(":") else { throw ToolFailure("解码结果缺少用户名与密码分隔符。") }
    return ToolOutput(value, note: "解析结果含明文密码；关闭标签后不会保留。")
  }
}
