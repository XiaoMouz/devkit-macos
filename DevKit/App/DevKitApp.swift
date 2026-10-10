import AppIntents
import SwiftUI

@main
struct DevKitApp: App {
  @AppStorage("appearance") private var appearance = "system"
  @NSApplicationDelegateAdaptor(DevKitApplicationDelegate.self) private var delegate
  init() { signal(SIGPIPE, SIG_IGN) }
  var body: some Scene {
    WindowGroup {
      MainWindow()
        .containerBackground(.clear, for: .window)
        .onChange(of: appearance, initial: true) { _, value in AppAppearance.apply(value) }
    }
    .defaultSize(width: 1280, height: 820)
    .windowResizability(.contentMinSize)
    .windowStyle(.hiddenTitleBar)
    .commands { DevKitCommands() }
    Settings { SettingsView() }
  }
}

@MainActor final class DevKitApplicationDelegate: NSObject, NSApplicationDelegate {
  func applicationWillFinishLaunching(_ notification: Notification) {
    AppAppearance.apply(UserDefaults.standard.string(forKey: "appearance") ?? "system")
  }
  func applicationDidFinishLaunching(_ notification: Notification) {
    SpotlightSettingsStore.shared.refresh()
  }
}

struct WorkspaceActions {
  var run: () -> Void
  var copy: () -> Void
  var search: () -> Void
  var supportsNavigation = true
  var selectPane: ((Int) -> Void)? = nil
}
private struct WorkspaceActionKey: FocusedValueKey { typealias Value = WorkspaceActions }
extension FocusedValues {
  var workspaceActions: WorkspaceActions? {
    get { self[WorkspaceActionKey.self] }
    set { self[WorkspaceActionKey.self] = newValue }
  }
}
struct DevKitCommands: Commands {
  @FocusedValue(\.workspaceActions) private var actions
  private var resolved: WorkspaceActions? { WindowCommandRouter.current ?? actions }
  var body: some Commands {
    CommandMenu("工具") {
      Button("搜索工具") { resolved?.search() }.keyboardShortcut("f", modifiers: [.command, .option])
        .disabled(resolved?.supportsNavigation != true)
      Button("执行") { resolved?.run() }.keyboardShortcut(.return, modifiers: .command)
      Button("复制完整结果") { resolved?.copy() }.keyboardShortcut("c", modifiers: [.command, .shift])
      Divider()
      Button("显示输入") { resolved?.selectPane?(0) }.keyboardShortcut(
        "1", modifiers: [.command, .option]
      ).disabled(resolved?.selectPane == nil)
      Button("显示结果") { resolved?.selectPane?(1) }.keyboardShortcut(
        "2", modifiers: [.command, .option]
      ).disabled(resolved?.selectPane == nil)

    }
  }
}
