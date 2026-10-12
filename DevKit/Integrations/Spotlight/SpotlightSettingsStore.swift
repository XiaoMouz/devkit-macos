import AppIntents
import CoreSpotlight
import DevKitCore
import SwiftUI

@MainActor @Observable final class SpotlightSettingsStore {
  static let shared = SpotlightSettingsStore()
  private(set) var preferences = SpotlightPreferences.load()
  private var statusMessage: LocalizedMessage = ""
  var status: String { L10n.tr(statusMessage) }
  private(set) var updating = false
  private var generation = 0
  func setEnabled(_ value: Bool) { preferences.enabled = value; save() }
  func setTool(_ id: String, enabled: Bool) { preferences.setEnabled(enabled, for: id); save() }
  func clearAndDisable() {
    preferences.enabled = false
    for tool in SpotlightCatalog.tools { preferences.setEnabled(false, for: tool.id) }
    save()
  }
  private func save() {
    do { try preferences.save(); refresh() }
    catch { statusMessage = "Index update failed: \(error.localizedDescription)" }
  }
  func refresh() {
    generation += 1
    let current = generation
    let snapshot = preferences
    updating = true; statusMessage = "Updating the DevKit index…"
    Task {
      do {
        try await SpotlightIndexManager.shared.synchronize(snapshot)
        if generation == current {
          updating = false
          statusMessage = !snapshot.enabled ? "DevKit’s tool index is cleared and quick execution is disabled"
            : !SpotlightRuntimeStatus.current.hasDeveloperIdentity ? "Tool index synced; the current signature cannot run Spotlight actions"
            : "Tool index synced (\(SpotlightCatalog.tools.filter { snapshot.allows($0.id) }.count))"
        }
      } catch {
        if generation == current { updating = false; statusMessage = "Index update failed: \(error.localizedDescription)" }
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
