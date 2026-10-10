import AppIntents

/// Entry points are static system metadata. The tools offered inside them are user-controlled.
struct DevKitShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: Base64CommandIntent(), phrases: ["使用 \(.applicationName) 执行 Base64 命令"],
      shortTitle: "Base64 命令", systemImageName: "arrow.left.arrow.right")
    AppShortcut(intent: Base64GuidedIntent(), phrases: ["使用 \(.applicationName) 转换 Base64"],
      shortTitle: "Base64 编码或解码", systemImageName: "arrow.left.arrow.right")
    AppShortcut(intent: DevKitCommandIntent(), phrases: ["使用 \(.applicationName) 执行命令"],
      shortTitle: "DevKit 命令", systemImageName: "terminal")
    AppShortcut(intent: DevKitToolIntent(), phrases: ["使用 \(.applicationName) 处理文本"],
      shortTitle: "DevKit 工具操作", systemImageName: "curlybraces")
  }
}
