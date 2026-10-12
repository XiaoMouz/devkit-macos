import AppIntents

/// Entry points are static system metadata. The tools offered inside them are user-controlled.
struct DevKitShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(intent: Base64CommandIntent(), phrases: ["Run a Base64 command with \(.applicationName)"],
      shortTitle: "Base64 Command", systemImageName: "arrow.left.arrow.right")
    AppShortcut(intent: Base64GuidedIntent(), phrases: ["Convert Base64 with \(.applicationName)"],
      shortTitle: "Base64 Encode or Decode", systemImageName: "arrow.left.arrow.right")
    AppShortcut(intent: DevKitCommandIntent(), phrases: ["Run a command with \(.applicationName)"],
      shortTitle: "DevKit Command", systemImageName: "terminal")
    AppShortcut(intent: DevKitToolIntent(), phrases: ["Process text with \(.applicationName)"],
      shortTitle: "DevKit Tool Action", systemImageName: "curlybraces")
  }
}
