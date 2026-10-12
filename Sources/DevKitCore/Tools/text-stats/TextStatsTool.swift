import Foundation

public enum TextStatsTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "text-stats", "Text Statistics", .text, "Count graphemes, Unicode code points, UTF-16 units, and UTF-8 bytes separately.", sample: "Hello 世界 👩‍💻",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    // Count CRLF once, and accept the same line boundaries as the editor.
    var lineCount = input.text.isEmpty ? 0 : 1
    var previous: UInt32 = 0
    for scalar in input.text.unicodeScalars {
      let value = scalar.value
      switch value {
      case 10: if previous != 13 { lineCount += 1 }
      case 13, 0x85, 0x2028, 0x2029: lineCount += 1
      default: break
      }
      previous = value
    }
    let rows = [
      ResultRow(L10n.tr("Graphemes"), String(input.text.count)),
      ResultRow(L10n.tr("Unicode Code Points"), String(input.text.unicodeScalars.count)),
      ResultRow(L10n.tr("UTF-16 Units"), String(input.text.utf16.count)),
      ResultRow(L10n.tr("UTF-8 Bytes"), String(input.text.utf8.count)),
      ResultRow(
        L10n.tr("Lines"), String(lineCount)),
      ResultRow(L10n.tr("Words (Whitespace-Separated)"), String(input.text.split(whereSeparator: { $0.isWhitespace }).count)),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
