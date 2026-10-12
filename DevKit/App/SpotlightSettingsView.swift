import DevKitCore
import SwiftUI

struct SpotlightSettingsView: View {
  @State private var store = SpotlightSettingsStore.shared
  @State private var query = ""
  @State private var selectedID = "base64"
  @State private var showingHelp = false
  private var matches: [SpotlightTool] {
    SpotlightCatalog.tools.filter { query.isEmpty || "\($0.name) \($0.sourceName) \($0.id)".localizedStandardContains(query) }
  }
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Toggle(L10n.tr("Enable Spotlight Tools"), isOn: Binding(get: { store.preferences.enabled }, set: store.setEnabled))
            .toggleStyle(.switch).font(.headline)
          Text(L10n.tr("Choose which tools can run from Spotlight.")).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Button { showingHelp = true } label: {
          Label(L10n.tr("Spotlight Help"), systemImage: "questionmark.circle")
        }
      }.padding(20)
      if let issue = SpotlightRuntimeStatus.current.issue {
        Label(issue, systemImage: "exclamationmark.triangle")
          .font(.callout).foregroundStyle(.orange)
          .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 14)
      }
      Divider()
      HStack(spacing: 0) {
        VStack(spacing: 0) {
          TextField(L10n.tr("Search Tools"), text: $query).textFieldStyle(.roundedBorder).padding(12)
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
        Text(store.status.isEmpty ? L10n.tr("Inputs and results are never indexed.") : store.status).lineLimit(2)
        Spacer()
        Button(L10n.tr("Clear Index and Disable")) { store.clearAndDisable() }.disabled(store.updating)
        Button(L10n.tr("Sync Again")) { store.refresh() }.disabled(store.updating)
      }.font(.caption).foregroundStyle(.secondary).padding(14)
    }
    .sheet(isPresented: $showingHelp) { SpotlightHelpView() }
  }
}
private struct SpotlightToolSettings: View {
  let tool: SpotlightTool
  @Bindable var store: SpotlightSettingsStore
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Toggle(tool.name, isOn: Binding(get: { store.preferences.tools[tool.id]?.enabled == true }, set: { store.setTool(tool.id, enabled: $0) }))
          .font(.title3.weight(.semibold)).toggleStyle(.switch)
        if !store.preferences.enabled {
          Text(L10n.tr("Spotlight is disabled globally. This tool cannot currently run from Spotlight.")).font(.caption).foregroundStyle(.secondary)
        }
        Divider()
        VStack(alignment: .leading, spacing: 10) {
          Text(L10n.tr("Command Examples")).font(.headline)
          ForEach(tool.id == "base64" ? tool.actions : Array(tool.actions.prefix(1))) { action in
            Text(action.example(command: tool.id))
              .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(12).background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
          }
        }
        if !tool.operations.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("Supported Operations")).font(.headline)
            Text(tool.localizedOperations.joined(separator: " · "))
              .font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
          }
        }
      }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
private struct SpotlightHelpView: View {
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text(L10n.tr("Spotlight Help")).font(.title2.weight(.semibold))
        Spacer()
        Button(L10n.tr("Done")) { dismiss() }.keyboardShortcut(.defaultAction)
      }.padding(24)
      Divider()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("Getting Started")).font(.headline)
            Text(L10n.tr("Enable Spotlight and the tools you need. Press ⌘ Space, then ⌘3 to search actions."))
            Text(L10n.tr("Choose “Base64 Command” for Base64, or “DevKit Command” for any enabled tool. Enter a command from the tool’s examples."))
            Text(L10n.tr("For guided input, choose “Base64 Encode or Decode” or “DevKit Tool Action”."))
          }
          Divider()
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("Quick Keys in Spotlight")).font(.headline)
            Text(L10n.tr("Quick Keys are optional and managed in Spotlight. Select an action and use “Add Quick Key”; DevKit does not configure them."))
            Text(L10n.tr("For example, assign base64 to “Base64 Command”, then type:"))
            Text(verbatim: "base64 \(SpotlightCatalog.operationCommand("encode")) hello")
              .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
            Text(L10n.tr("Without a Quick Key, select “Base64 Command” and enter:"))
            Text(verbatim: "\(SpotlightCatalog.operationCommand("encode")) hello")
              .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
            Link(L10n.tr("Apple’s Quick Key Setup Guide"), destination: URL(string: "https://support.apple.com/guide/mac-help/mchl4953dfeb/mac")!)
          }
          Divider()
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("Command Language")).font(.headline)
            Text(L10n.tr("Examples follow the app language. English operations such as encode / decode and abbreviations enc / dec still work. Keep tool names such as base64 unchanged."))
            Text(L10n.tr("Use -- for empty text. Spaces and line breaks in the input are preserved."))
          }
          Divider()
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("Troubleshooting")).font(.headline)
            Text(L10n.tr("You should see the DevKit action’s parameter field. If you only see Search Web or Search iCloud Drive, you are still in search. Syncing the index does not bind a Quick Key."))
            Text(L10n.tr("Disabling a tool removes its index entries and blocks quick execution. macOS may still show registered action names, but execution checks this setting. Control app visibility in Spotlight settings."))
            Text(L10n.tr("Inputs and results are never indexed."))
          }
        }.font(.callout).frame(maxWidth: .infinity, alignment: .leading).padding(24)
      }
    }.frame(width: 580, height: 540)
  }
}
