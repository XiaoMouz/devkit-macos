import AppKit
import DevKitCore
import Observation

/// SwiftUI owns the menu structure and responder-chain actions. Update only
/// display titles when it rebuilds a menu or the app language changes.
@MainActor final class NativeMenuLocalization: NSObject {
  static let shared = NativeMenuLocalization()
  private final class Binding: NSObject {
    let key: String
    var rendered: String
    init(key: String, rendered: String) { self.key = key; self.rendered = rendered }
  }
  private let bindings = NSMapTable<NSMenuItem, Binding>.weakToStrongObjects()
  private var started = false
  private var scheduled = false
  private var applying = false

  func start() {
    guard !started else { return }
    started = true
    for name in [NSMenu.didAddItemNotification, NSMenu.didChangeItemNotification,
                 NSMenu.didBeginTrackingNotification, NSApplication.didBecomeActiveNotification,
                 NSWindow.didBecomeKeyNotification] {
      // AppKit delivers these notifications on the main thread. The selector
      // observer keeps non-Sendable menu objects inside that isolation domain.
      NotificationCenter.default.addObserver(self, selector: #selector(menuChanged(_:)), name: name, object: nil)
    }
    observeLanguage()
    schedule()
  }
  @objc private func menuChanged(_ notification: Notification) {
    guard !applying else { return }
    if let menu = notification.object as? NSMenu, !belongsToMainMenu(menu) { return }
    // AppKit can post item changes while holding its key-equivalent lock.
    // Mutating/inspecting menus in that callback can reenter menu population.
    schedule()
  }
  private func observeLanguage() {
    withObservationTracking { _ = L10n.language } onChange: { [weak self] in
      Task { @MainActor in
        self?.schedule()
        self?.observeLanguage()
      }
    }
  }
  private func belongsToMainMenu(_ menu: NSMenu) -> Bool {
    var root = menu
    while let parent = root.supermenu { root = parent }
    return root === NSApp.mainMenu
  }
  private func schedule() {
    guard !scheduled else { return }
    scheduled = true
    // Common modes also run while a menu is tracking, without updating it
    // synchronously inside AppKit's notification/validation call stack.
    RunLoop.main.perform(inModes: [.common]) { [weak self] in
      MainActor.assumeIsolated {
        guard let self else { return }
        self.scheduled = false
        if let menu = NSApp.mainMenu { self.apply(to: menu) }
      }
    }
  }

  func apply(to mainMenu: NSMenu) {
    guard !applying else { return }
    applying = true
    defer { applying = false }
    for item in mainMenu.items {
      guard let menu = item.submenu else { continue }
      let key: String?
      if menu === NSApp.windowsMenu { key = "Window" }
      else if menu === NSApp.helpMenu { key = "Help" }
      else { key = self.key(for: item, allowed: Self.headings) }
      if let key { translate(item, key: key) }
      translateContents(of: menu)
    }
  }
  private func translateContents(of menu: NSMenu) {
    // These submenus contain names supplied by other apps, documents, or windows.
    guard menu !== NSApp.servicesMenu else { return }
    for item in menu.items where !item.isSeparatorItem {
      let action = item.action.map(NSStringFromSelector) ?? ""
      // Standard Close/Zoom items also target NSWindow. Skip only window-list
      // entries, whose titles are document data, rather than every window target.
      guard action != "makeKeyAndOrderFront:" else { continue }
      let key = self.key(for: item, allowed: Self.standardTitles)
        ?? (item.isAlternate ? nil : Self.actionTitles[action])
      if let key { translate(item, key: key) }
      if let submenu = item.submenu, let key, key != "Open Recent" { translateContents(of: submenu) }
    }
  }
  private func key(for item: NSMenuItem, allowed: [String]) -> String? {
    if let binding = bindings.object(forKey: item), item.title == binding.rendered,
      allowed.contains(binding.key) { return binding.key }
    guard let key = Self.aliases[Self.normalized(item.title)], allowed.contains(key) else { return nil }
    return key
  }
  private func translate(_ item: NSMenuItem, key: String) {
    let title = L10n.text(key)
    let previous = bindings.object(forKey: item)
    let binding = previous?.key == key ? previous! : Binding(key: key, rendered: "")
    let titleChanged = item.title != title || binding.rendered != title
    binding.rendered = title
    bindings.setObject(binding, forKey: item)
    if item.title != title { item.title = title }
    if titleChanged {
      // Never read accessibilityTitle/Label here: AppKit may open/populate
      // another menu to answer the query. Update through NSAccessibility's
      // supported setters and notify clients without probing through AX.
      // SwiftUI can retain a cached AXTitle; accessibilityLabel supplies the
      // localized name used by VoiceOver without overriding legacy attributes.
      item.setAccessibilityTitle(title)
      item.setAccessibilityLabel(title)
      NSAccessibility.post(element: item, notification: .titleChanged)
    }
    // AppKit uses the submenu title for top-level menu-bar labels.
    if let submenu = item.submenu, submenu.title != title { submenu.title = title }
  }
  private static func normalized(_ value: String) -> String {
    value.replacingOccurrences(of: "...", with: "…").filter { !$0.isWhitespace }.lowercased()
  }

  private static let aliases: [String: String] = {
    var result: [String: String] = [:]
    for key in headings + standardTitles {
      result[normalized(key)] = key
      for language in L10n.languages {
        if let value = language.strings[key] { result[normalized(value)] = key }
      }
    }
    // InspectorCommands can concatenate an English verb with a localized
    // Inspector label. Recognize those native titles without translating data.
    for verb in ["Show", "Hide"] {
      for language in L10n.languages {
        if let inspector = language.strings["Inspector"] {
          result[normalized(verb + inspector)] = verb + " Inspector"
          result[normalized(verb + " " + inspector)] = verb + " Inspector"
        }
      }
    }
    return result
  }()

  static let headings = ["File", "Edit", "View", "Tools", "Window", "Help"]
  static let standardTitles = [
    "Check for Updates…", "Restart to Update…",
    "Search Tools", "Run", "Copy Full Result", "Show Input", "Show Result", "Toggle Sidebar", "Toggle Inspector",
    "About DevKit", "Settings…", "Services", "Hide DevKit", "Hide Others", "Show All", "Quit DevKit",
    "New Window", "New Tab", "Close", "Close All", "Open…", "Open Recent", "Save…", "Save As…", "Revert to Saved", "Print…",
    "AutoFill", "Contacts…", "Passwords…", "Credit Cards…",
    "Undo", "Redo", "Undo Typing", "Redo Typing", "Undo Paste", "Redo Paste", "Cut", "Copy", "Paste", "Paste and Match Style", "Delete", "Select All",
    "Find", "Find…", "Find Next", "Find Previous", "Use Selection for Find", "Jump to Selection",
    "Spelling and Grammar", "Show Spelling and Grammar", "Check Document Now", "Check Spelling While Typing", "Check Grammar With Spelling", "Correct Spelling Automatically",
    "Substitutions", "Show Substitutions", "Smart Copy/Paste", "Smart Quotes", "Smart Dashes", "Smart Links", "Data Detectors", "Text Replacement",
    "Transformations", "Make Upper Case", "Make Lower Case", "Capitalize", "Speech", "Start Speaking", "Stop Speaking", "Writing Tools", "Start Dictation…", "Emoji & Symbols",
    "Show Sidebar", "Hide Sidebar", "Show Inspector", "Hide Inspector", "Show Toolbar", "Hide Toolbar", "Customize Toolbar…", "Show Tab Bar", "Hide Tab Bar", "Show All Tabs", "Exit Tab Overview", "Enter Full Screen", "Exit Full Screen",
    "Halves", "Quarters", "Left & Right", "Left & Quarters", "Right & Left", "Right & Quarters", "Top & Bottom", "Top & Quarters", "Bottom & Top", "Bottom & Quarters", "Left of Screen", "Right of Screen", "Bring to Front", "Remove Window from Set",
    "Minimize", "Minimize All", "Zoom", "Zoom All", "Move & Resize", "Full Screen Tile", "Center", "Fill", "Left", "Right", "Top", "Bottom", "Top Left", "Top Right", "Bottom Left", "Bottom Right", "Return to Previous Size", "Arrange", "Bring All to Front", "Show Previous Tab", "Show Next Tab", "Move Tab to New Window", "Merge All Windows", "DevKit Help",
  ]
  private static let actionTitles = [
    "orderFrontStandardAboutPanel:": "About DevKit", "hide:": "Hide DevKit",
    "hideOtherApplications:": "Hide Others", "unhideAllApplications:": "Show All", "terminate:": "Quit DevKit",
    "performClose:": "Close", "closeAll:": "Close All", "cut:": "Cut", "copy:": "Copy",
    "paste:": "Paste", "pasteAsPlainText:": "Paste and Match Style", "delete:": "Delete", "selectAll:": "Select All",
    "performMiniaturize:": "Minimize", "miniaturizeAll:": "Minimize All", "performZoom:": "Zoom", "zoomAll:": "Zoom All", "alternateArrangeInFront:": "Bring to Front", "arrangeInFront:": "Bring All to Front", "showHelp:": "DevKit Help",
    "orderFrontCharacterPalette:": "Emoji & Symbols",
  ]
}
