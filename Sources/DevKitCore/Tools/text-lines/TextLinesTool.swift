import Foundation

public enum TextLinesTool: ToolModule {
  public struct Options: ToolOptions {
    public var mode: String = "deduplicate"
    public var prefix: String = ""
    public var suffix: String = ""
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "text-lines", "文本行处理", .text, "排序、去重、去空行、编号和添加前后缀。", sample: "banana\napple\nbanana\n\ncherry",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "mode", "操作", \.mode,
        choices: ["deduplicate", "sort", "reverse-sort", "remove-empty", "number", "affix"]),
      .init("prefix", "前缀", \.prefix),
      .init("suffix", "后缀", \.suffix),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.mode == "affix" || !["prefix", "suffix"].contains(field.id) }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    var lines = input.text.components(separatedBy: "\n")
    switch options.mode {
    case "sort": lines.sort()
    case "reverse-sort": lines.sort(by: >)
    case "remove-empty":
      lines.removeAll { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    case "number": lines = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }
    case "affix": lines = lines.map { options.prefix + $0 + options.suffix }
    default:
      var seen = Set<String>()
      lines = lines.filter { seen.insert($0).inserted }
    }
    return ToolOutput(lines.joined(separator: "\n"))
  }
}
