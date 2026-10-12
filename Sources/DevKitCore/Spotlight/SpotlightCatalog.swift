import Foundation

public struct SpotlightAction: Sendable, Identifiable {
  public let id: String
  public let toolID: String
  public let sourceName: String
  public var name: String { L10n.text(sourceName) + (operation.map { " · " + SpotlightCatalog.operationTitle($0) } ?? "") }
  public let operation: String?
  public let exampleInput: String
  public let request: @Sendable (String) throws -> WorkerRequest
  public var commandOperation: String? { operation.map { SpotlightCatalog.operationCommand($0) } }
  public func example(command: String) -> String {
    ([command] + [commandOperation].compactMap { $0 } + [exampleInput]).joined(separator: " ")
  }
}
public struct SpotlightTool: Sendable, Identifiable {
  public let id: String
  public let sourceName: String
  public var name: String { L10n.text(sourceName) }
  public let symbol: String
  public let generator: Bool
  public let actions: [SpotlightAction]
  public var operations: [String] { actions.compactMap(\.operation) }
  public var localizedOperations: [String] { actions.compactMap(\.commandOperation) }
  public func example(alias: String) -> String {
    actions[0].example(command: alias)
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
      var exampleOptions = T.Options()
      if let operation, let field { field.write(&exampleOptions, operation) }
      let example = T.inputStyle(for: exampleOptions) == .generator ? "3" : T.example(for: exampleOptions).text
      return SpotlightAction(id: T.metadata.id + ":" + (operation ?? "run"), toolID: T.metadata.id,
        sourceName: T.metadata.sourceName, operation: operation, exampleInput: example.isEmpty ? "--" : example,
        request: { payload in
          var options = T.Options()
          if let operation, let field { field.write(&options, operation) }
          let activeGenerator = T.inputStyle(for: options) == .generator
          if activeGenerator, !payload.isEmpty {
            guard let countField = T.fields.first(where: { $0.id == "count" }),
              case .integer(let range) = countField.kind, let count = Int(payload), range.contains(count)
            else { throw ToolFailure(L10n.tr("Generators only accept a count within the allowed range. Use the main app for other parameters.")) }
            countField.write(&options, String(count))
          }
          return WorkerRequest(id: T.metadata.id, input: ToolInput(text: activeGenerator ? "" : payload), options: try JSONEncoder().encode(options))
        })
    }
    return SpotlightTool(id: T.metadata.id, sourceName: T.metadata.sourceName, symbol: T.metadata.symbol,
      generator: generator, actions: actions)
  }
  // Canonical option values remain stable. Translations only name the commands.
  static let operationKeys = [
    "encode": "Encode", "decode": "Decode", "format": "Format", "minify": "Minify", "validate": "Validate",
    "tree": "Path List", "typescript": "Generate Types", "parse": "Parse", "generate": "Generate",
    "seconds": "Seconds", "milliseconds": "Milliseconds",
    "plain": "Round Half Up", "bankers": "Banker’s Rounding", "down": "Round Toward Negative Infinity", "up": "Round Toward Positive Infinity",
    "deduplicate": "Remove Duplicates", "sort": "Sort", "reverse-sort": "Sort Descending",
    "remove-empty": "Remove Empty Lines", "number": "Add Line Numbers", "affix": "Add Prefix and Suffix",
  ].merging(TextCaseTool.modeTitleKeys) { _, modeTitle in modeTitle }
  fileprivate static func operationTitle(_ operation: String, language: String? = nil) -> String {
    operationKeys[operation].map { L10n.text($0, language: language) } ?? operation
  }
  public static func operationCommand(_ operation: String, language: String? = nil) -> String {
    let language = language ?? L10n.language
    return language == "en" ? operation : operationTitle(operation, language: language)
  }
}

