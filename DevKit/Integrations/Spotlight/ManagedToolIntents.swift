import AppIntents
import CoreSpotlight
import DevKitCore
import UniformTypeIdentifiers

struct SpotlightToolAction: AppEntity, IndexedEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tool Action")
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
    attributes.contentDescription = L10n.tr("DevKit Tool Action")
    attributes.keywords = aliases + [toolID, "DevKit"]
    return attributes
  }
}
struct SpotlightToolActionQuery: EntityStringQuery {
  func suggestedEntities() async throws -> [SpotlightToolAction] {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    return available()
  }
  func entities(for identifiers: [String]) async throws -> [SpotlightToolAction] {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    return available().filter { identifiers.contains($0.id) }
  }
  func entities(matching string: String) async throws -> [SpotlightToolAction] {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    return available().filter { ($0.name + " " + $0.toolID + " " + $0.aliases.joined(separator: " ")).localizedStandardContains(string) }
  }
  private func available() -> [SpotlightToolAction] {
    let preferences = SpotlightPreferences.load()
    return SpotlightCatalog.actions.filter { preferences.allows($0.toolID) }.map { SpotlightToolAction($0, preferences: preferences) }
  }
}
struct DevKitCommandIntent: AppIntent {
  static let title: LocalizedStringResource = "DevKit Command"
  static let description = IntentDescription("Enter a command for an enabled tool, such as base64 encode hello. See command examples in DevKit settings.")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Command") var command: String
  static var parameterSummary: some ParameterSummary { Summary("DevKit Command \(\.$command)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let request = try SpotlightCommand.parse(command, preferences: .load())
    let value = try await SpotlightExecution.run(request)
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: ToolRegistry.find(request.id)?.metadata.name ?? request.id))
  }
}
struct DevKitToolIntent: AppIntent {
  static let title: LocalizedStringResource = "DevKit Tool Action"
  static let description = IntentDescription("Choose an enabled tool action and enter text. For generators, enter a count.")
  static var supportedModes: IntentModes { .background }
  @Parameter(title: "Tool Action") var action: SpotlightToolAction
  @Parameter(title: "Text or Count", default: "") var text: String
  static var parameterSummary: some ParameterSummary { Summary("Process \(\.$text) with \(\.$action)") }
  func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetIntent {
    let activity = await BackgroundActivity.begin()
    defer { activity.finish() }
    let preferences = SpotlightPreferences.load()
    try require(preferences.allows(action.toolID), L10n.tr("This tool’s Spotlight action is disabled. Enable it in DevKit settings."))
    guard let selected = SpotlightCatalog.actions.first(where: { $0.id == action.id && $0.toolID == action.toolID }) else { throw ToolFailure(L10n.tr("This tool action is no longer available. Select it again.")) }
    let value = try await SpotlightExecution.run(try selected.request(text))
    return .result(value: value, snippetIntent: ResultSnippetIntent(text: value, tool: selected.name))
  }
}
