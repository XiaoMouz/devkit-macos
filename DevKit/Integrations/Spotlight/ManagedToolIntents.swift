import AppIntents
import CoreSpotlight
import DevKitCore
import UniformTypeIdentifiers

struct SpotlightToolAction: AppEntity, IndexedEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "工具操作")
  static let defaultQuery = SpotlightToolActionQuery()
  let id: String
  let name: String
  let toolID: String
  let aliases: [String]
  init(_ action: SpotlightAction, preferences: SpotlightPreferences) {
    id = action.id; name = action.name; toolID = action.toolID
    aliases = preferences.aliases(for: action.toolID)
  }
  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)", subtitle: "\(aliases.joined(separator: ", "))")
  }
  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = CSSearchableItemAttributeSet(contentType: .item)
    attributes.title = name
    attributes.contentDescription = "DevKit 工具操作"
    attributes.keywords = aliases + [toolID, "DevKit"]
    return attributes
  }
}
struct SpotlightToolActionQuery: EntityStringQuery {
  func suggestedEntities() async throws -> [SpotlightToolAction] { available() }
  func entities(for identifiers: [String]) async throws -> [SpotlightToolAction] {
    available().filter { identifiers.contains($0.id) }
  }
  func entities(matching string: String) async throws -> [SpotlightToolAction] {
    available().filter { ($0.name + " " + $0.toolID + " " + $0.aliases.joined(separator: " ")).localizedStandardContains(string) }
  }
  private func available() -> [SpotlightToolAction] {
    let preferences = SpotlightPreferences.load()
    return SpotlightCatalog.actions.filter { preferences.allows($0.toolID) }.map { SpotlightToolAction($0, preferences: preferences) }
  }
}
struct DevKitCommandIntent: AppIntent {
  static let title: LocalizedStringResource = "DevKit 命令"
  static let description = IntentDescription("使用已启用工具的命令别名，如 b64 encode hello。别名在 DevKit 设置中修改。")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "命令") var command: String
  static var parameterSummary: some ParameterSummary { Summary("DevKit 命令 \(\.$command)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let request = try SpotlightCommand.parse(command, preferences: .load())
    let value = try await SpotlightExecution.run(request)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: ToolRegistry.find(request.id)?.metadata.name ?? request.id))
  }
}
struct DevKitToolIntent: AppIntent {
  static let title: LocalizedStringResource = "DevKit 工具操作"
  static let description = IntentDescription("选择已启用的工具操作并输入文本；生成器可输入数量。")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "工具操作") var action: SpotlightToolAction
  @Parameter(title: "文本或数量", default: "") var text: String
  static var parameterSummary: some ParameterSummary { Summary("使用 \(\.$action) 处理 \(\.$text)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let preferences = SpotlightPreferences.load()
    try require(preferences.allows(action.toolID), "此工具的 Spotlight 操作已关闭，请在 DevKit 设置中启用。")
    guard let selected = SpotlightCatalog.actions.first(where: { $0.id == action.id && $0.toolID == action.toolID }) else { throw ToolFailure("工具操作已失效，请重新选择。") }
    let value = try await SpotlightExecution.run(try selected.request(text))
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: selected.name))
  }
}
