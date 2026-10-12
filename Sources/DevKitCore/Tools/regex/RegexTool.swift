import Foundation

public enum RegexTool: ToolModule {
  public struct Options: ToolOptions {
    public var pattern: String = "([\\w.-]+)@([\\w.-]+)"
    public var flags: String = "g"
    public var operation: String = "match"
    public var replacement: String = "$1@new.test"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "regex", "Regex Tester", .text, "ECMAScript regex, capture groups, and replacement previews in a cancellable worker process.",
    sample: "user@example.com\nhello@devkit.app", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("pattern", L10n.tr("Expression"), \.pattern),
      .init("flags", L10n.tr("Flags"), \.flags),
      .init("operation", L10n.tr("Operation"), \.operation, choices: ["match", "replace"]),
      .init("replacement", L10n.tr("Replacement Text"), \.replacement),
    ]
  }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] {
    fields.filter { field in options.operation == "replace" || field.id != "replacement" }
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("regex", input: input, options: options)
  }
}
