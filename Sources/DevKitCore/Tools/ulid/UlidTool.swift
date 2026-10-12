import Foundation

public enum UlidTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "generate"
    public var count: Int = 5
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "ulid", "ULID", .generators, "Crockford Base32 with a 48-bit millisecond timestamp and 80 secure random bits.", sample: "",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", L10n.tr("Operation"), \.operation, choices: ["generate", "parse"]),
      .init("count", L10n.tr("Count"), \.count, range: 1...1000),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.operation != "parse" || field.id == "operation" }
  }
  public static func inputStyle(for options: Options) -> InputStyle { options.operation == "generate" ? .generator : .text }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    if options.operation == "parse" {
      let chars = Array(input.text.uppercased())
      try require(
        chars.count == 26 && chars.allSatisfy { alphabet.contains($0) },
        L10n.tr("ULID must contain 26 Crockford Base32 characters."))
      var time: UInt64 = 0
      for c in chars.prefix(10) { time = time * 32 + UInt64(alphabet.firstIndex(of: c)!) }
      try require(time < (1 << 48), L10n.tr("ULID exceeds the 128-bit range."))
      return ToolOutput(Dates.display(Date(timeIntervalSince1970: Double(time) / 1000), milliseconds: true), note: L10n.tr("Time zone: ") + Dates.zoneLabel(.current, at: Date(timeIntervalSince1970: Double(time) / 1000)))
    }
    try require((1...1000).contains(options.count), L10n.tr("Count must be between 1 and 1,000."))
    let values = try (0..<options.count).map { _ -> String in
      var time = UInt64(Date().timeIntervalSince1970 * 1000)
      var prefix = [Character](repeating: "0", count: 10)
      for j in (0..<10).reversed() {
        prefix[j] = alphabet[Int(time & 31)]
        time >>= 5
      }
      let bits = try randomBytes(10).flatMap { byte in
        (0..<8).reversed().map { Int((byte >> $0) & 1) }
      }
      let tail = stride(from: 0, to: 80, by: 5).map { j -> Character in
        alphabet[bits[j..<j + 5].reduce(0) { ($0 << 1) | $1 }]
      }
      return String(prefix + tail)
    }
    return ToolOutput(
      values.joined(separator: "\n"),
      rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) },
      note: L10n.tr("Independent random values within the same millisecond; monotonic ordering is not guaranteed."))
  }
}
