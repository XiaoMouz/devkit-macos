import Foundation

public enum TextReplaceTool: ToolModule {
  public struct Options: ToolOptions {
    public var search: String = "hello"
    public var replacement: String = "Hello"
    public var regex: Bool = false
    public var flags: String = "g"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "text-replace", "Find and Replace", .text, "Plain text or ECMAScript regex, preserving the original and previewing the result.",
    sample: "hello world\nhello DevKit", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("search", L10n.tr("Find"), \.search),
      .init("replacement", L10n.tr("Replace"), \.replacement),
      .init("regex", L10n.tr("Regex Mode"), \.regex),
      .init("flags", L10n.tr("Regex Flags"), \.flags),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.regex || field.id != "flags" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("text-replace", input: input, options: options)
  }
}
