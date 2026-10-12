import DevKitCore
import SwiftUI

struct SpotlightSettingsView: View {
  @State private var store = SpotlightSettingsStore.shared
  @State private var query = ""
  @State private var selectedID = "base64"
  private var matches: [SpotlightTool] {
    SpotlightCatalog.tools.filter { query.isEmpty || "\($0.name) \($0.id) \(store.preferences.aliases(for: $0.id).joined(separator: " "))".localizedStandardContains(query) }
  }
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Toggle(L10n.tr("Enable Spotlight Tools"), isOn: Binding(get: { store.preferences.enabled }, set: store.setEnabled))
            .toggleStyle(.switch).font(.headline)
          Text(L10n.tr("After enabling tools, set a Quick Key for the action in Spotlight.")).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Button(L10n.tr("Clear Index and Disable")) { store.clearAndDisable() }.disabled(store.updating)
      }.padding(20)
      if let issue = SpotlightRuntimeStatus.current.issue {
        Label(issue, systemImage: "exclamationmark.triangle")
          .font(.callout).foregroundStyle(.orange)
          .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 14)
      }
      Divider()
      HStack(spacing: 0) {
        VStack(spacing: 0) {
          TextField(L10n.tr("Search tools or aliases"), text: $query).textFieldStyle(.roundedBorder).padding(12)
          List(selection: $selectedID) {
            ForEach(matches) { tool in
              HStack {
                Label(tool.name, systemImage: tool.symbol).font(.system(size: 12))
                Spacer()
                Image(systemName: store.preferences.allows(tool.id) ? "checkmark.circle.fill" : "circle")
                  .font(.system(size: 11))
                  .foregroundStyle(store.preferences.allows(tool.id) ? AnyShapeStyle(Color.green) : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
                  .accessibilityLabel(store.preferences.allows(tool.id) ? L10n.tr("Enabled") : L10n.tr("Disabled"))
              }.tag(tool.id).padding(.vertical, 6)
            }
          }.listStyle(.sidebar)
        }.frame(width: 214)
        Divider()
        if let tool = SpotlightCatalog.tools.first(where: { $0.id == selectedID }) {
          SpotlightToolSettings(tool: tool, store: store).id(tool.id)
        }
      }
      Divider()
      HStack(spacing: 8) {
        if store.updating { ProgressView().controlSize(.mini) }
        Text(store.status.isEmpty ? L10n.tr("Only tool names and aliases are indexed. Inputs and results are never saved.") : store.status).lineLimit(2)
        Spacer()
        Button(L10n.tr("Sync Again")) { store.refresh() }.disabled(store.updating)
      }.font(.caption).foregroundStyle(.secondary).padding(14)
    }
  }
}
private struct SpotlightToolSettings: View {
  let tool: SpotlightTool
  @Bindable var store: SpotlightSettingsStore
  @State private var aliases = ""
  @State private var validation: String?
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Toggle(tool.name, isOn: Binding(get: { store.preferences.tools[tool.id]?.enabled == true }, set: { store.setTool(tool.id, enabled: $0) }))
          .font(.title3.weight(.semibold)).toggleStyle(.switch)
        if !store.preferences.enabled { Text(L10n.tr("Spotlight is disabled globally. This tool cannot currently run from Spotlight.")).font(.caption).foregroundStyle(.secondary) }
        setupGuide
        Divider()
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("In-App Command Aliases")).font(.headline)
          HStack {
            TextField(L10n.tr("For example: b64, base64"), text: $aliases).textFieldStyle(.roundedBorder).onSubmit(save)
              .accessibilityLabel(L10n.tr("Command Aliases"))
            Button(L10n.tr("Save"), action: save)
              .disabled(aliases == store.preferences.aliases(for: tool.id).joined(separator: ", "))
          }
          Text(L10n.tr("Separate aliases with commas. They work inside the DevKit Command action and do not change Spotlight Quick Keys. The original tool name \(tool.id) always works.")).font(.caption).foregroundStyle(.secondary)
          if let validation { Text(validation).font(.caption).foregroundStyle(.orange) }
        }
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.tr("Enter in DevKit Command")).font(.headline)
          Text(tool.example(alias: store.preferences.aliases(for: tool.id).first ?? tool.id))
            .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
          if !tool.operations.isEmpty {
            Text(L10n.tr("Supported operations: \(tool.operations.joined(separator: "、"))")).font(.caption).foregroundStyle(.secondary)
          }
          if tool.id == "base64" {
            Text(L10n.tr("You can also use enc / dec for encode / decode.")).font(.caption).foregroundStyle(.secondary)
          }
        }
        Divider()
        Text(L10n.tr("Disabling a tool removes its index entries and blocks quick execution. macOS may still show registered action names, but execution checks this setting. Control app visibility in Spotlight settings.")).font(.caption).foregroundStyle(.secondary)
      }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }
    .onAppear { aliases = store.preferences.aliases(for: tool.id).joined(separator: ", ") }
  }
  private var setupGuide: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(L10n.tr("First Use: Set a Quick Key")).font(.headline)
      if tool.id == "base64" {
        Text(L10n.tr("1. Press ⌘ Space to open Spotlight, then ⌘3 to search actions."))
        Text(L10n.tr("2. Search for “Base64 Command” and check that it is from DevKit."))
        Text(L10n.tr("3. Click “Add Quick Key” next to the action and enter base64."))
        Text(L10n.tr("Then enter: base64 encode 123 → MTIz"))
          .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
        Text(L10n.tr("You can also select “Base64 Command” and enter encode 123. For guided choices, search for “Base64 Encode or Decode”."))
          .font(.caption).foregroundStyle(.secondary)
      } else {
        Text(L10n.tr("Press ⌘ Space to open Spotlight, then ⌘3 to search for “DevKit Command”. Add a Quick Key such as \(store.preferences.quickKeyReminder)."))
        Text(L10n.tr("Then enter: \(store.preferences.quickKeyReminder) \(tool.example(alias: store.preferences.aliases(for: tool.id).first ?? tool.id))"))
          .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
        HStack {
          Text(L10n.tr("Quick Key Reminder")).font(.caption).foregroundStyle(.secondary)
          TextField("dk", text: Binding(get: { store.preferences.quickKeyReminder }, set: store.setQuickKeyReminder))
            .textFieldStyle(.roundedBorder).frame(width: 90)
        }
      }
      Text(L10n.tr("You should see the DevKit action’s parameter field. If you only see Search Web or Search iCloud Drive, you are still in search. Syncing the index does not bind a Quick Key."))
        .font(.caption).foregroundStyle(.secondary)
      Link(L10n.tr("Apple’s Quick Key Setup Guide"), destination: URL(string: "https://support.apple.com/zh-cn/guide/mac-help/mchl4953dfeb/26/mac/26")!)
        .font(.caption)
    }.font(.callout)
  }
  private func save() {
    do { try store.setAliases(aliases, for: tool.id); aliases = store.preferences.aliases(for: tool.id).joined(separator: ", "); validation = nil }
    catch { validation = error.localizedDescription }
  }
}
