import Foundation

public enum NanoidTool: ToolModule {
  public struct Options: ToolOptions {
    public var length: Int = 21
    public var count: Int = 5
    public var alphabet: String = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "nanoid", "Nano ID", .generators, "安全随机与无偏采样，可自定义 Unicode 字符集。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("length", "长度", \.length, range: 1...4096),
      .init("count", "数量", \.count, range: 1...1000),
      .init("alphabet", "字符集", \.alphabet),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (1...4096).contains(options.length) && (1...1000).contains(options.count)
        && options.length * options.count <= 100_000, "长度、数量或总字符超过限制。")
    let values = try (0..<options.count).map { _ in
      try randomText(length: options.length, alphabet: options.alphabet)
    }
    return ToolOutput(
      values.joined(separator: "\n"),
      rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
  }
}
