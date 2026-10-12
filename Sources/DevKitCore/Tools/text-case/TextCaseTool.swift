import Foundation

public enum TextCaseTool: ToolModule {
  public struct Options: ToolOptions {
    public var mode: String = "camelCase"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "text-case", "Naming and Case", .text, "camelCase, PascalCase, snake_case, and kebab-case.",
    sample: "helloWorld HTTPServer", secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "mode", L10n.tr("Output Format"), \.mode,
        choices: ["camelCase", "PascalCase", "snake_case", "kebab-case", "UPPERCASE", "lowercase"])
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    if options.mode == "UPPERCASE" { return ToolOutput(input.text.uppercased()) }
    if options.mode == "lowercase" { return ToolOutput(input.text.lowercased()) }
    let spaced = input.text.replacingOccurrences(
      of: "([a-z0-9])([A-Z])", with: "$1 $2", options: .regularExpression
    ).replacingOccurrences(of: "([A-Z])([A-Z][a-z])", with: "$1 $2", options: .regularExpression)
    let words = spaced.components(separatedBy: CharacterSet.alphanumerics.inverted).filter {
      !$0.isEmpty
    }.map { $0.lowercased() }
    let capitalized = words.map { $0.prefix(1).uppercased() + $0.dropFirst() }
    switch options.mode {
    case "snake_case": return ToolOutput(words.joined(separator: "_"))
    case "kebab-case": return ToolOutput(words.joined(separator: "-"))
    case "PascalCase": return ToolOutput(capitalized.joined())
    default: return ToolOutput((words.first ?? "") + capitalized.dropFirst().joined())
    }
  }
}
