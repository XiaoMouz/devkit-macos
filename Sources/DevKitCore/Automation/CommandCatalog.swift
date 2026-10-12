import Foundation
import CoreFoundation

/// Machine-readable discovery stays tied to the same options and registry as the UI.
public enum CommandCatalog {
  public static let protocolVersion = 1

  public static func list() -> [[String: Any]] {
    ToolRegistry.all.map { summary($0) }
  }

  public static func describe(_ id: String, options: [String: Any] = [:]) throws -> [String: Any] {
    guard let tool = ToolRegistry.find(id) else { throw unknownTool() }
    return try describe(tool, values: options)
  }

  public static func request(_ id: String, input: ToolInput, options: [String: Any]) throws -> WorkerRequest {
    guard let tool = ToolRegistry.find(id) else { throw unknownTool() }
    try Limits.check(input)
    return try request(tool, input: input, values: options)
  }

  /// `--option` values use the declared option type, never JSON guessing for text fields.
  public static func option(_ value: String, id: String, key: String) throws -> Any {
    let description = try describe(id)
    let fields = description["options"] as? [[String: Any]] ?? []
    guard let field = fields.first(where: { $0["id"] as? String == key }) else {
      throw ToolFailure(L10n.tr("Unknown option: \(key)"), code: "usage")
    }
    switch field["type"] as? String {
    case "boolean":
      guard ["true", "false"].contains(value) else { throw invalidOption(key) }
      return value == "true"
    case "integer":
      guard let number = Int(value) else { throw invalidOption(key) }
      return number
    default: return value
    }
  }

  private static func summary(_ tool: any ToolModule.Type) -> [String: Any] {
    let metadata = tool.metadata
    return ["id": metadata.id, "name": metadata.name, "summary": metadata.summary,
      "category": metadata.category.rawValue, "network": metadata.network]
  }

  private static func describe<T: ToolModule>(_ tool: T.Type, values: [String: Any]) throws -> [String: Any] {
    let options = try resolve(tool, values: values)
    let encoded = try JSONEncoder().encode(options)
    let defaults = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] ?? [:]
    let visible = Set(T.visibleFields(for: options).map(\.id))
    var result = summary(tool)
    result["inputStyle"] = T.inputStyle(for: options).rawValue
    result["defaults"] = defaults
    result["options"] = T.fields.map { field -> [String: Any] in
      var item: [String: Any] = ["id": field.id, "label": field.label,
        "default": defaults[field.id] ?? NSNull(), "visible": visible.contains(field.id)]
      switch field.kind {
      case .text, .decimal: item["type"] = "string"
      case .secret: item["type"] = "string"; item["secret"] = true
      case .choice(let choices): item["type"] = "string"; item["enum"] = choices
      case .integer(let range):
        item["type"] = "integer"; item["minimum"] = range.lowerBound; item["maximum"] = range.upperBound
      case .toggle: item["type"] = "boolean"
      }
      return item
    }
    result["exampleInput"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(T.example(for: options)))
    result["limits"] = ["textBytes": Limits.textBytes, "fileBytes": Limits.fileBytes,
      "outputBytes": Limits.outputBytes, "workerSeconds": 25]
    return result
  }

  private static func request<T: ToolModule>(_ tool: T.Type, input: ToolInput,
    values: [String: Any]) throws -> WorkerRequest {
    WorkerRequest(id: T.metadata.id, input: input,
      options: try JSONEncoder().encode(resolve(tool, values: values)))
  }

  private static func resolve<T: ToolModule>(_ tool: T.Type, values: [String: Any]) throws -> T.Options {
    let known = Set(T.fields.map(\.id))
    if let unknown = values.keys.sorted().first(where: { !known.contains($0) }) {
      throw ToolFailure(L10n.tr("Unknown option: \(unknown)"), code: "usage")
    }
    var options = T.Options()
    // Definition order preserves option dependencies (e.g. JSON syntax resets its default path).
    for field in T.fields {
      guard let value = values[field.id] else { continue }
      let text: String
      switch field.kind {
      case .text, .secret, .decimal:
        guard let string = value as? String else { throw invalidOption(field.id) }
        text = string
      case .choice(let choices):
        guard let string = value as? String, choices.contains(string) else { throw invalidOption(field.id) }
        text = string
      case .toggle:
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
          throw invalidOption(field.id)
        }
        text = number.boolValue ? "true" : "false"
      case .integer(let range):
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
          let integer = Int(number.stringValue), range.contains(integer)
        else { throw invalidOption(field.id) }
        text = String(integer)
      }
      field.write(&options, text)
    }
    return options
  }

  private static func invalidOption(_ key: String) -> ToolFailure {
    ToolFailure(L10n.tr("Invalid type, value, or range for option \(key). See devkit describe."), code: "usage")
  }
  private static func unknownTool() -> ToolFailure {
    ToolFailure(L10n.tr("Tool not found. See devkit list."), code: "usage")
  }
}
