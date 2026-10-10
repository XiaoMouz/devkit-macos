import Foundation

public struct SpotlightAction: Sendable, Identifiable {
  public let id: String
  public let toolID: String
  public let name: String
  public let operation: String?
  public let request: @Sendable (String) throws -> WorkerRequest
}
public struct SpotlightTool: Sendable, Identifiable {
  public let id: String
  public let name: String
  public let symbol: String
  public let generator: Bool
  public let actions: [SpotlightAction]
  public var operations: [String] { actions.compactMap(\.operation) }
  public func example(alias: String) -> String {
    let payload = generator ? "3" : "hello"
    return ([alias] + [operations.first].compactMap { $0 } + [payload]).joined(separator: " ")
  }
}

public enum SpotlightCatalog {
  public static let tools: [SpotlightTool] = [
    make(Base64Tool.self), make(UrlCodecTool.self), make(JsonTool.self), make(HashTool.self),
    make(UuidTool.self), make(RandomStringTool.self), make(TimestampTool.self), make(ColorTool.self),
    make(HttpStatusTool.self), make(JwtTool.self),
    make(MimeTypesTool.self), make(NanoidTool.self), make(NumberBaseTool.self), make(NumberFormatTool.self),
    make(TextCaseTool.self), make(TextLinesTool.self),
    make(TextStatsTool.self), make(UlidTool.self), make(UrlParserTool.self),
    make(CssUnitTool.self),
  ]
  public static var actions: [SpotlightAction] { tools.flatMap(\.actions) }
  public static func defaultAlias(for id: String) -> String {
    ["base64":"b64", "url-codec":"url", "random-string":"rand", "timestamp":"ts", "text-stats":"stats",
     "number-base":"base", "number-format":"num",
     "http-status":"http", "mime-types":"mime", "css-unit":"css", "text-case":"case",
     "text-lines":"lines", "url-parser":"urlparse"][id] ?? id
  }
  private static func make<T: ToolModule>(_ type: T.Type) -> SpotlightTool {
    let generator = T.inputStyle(for: .init()) == .generator
    let field = generator ? T.fields.first { $0.id == "operation" } : T.fields.first { if case .choice = $0.kind { return true }; return false }
    var operations: [String?] = [nil]
    if let field, case .choice(let choices) = field.kind { operations = choices.filter { T.metadata.id != "json" || !["query", "schema", "diff"].contains($0) }.map(Optional.some) }
    let actions = operations.map { operation in
      SpotlightAction(id: T.metadata.id + ":" + (operation ?? "run"), toolID: T.metadata.id,
        name: T.metadata.name + (operation.map { " · " + operationTitle($0) } ?? ""), operation: operation,
        request: { payload in
          var options = T.Options()
          if let operation, let field { field.write(&options, operation) }
          let activeGenerator = T.inputStyle(for: options) == .generator
          if activeGenerator, !payload.isEmpty {
            guard let countField = T.fields.first(where: { $0.id == "count" }),
              case .integer(let range) = countField.kind, let count = Int(payload), range.contains(count)
            else { throw ToolFailure("生成器只接受范围内的数量；其他参数请使用工具箱。") }
            countField.write(&options, String(count))
          }
          return WorkerRequest(id: T.metadata.id, input: ToolInput(text: activeGenerator ? "" : payload), options: try JSONEncoder().encode(options))
        })
    }
    return SpotlightTool(id: T.metadata.id, name: T.metadata.name, symbol: T.metadata.symbol,
      generator: generator, actions: actions)
  }
  private static func operationTitle(_ operation: String) -> String {
    ["encode":"编码", "decode":"解码", "format":"格式化", "minify":"压缩", "validate":"校验",
     "parse":"解析", "generate":"生成", "build":"构建", "unique":"去重", "sort":"排序"][operation] ?? operation
  }
}

public enum SpotlightCommand {
  /// A dedicated action already knows its tool. Spotlight can supply only the
  /// argument after its Quick Key, while manual input may include the full command.
  public static func parse(_ command: String, toolID: String, preferences: SpotlightPreferences) throws -> WorkerRequest {
    try require(command.utf8.count <= 16 * 1024, "Spotlight 输入上限为 16 KiB，请改用工具箱。")
    let (first, _) = token(command.drop(while: { $0.isWhitespace }))
    let hasToolPrefix = first.lowercased() == toolID
      || preferences.aliases(for: toolID).contains(first.lowercased())
    let request = try parse(hasToolPrefix ? command : toolID + " " + command, preferences: preferences)
    try require(request.id == toolID, "此动作只能执行 \(toolID)。")
    return request
  }
  public static func parse(_ command: String, preferences: SpotlightPreferences) throws -> WorkerRequest {
    try require(command.utf8.count <= 16 * 1024, "Spotlight 输入上限为 16 KiB，请改用工具箱。")
    try require(preferences.enabled, "Spotlight 已关闭，请在 DevKit 设置中启用。")
    let (alias, remainder) = token(command.drop(while: { $0.isWhitespace }))
    guard let tool = SpotlightCatalog.tools.first(where: { $0.id == alias.lowercased() || preferences.aliases(for: $0.id).contains(alias.lowercased()) })
    else { throw ToolFailure("未知工具命令 \(alias)。可在 DevKit → 设置 → Spotlight 查看命令别名。") }
    try require(preferences.allows(tool.id), "\(tool.name)的 Spotlight 操作已关闭。")
    var payload = remainder
    let action: SpotlightAction
    if !tool.operations.isEmpty {
      let (operation, rest) = token(remainder[...])
      let canonical = ["enc":"encode", "dec":"decode", "fmt":"format", "min":"minify"][operation.lowercased()] ?? operation
      guard let selected = tool.actions.first(where: { $0.operation?.lowercased() == canonical.lowercased() }) else {
        throw ToolFailure("\(tool.name)支持：\(tool.operations.joined(separator: ", "))。示例：\(tool.example(alias: alias))")
      }
      action = selected; payload = rest
    } else { action = tool.actions[0] }
    if payload == "--" { payload = "" }
    else if payload.hasPrefix("-- ") { payload = String(payload.dropFirst(3)) }
    else { try require(tool.generator || !payload.isEmpty, "缺少输入文本；空文本请明确使用 --。") }
    return try action.request(payload)
  }
  private static func token(_ value: Substring) -> (String, String) {
    guard let split = value.firstIndex(where: { $0 == " " || $0 == "\t" }) else { return (String(value), "") }
    return (String(value[..<split]), String(value[value.index(after: split)...]))
  }
}
