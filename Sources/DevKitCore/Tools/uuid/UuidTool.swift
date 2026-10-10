import Foundation

public enum UuidTool: ToolModule {
  public struct Options: ToolOptions {
    public var version: String = "v4"
    public var count: Int = 5
    public var uppercase: Bool = false
    public var hyphens: Bool = true
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "uuid", "UUID", .generators, "RFC 9562 UUID v4 / v7，支持批量与大小写。", sample: "", secondary: "",
    input: .generator, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("version", "版本", \.version, choices: ["v4", "v7"]),
      .init("count", "数量", \.count, range: 1...1000),
      .init("uppercase", "大写", \.uppercase),
      .init("hyphens", "保留连字符", \.hyphens),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require((1...1000).contains(options.count), "数量必须为 1–1000。")
    let values = try (0..<options.count).map { _ -> String in
      var bytes = try randomBytes(16)
      if options.version == "v7" {
        let ms = UInt64(Date().timeIntervalSince1970 * 1000)
        for i in 0..<6 { bytes[i] = UInt8(truncatingIfNeeded: ms >> (8 * (5 - i))) }
        bytes[6] = (bytes[6] & 0x0f) | 0x70
      } else {
        bytes[6] = (bytes[6] & 0x0f) | 0x40
      }
      bytes[8] = (bytes[8] & 0x3f) | 0x80
      let h = hex(bytes)
      let a = Array(h)
      var value =
        options.hyphens
        ? [
          String(a[0..<8]), String(a[8..<12]), String(a[12..<16]), String(a[16..<20]),
          String(a[20..<32]),
        ].joined(separator: "-") : h
      if options.uppercase { value = value.uppercased() }
      return value
    }
    return ToolOutput(
      values.joined(separator: "\n"),
      rows: values.enumerated().map { ResultRow(String($0.offset + 1), $0.element) },
      note: options.version == "v7" ? "v7 使用毫秒时间戳与安全随机位；不保证同毫秒内排序。" : "UUID v4 · 使用系统安全随机数生成。")
  }
}