public enum SpotlightCommand {
  /// A dedicated action already knows its tool. Spotlight can supply only the
  /// argument after its Quick Key, while manual input may include the full command.
  public static func parse(_ command: String, toolID: String, preferences: SpotlightPreferences) throws -> WorkerRequest {
    try require(command.utf8.count <= 16 * 1024, L10n.tr("Spotlight input is limited to 16 KiB. Use the main app instead."))
    let (first, _) = token(command.drop(while: { $0.isWhitespace }))
    let hasToolPrefix = first.lowercased() == toolID
      || preferences.aliases(for: toolID).contains(first.lowercased())
    let request = try parse(hasToolPrefix ? command : toolID + " " + command, preferences: preferences)
    try require(request.id == toolID, L10n.tr("This action can only run \(toolID)."))
    return request
  }
  public static func parse(_ command: String, preferences: SpotlightPreferences) throws -> WorkerRequest {
    try require(command.utf8.count <= 16 * 1024, L10n.tr("Spotlight input is limited to 16 KiB. Use the main app instead."))
    try require(preferences.enabled, L10n.tr("Spotlight is disabled. Enable it in DevKit settings."))
    let (alias, remainder) = token(command.drop(while: { $0.isWhitespace }))
    guard let tool = SpotlightCatalog.tools.first(where: { $0.id == alias.lowercased() || preferences.aliases(for: $0.id).contains(alias.lowercased()) })
    else { throw ToolFailure(L10n.tr("Unknown tool command \(alias). See command examples in DevKit → Settings → Spotlight.")) }
    try require(preferences.allows(tool.id), L10n.tr("Spotlight actions for \(tool.name) are disabled."))
    var payload = remainder
    let action: SpotlightAction
    if !tool.operations.isEmpty {
      let (operation, rest) = token(remainder[...])
      let canonical = ["enc":"encode", "dec":"decode", "fmt":"format", "min":"minify"][operation.lowercased()] ?? operation
      if let selected = tool.actions.first(where: { $0.operation?.lowercased() == canonical.lowercased() }) {
        action = selected; payload = rest
      } else if let match = localizedAction(in: remainder, tool: tool) {
        action = match.action; payload = match.payload
      } else {
        throw ToolFailure(L10n.tr("\(tool.name) supports: \(tool.localizedOperations.joined(separator: ", ")). Example: \(tool.example(alias: alias))"))
      }
    } else { action = tool.actions[0] }
    if payload == "--" { payload = "" }
    else if payload.hasPrefix("-- ") { payload = String(payload.dropFirst(3)) }
    else { try require(tool.generator || !payload.isEmpty, L10n.tr("Missing input text. For empty text, explicitly use --.")) }
    return try action.request(payload)
  }
  private static func localizedAction(in value: String, tool: SpotlightTool) -> (action: SpotlightAction, payload: String)? {
    // Accept every shipped language so system-cached Spotlight labels still work
    // after an app language change. Match phrases, including spaces, at a boundary.
    var matches: [(action: SpotlightAction, end: String.Index)] = []
    for action in tool.actions {
      guard let operation = action.operation else { continue }
      let names = Set(L10n.languages.map { SpotlightCatalog.operationTitle(operation, language: $0.id) })
      for name in names {
        guard let range = value.range(of: name, options: [.anchored, .caseInsensitive]),
          range.upperBound == value.endIndex || value[range.upperBound] == " " || value[range.upperBound] == "\t"
        else { continue }
        matches.append((action, range.upperBound))
      }
    }
    guard let end = matches.map(\.end).max() else { return nil }
    let longest = matches.filter { $0.end == end }
    // Conflicting translations must not silently choose a different operation.
    guard Set(longest.map { $0.action.id }).count == 1, let match = longest.first else { return nil }
    return (match.action, end == value.endIndex ? "" : String(value[value.index(after: end)...]))
  }
  private static func token(_ value: Substring) -> (String, String) {
    guard let split = value.firstIndex(where: { $0 == " " || $0 == "\t" }) else { return (String(value), "") }
    return (String(value[..<split]), String(value[value.index(after: split)...]))
  }
}
