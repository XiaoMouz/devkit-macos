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
        .onChange(of: appearance, initial: true) { _, value in AppAppearance.apply(value) }
    }
    .defaultSize(width: 1280, height: 820)
    .windowResizability(.contentMinSize)
    .windowToolbarStyle(.unified)
    .commands {
      SidebarCommands()
      InspectorCommands()
      DevKitCommands()
    }
    Settings { SettingsView() }
  }
}

@MainActor final class DevKitApplicationDelegate: NSObject, NSApplicationDelegate {
  func applicationWillFinishLaunching(_ notification: Notification) {
    // Tools switch from the sidebar; window tabs would duplicate that navigation.
    NSWindow.allowsAutomaticWindowTabbing = false
    AppAppearance.apply(UserDefaults.standard.string(forKey: "appearance") ?? "system")
  }
  func applicationDidFinishLaunching(_ notification: Notification) {
    SpotlightSettingsStore.shared.refresh()
  }
}

@MainActor final class WorkspaceActions {
  let run: () -> Void
  let copy: () -> Void
  let search: () -> Void
  let supportsNavigation: Bool
  let selectPane: ((Int) -> Void)?
  let canSelectPane: () -> Bool
  init(run: @escaping () -> Void, copy: @escaping () -> Void, search: @escaping () -> Void,
    supportsNavigation: Bool = true, selectPane: ((Int) -> Void)? = nil,
    canSelectPane: @escaping () -> Bool = { false }) {
    self.run = run; self.copy = copy; self.search = search
    self.supportsNavigation = supportsNavigation; self.selectPane = selectPane
    self.canSelectPane = canSelectPane
  }
}
struct DevKitCommands: Commands {
  private var resolved: WorkspaceActions? { WindowCommandRouter.current }
  var body: some Commands {
    CommandMenu("工具") {
      Button("搜索工具") { resolved?.search() }.keyboardShortcut("f", modifiers: [.command, .option])
        .disabled(resolved?.supportsNavigation != true)
      Button("执行") { resolved?.run() }.keyboardShortcut(.return, modifiers: .command)
      Button("复制完整结果") { resolved?.copy() }.keyboardShortcut("c", modifiers: [.command, .shift])
      Divider()
      Button("显示输入") { resolved?.selectPane?(0) }.keyboardShortcut(
        "1", modifiers: [.command, .option]
      ).disabled(resolved?.canSelectPane() != true)
      Button("显示结果") { resolved?.selectPane?(1) }.keyboardShortcut(
        "2", modifiers: [.command, .option]
      ).disabled(resolved?.canSelectPane() != true)

    }
  }
}
