import Foundation

public enum UlidTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "generate"
    public var count: Int = 5
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "ulid", "ULID", .generators, "Crockford Base32，48 位毫秒时间戳与 80 位安全随机数。", sample: "",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["generate", "parse"]),
      .init("count", "数量", \.count, range: 1...1000),
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
        "ULID 必须为 26 位 Crockford Base32。")
      var time: UInt64 = 0
      for c in chars.prefix(10) { time = time * 32 + UInt64(alphabet.firstIndex(of: c)!) }
      try require(time < (1 << 48), "ULID 超过 128 位范围。")
      return ToolOutput(Dates.iso(Date(timeIntervalSince1970: Double(time) / 1000)))
    }
    try require((1...1000).contains(options.count), "数量必须为 1–1000。")
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
      note: "同毫秒内使用独立随机值，不保证单调递增。")
  }
}
