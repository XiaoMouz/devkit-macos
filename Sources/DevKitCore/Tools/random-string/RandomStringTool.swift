import Foundation

public enum RandomStringTool: ToolModule {
  public struct Options: ToolOptions {
    public var length: Int = 24
    public var count: Int = 5
    public var alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    public var excludeSimilar: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "random-string", "Random String", .generators, "Generate batches using the system’s secure random source and a custom character set.", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("length", L10n.tr("Length"), \.length, range: 1...4096),
      .init("count", L10n.tr("Count"), \.count, range: 1...1000),
      .init("alphabet", L10n.tr("Character Set"), \.alphabet),
      .init("excludeSimilar", L10n.tr("Exclude Ambiguous Characters"), \.excludeSimilar),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      (1...4096).contains(options.length) && (1...1000).contains(options.count)
        && options.length * options.count <= 100_000, L10n.tr("Length 1–4,096, count 1–1,000, and no more than 100,000 total characters."))
    let alphabet =
      options.excludeSimilar ? options.alphabet.filter { !"0O1lI".contains($0) } : options.alphabet
    let values = try (0..<options.count).map { _ in
      try randomText(length: options.length, alphabet: alphabet)
    }
    return ToolOutput(
      values.joined(separator: "\n"),
      rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) })
  }
}
