import DevKitCore
import SwiftUI

struct SettingsView: View {
  @AppStorage(L10n.preferenceKey) private var language = "system"
  @AppStorage("appearance") private var appearance = "system"
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @AppStorage("wrapLines") private var wrap = true
  var body: some View {
    TabView {
      Form {
        Section(L10n.tr("Language")) {
          Picker(L10n.tr("App Language"), selection: $language) {
            Text(L10n.tr("Follow System")).tag("system")
            ForEach(L10n.languages) { language in Text(language.name).tag(language.id) }
          }
          Text(L10n.tr("Changes apply immediately without closing your work. Existing results stay unchanged; new runs use the selected language."))
            .font(.caption).foregroundStyle(.secondary)
          Text(L10n.tr("Some macOS dialogs and Spotlight labels update the next time the system loads them."))
            .font(.caption).foregroundStyle(.secondary)
        }

        Section(L10n.tr("Appearance")) {
          Picker(L10n.tr("Theme"), selection: $appearance) {
            Text(L10n.tr("Follow System")).tag("system")
            Text(L10n.tr("Light")).tag("light")
            Text(L10n.tr("Dark")).tag("dark")
          }
          Text(L10n.tr("Liquid Glass transparency follows System Settings → Appearance and the Reduce Transparency accessibility setting."))
            .font(.caption).foregroundStyle(.secondary)
        }
        Section(L10n.tr("Editor")) {
          Slider(value: $fontSize, in: 11...22, step: 1) { Text(L10n.tr("Font Size \(Int(fontSize))")) }
          Toggle(L10n.tr("Wrap Lines"), isOn: $wrap)
        }
      }.formStyle(.grouped).tabItem { Label(L10n.tr("General"), systemImage: "gearshape") }
      SpotlightSettingsView().tabItem { Label("Spotlight", systemImage: "magnifyingglass") }
      AutomationSettingsView().tabItem { Label(L10n.tr("CLI & AI"), systemImage: "terminal") }
      UpdateSettingsView().tabItem { Label(L10n.tr("Updates"), systemImage: "arrow.down.circle") }
      VStack(spacing: 12) {
        Image(nsImage: NSApp.applicationIconImage).resizable().scaledToFit().frame(width: 96, height: 96)
          .accessibilityHidden(true)
        Text("DevKit").font(.title.bold())
        Text(L10n.tr("A native macOS toolkit for web developers")).foregroundStyle(.secondary)
        HStack(spacing: 14) {
          Label(L10n.tr("Tools: \(ToolRegistry.all.count)"), systemImage: "square.grid.2x2")
          Label(L10n.tr("Local Processing"), systemImage: "lock.shield")
        }.font(.callout).foregroundStyle(.secondary).padding(.top, 4)
        Text(verbatim: "\(AppUpdater.version) · macOS 26+").font(.caption).foregroundStyle(.tertiary)
      }.frame(maxWidth: .infinity, maxHeight: .infinity).tabItem { Label(L10n.tr("About"), systemImage: "info.circle") }
    }.frame(width: 800, height: 610)
      .onChange(of: language) { _, value in
        L10n.selectLanguage(value)
        // Native system components also receive the preference on their next load.
        if value == "system" { UserDefaults.standard.removeObject(forKey: "AppleLanguages") }
        else { UserDefaults.standard.set([value], forKey: "AppleLanguages") }
        SpotlightSettingsStore.shared.refresh()
      }
      .onChange(of: appearance) { _, value in AppAppearance.apply(value) }
  }
}
