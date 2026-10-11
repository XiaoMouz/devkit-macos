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
      Section("命令行工具") {
        Text("通过终端和 AI 调用 DevKit 的 \(ToolRegistry.all.count) 个工具，无需打开主窗口。")
        HStack {
          path(command.path)
          Spacer()
          Button(installed(cli, command) ? "已安装 · 更新链接" : "安装 CLI") {
            install(cli, at: command, key: "cli")
          }
        }
        Text("安装时自动配置终端路径，新开终端即可使用 devkit。已有终端请重开；移动应用后可在这里更新链接。")
          .font(.caption).foregroundStyle(.secondary)
        HStack {
          path("devkit list")
          Spacer()
          Button("复制命令") { Clipboard.copy("devkit list") }
        }
      }
      Section("AI Skill") {
        Text("安装 devkit Skill，让 AI 发现工具、查询参数并通过 CLI 执行。先安装上方 CLI，再为使用的 AI 安装 Skill。")
          .font(.callout)
        skillRow("Codex", directory: codexSkills, key: "codex")
        skillRow("Claude Code", directory: home.appendingPathComponent(".claude/skills"), key: "claude")
        Button("查看 Skill 文件") {
          if let url = AutomationInstallation.skillURL { NSWorkspace.shared.open(url) }
        }
        Text("其他支持 SKILL.md 的 AI 可使用同一份文件。安装后重新打开 AI 会话，使其发现新 Skill。")
          .font(.caption).foregroundStyle(.secondary)
      }
      Section("调用示例") {
        path("devkit describe json")
        path("printf '%s' '{\"hello\":\"DevKit\"}' | devkit run json --format text")
        Text("默认显示排版结果，AI 可加 --format json；联网工具需要 --allow-network。")
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
      Button(AutomationInstallation.skillURL.map { installed($0, destination) } == true ? "已安装 · 更新链接" : "安装 Skill") {
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
        message = "CLI 已安装。新开终端即可运行 devkit list。"
      } else { message = "已安装到 \(destination.path)" }
      failed = false
    } catch {
      message = error.localizedDescription; failed = true
    }
    revision += 1
  }
}
