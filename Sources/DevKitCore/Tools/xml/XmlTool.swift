import Foundation

public enum XmlTool: ToolModule {
  public struct Options: ToolOptions {
    public var operation: String = "format"
    public var path: String = "//tool"
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "xml", "XML", .structured, "XML 格式化、校验与 XPath 1.0；拒绝 DTD 和外部实体。",
    sample: "<tools><tool id=\"base64\">Base64</tool><tool id=\"json\">JSON</tool></tools>",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("operation", "操作", \.operation, choices: ["format", "minify", "validate", "xpath"]),
      .init("path", "XPath", \.path),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    try require(
      input.text.range(of: "<!DOCTYPE|<!ENTITY", options: [.regularExpression, .caseInsensitive])
        == nil, "此工具禁用 DTD 与实体声明。")
    let document: XMLDocument
    do {
      document = try XMLDocument(
        xmlString: input.text, options: [.nodeLoadExternalEntitiesNever, .nodePreserveWhitespace])
    } catch { throw ToolFailure("XML 无效：\(error.localizedDescription)") }
    if options.operation == "validate" { return ToolOutput("XML 格式有效") }
    if options.operation == "xpath" {
      let nodes = try document.nodes(forXPath: options.path)
      try require(nodes.count <= 10000, "匹配节点超过 10000。")
      return ToolOutput(
        nodes.map(\.xmlString).joined(separator: "\n"),
        rows: nodes.enumerated().map { ResultRow(String($0.offset + 1), $0.element.xmlString) })
    }
    return ToolOutput(
      document.xmlString(options: options.operation == "format" ? [.nodePrettyPrint] : []),
      note: "保留文本空白，不在混合内容中擅自删空格。")
  }
}
