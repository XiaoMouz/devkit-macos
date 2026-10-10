import AppIntents

/// Entry points are static system metadata. The tools offered inside them are user-controlled.
struct DevKitShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: DevKitCommandIntent(), phrases: ["使用 \(.applicationName) 执行命令"],
      shortTitle: "DevKit 命令", systemImageName: "terminal")
    AppShortcut(intent: DevKitToolIntent(), phrases: ["使用 \(.applicationName) 处理文本"],
      shortTitle: "DevKit 工具操作", systemImageName: "curlybraces")
  }
}
