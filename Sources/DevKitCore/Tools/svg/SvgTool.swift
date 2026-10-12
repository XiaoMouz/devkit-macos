import Foundation

public enum SvgTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "svg", "SVG Workspace", .assets, "Remove scripts and external references, optimize SVG, and preview it in a restricted view.",
    sample:
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"240\" height=\"160\"><rect width=\"240\" height=\"160\" rx=\"28\" fill=\"#3478f6\"/><circle cx=\"120\" cy=\"80\" r=\"42\" fill=\"white\"/></svg>",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    return try ScriptEngine.execute("svg", input: input, options: options)
  }
}
