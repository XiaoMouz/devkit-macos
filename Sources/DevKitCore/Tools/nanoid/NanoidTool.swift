import Foundation

public enum NanoidTool: ToolModule {
  public struct Options: ToolOptions {
    public var length: Int = 21
    public var count: Int = 5
    public var alphabet: String = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "nanoid", "Nano ID", .generators, "Secure randomness and unbiased sampling, with custom Unicode character sets.", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("length", L10n.tr("Length"), \.length, range: 1...4096),
      .init("count", L10n.tr("Count"), \.count, range: 1...1000),
      .init("alphabet", L10n.tr("Character Set"), \.alphabet),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (1...4096).contains(options.length) && (1...1000).contains(options.count)
        && options.length * options.count <= 100_000, L10n.tr("Length, count, or total characters exceed the limit."))
    let values = try (0..<options.count).map { _ in
      try randomText(length: options.length, alphabet: options.alphabet)
    }
    return ToolOutput(
      values.joined(separator: "\n"),
      rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
  }
}
