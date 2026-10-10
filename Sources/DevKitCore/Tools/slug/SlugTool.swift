import Foundation

public enum SlugTool: ToolModule {
  public struct Options: ToolOptions {
    public var ascii: Bool = false
    public var separator: String = "-"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "slug", "Slug", .text, "Unicode / ASCII 策略，折叠分隔符并移除首尾连接符。", sample: "Hello 世界 / Café Déjà Vu",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("ascii", "仅 ASCII（拉丁转写）", \.ascii),
      .init("separator", "连接符", \.separator, choices: ["-", "_"]),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    var value = input.text
    if options.ascii {
      value =
        value.applyingTransform(.toLatin, reverse: false)?.applyingTransform(
          .stripCombiningMarks, reverse: false) ?? value
    }
    value = value.lowercased()
    let words = value.components(
      separatedBy: options.ascii
        ? CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").inverted
        : CharacterSet.alphanumerics.inverted
    ).filter { !$0.isEmpty }
    return ToolOutput(words.joined(separator: options.separator))
  }
}
