import AppIntents
import CoreSpotlight
import DevKitCore
import SwiftUI

@MainActor @Observable final class SpotlightSettingsStore {
  static let shared = SpotlightSettingsStore()
  private(set) var preferences = SpotlightPreferences.load()
  private(set) var status = ""
  private(set) var updating = false
  private var generation = 0
  func setEnabled(_ value: Bool) { preferences.enabled = value; save() }
  func setTool(_ id: String, enabled: Bool) { preferences.setEnabled(enabled, for: id); save() }
  func setAliases(_ text: String, for id: String) throws { try preferences.setAliases(text, for: id); save() }
  func setQuickKeyReminder(_ value: String) {
    preferences.quickKeyReminder = String(value.prefix(24))
    do { try preferences.save() } catch { status = error.localizedDescription }
  }
  func clearAndDisable() {
    preferences.enabled = false
    for tool in SpotlightCatalog.tools { preferences.setEnabled(false, for: tool.id) }
    save()
  }
  private func save() {
    do { try preferences.save(); refresh() }
    catch { status = error.localizedDescription }
  }
  func refresh() {
    generation += 1
    let current = generation
    let snapshot = preferences
    updating = true; status = L10n.tr("Updating the DevKit index…")
    Task {
      do {
        try await SpotlightIndexManager.shared.synchronize(snapshot)
        if generation == current {
          updating = false
          status = !snapshot.enabled ? L10n.tr("DevKit’s tool index is cleared and quick execution is disabled")
            : !SpotlightRuntimeStatus.current.hasDeveloperIdentity ? L10n.tr("Tool index synced; the current signature cannot run Spotlight actions")
            : L10n.tr("Tool index synced (\(SpotlightCatalog.tools.filter { snapshot.allows($0.id) }.count)); bind Quick Keys in Spotlight")
        }
      } catch {
        if generation == current { updating = false; status = L10n.tr("Index update failed: \(error.localizedDescription)") }
      }
    }
  }
}

/// Serialize asynchronous index updates so a slow enable cannot undo a later disable.
actor SpotlightIndexManager {
  static let shared = SpotlightIndexManager()
  private static let indexStateKey = "spotlightIndexStateV1"
  private var operation: Task<Void, Error>?
  func synchronize(_ preferences: SpotlightPreferences) async throws {
    let previous = operation
    let next = Task<Void, Error> {
      _ = await previous?.result
      // An already-disabled integration needs no XPC connection, signing lookup,
      // or App Shortcuts registration on subsequent application launches.
      if !preferences.enabled && UserDefaults.standard.string(forKey: Self.indexStateKey) == "disabled" { return }
      let index = CSSearchableIndex.default()
      UserDefaults.standard.set("pending", forKey: Self.indexStateKey)
      // Cleanup is scoped to this app's index, never the user's system-wide Spotlight database.
      do {
        if preferences.enabled { try await index.deleteAppEntities(ofType: SpotlightToolAction.self) }
        else { try await index.deleteAllSearchableItems() }
      } catch { throw ToolFailure(L10n.tr("Could not clear the tool index: \(error.localizedDescription)")) }
      guard preferences.enabled else {
        UserDefaults.standard.set("disabled", forKey: Self.indexStateKey)
        return
      }
      let entities = SpotlightCatalog.actions.filter { preferences.allows($0.toolID) }
        .map { SpotlightToolAction($0, preferences: preferences) }
      do {
        if !entities.isEmpty { try await index.indexAppEntities(entities) }
      } catch { throw ToolFailure(L10n.tr("Could not write the tool index: \(error.localizedDescription)")) }
      // DevKit never donated intents. Static legacy actions are retired by isDiscoverable=false
      // and the updated provider, rather than calling an unrelated donation-history service.
      if SpotlightRuntimeStatus.current.hasDeveloperIdentity {
        DevKitShortcuts.updateAppShortcutParameters()
      }
      UserDefaults.standard.set("enabled", forKey: Self.indexStateKey)
    }
    operation = next
    try await next.value
  }
}
