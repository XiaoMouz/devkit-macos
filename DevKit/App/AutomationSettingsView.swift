import DevKitCore
import SwiftUI

struct AutomationSettingsView: View {
  @State private var message: String?
  @State private var failed = false
  @State private var revision = 0
  private let home = FileManager.default.homeDirectoryForCurrentUser
  private var cli: URL { Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/devkit") }
  private var command: URL { home.appendingPathComponent(".local/bin/devkit") }

  var body: some View {
    Form {
      Section(L10n.tr("Command-Line Tools")) {
        Text(L10n.tr("Use DevKit’s \(ToolRegistry.all.count) tools from your terminal or AI without opening the main window."))
        HStack {
          path(command.path)
          Spacer()
          Button(installed(cli, command) ? L10n.tr("Installed · Update Link") : L10n.tr("Install CLI")) {
            install(cli, at: command, key: "cli")
          }
        }
        Text(L10n.tr("Installation configures your terminal path. Open a new terminal to use devkit. Reopen existing terminals; update the link here if you move the app."))
          .font(.caption).foregroundStyle(.secondary)
        HStack {
          path("devkit list")
          Spacer()
          Button(L10n.tr("Copy Command")) { Clipboard.copy("devkit list") }
        }
      }
      Section("AI Skill") {
        Text(L10n.tr("Install the devkit Skill so AI can discover tools, inspect parameters, and run the CLI. Install the CLI above first, then install the Skill for your AI."))
          .font(.callout)
        skillRow("Codex", directory: codexSkills, key: "codex")
        skillRow("Claude Code", directory: home.appendingPathComponent(".claude/skills"), key: "claude")
        Button(L10n.tr("View Skill Files")) {
          if let url = AutomationInstallation.skillURL { NSWorkspace.shared.open(url) }
        }
        Text(L10n.tr("Other AI tools that support SKILL.md can use the same files. Start a new AI session after installation to discover the Skill."))
          .font(.caption).foregroundStyle(.secondary)
      }
      Section(L10n.tr("Examples")) {
        path("devkit describe json")
        path("printf '%s' '{\"hello\":\"DevKit\"}' | devkit run json --format text")
        Text(L10n.tr("Results are formatted by default. AI can add --format json; network tools require --allow-network."))
          .font(.caption).foregroundStyle(.secondary)
      }
      if let message {
        Section {
          Label(message, systemImage: failed ? "exclamationmark.triangle" : "checkmark.circle")
            .foregroundStyle(failed ? Color.orange : Color.secondary)
            .textSelection(.enabled)
        }
      }
    }
    .formStyle(.grouped)
  }

  private var codexSkills: URL {
    if let directory = ProcessInfo.processInfo.environment["CODEX_HOME"], directory.hasPrefix("/") {
      return URL(fileURLWithPath: directory).appendingPathComponent("skills")
    }
    return home.appendingPathComponent(".codex/skills")
  }

  private func path(_ text: String) -> some View {
    Text(text).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
  }

  private func installed(_ source: URL, _ destination: URL) -> Bool {
    _ = revision
    return AutomationInstallation.isInstalled(source: source, destination: destination)
  }

  private func skillRow(_ name: String, directory: URL, key: String) -> some View {
    let destination = directory.appendingPathComponent("devkit")
    return HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(name)
        path(destination.path).foregroundStyle(.secondary)
      }
      Spacer()
      Button(AutomationInstallation.skillURL.map { installed($0, destination) } == true ? L10n.tr("Installed · Update Link") : L10n.tr("Install Skill")) {
        if let source = AutomationInstallation.skillURL { install(source, at: destination, key: key) }
      }.disabled(AutomationInstallation.skillURL == nil)
    }
  }

  private func install(_ source: URL, at destination: URL, key: String) {
    let setting = "automation.installed.\(key)"
    do {
      try AutomationInstallation.installLink(source: source, destination: destination,
        previousSource: UserDefaults.standard.string(forKey: setting))
      UserDefaults.standard.set(source.path, forKey: setting)
      if key == "cli" {
        try AutomationInstallation.configureCommandPath(home: home, shell: AutomationInstallation.loginShell)
        message = L10n.tr("CLI installed. Open a new terminal and run devkit list.")
      } else { message = L10n.tr("Installed at \(destination.path)") }
      failed = false
    } catch {
      message = error.localizedDescription; failed = true
    }
    revision += 1
  }
}
