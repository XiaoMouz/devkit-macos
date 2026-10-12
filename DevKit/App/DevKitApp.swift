import DevKitCore
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
        .environment(\.locale, L10n.locale)
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
    Settings { SettingsView().environment(\.locale, L10n.locale) }
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
    CommandMenu(L10n.tr("Tools")) {
      Button(L10n.tr("Search Tools")) { resolved?.search() }.keyboardShortcut("f", modifiers: [.command, .option])
        .disabled(resolved?.supportsNavigation != true)
      Button(L10n.tr("Run")) { resolved?.run() }.keyboardShortcut(.return, modifiers: .command)
      Button(L10n.tr("Copy Full Result")) { resolved?.copy() }.keyboardShortcut("c", modifiers: [.command, .shift])
      Divider()
      Button(L10n.tr("Show Input")) { resolved?.selectPane?(0) }.keyboardShortcut(
        "1", modifiers: [.command, .option]
      ).disabled(resolved?.canSelectPane() != true)
      Button(L10n.tr("Show Result")) { resolved?.selectPane?(1) }.keyboardShortcut(
        "2", modifiers: [.command, .option]
      ).disabled(resolved?.canSelectPane() != true)

    }
  }
}
