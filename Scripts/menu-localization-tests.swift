import AppKit
import DevKitCore

@main struct MenuLocalizationRegression {
  @MainActor static func main() {
    func check(_ condition: Bool, line: Int = #line) {
      if !condition { print("FAIL menu localization at line \(line)"); exit(1) }
    }
    let app = NSApplication.shared
    app.finishLaunching()
    let main = NSMenu(title: "Main")
    var menus: [String: NSMenu] = [:]
    for key in NativeMenuLocalization.headings {
      let title = L10n.text(key, language: "zh-Hans")
      let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
      let menu = NSMenu(title: title)
      menu.autoenablesItems = false
      item.submenu = menu
      main.addItem(item)
      menus[key] = menu
    }
    app.mainMenu = main
    app.windowsMenu = menus["Window"]
    app.helpMenu = menus["Help"]
    let close = NSMenuItem(title: "关闭", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    close.keyEquivalentModifierMask = [.command, .option]
    close.isEnabled = false
    close.state = .on
    close.setAccessibilityTitle("Close")
    close.setAccessibilityLabel("Close")
    let payload = NSObject()
    close.representedObject = payload
    menus["File"]!.addItem(close)
    let copy = NSMenuItem(title: "拷贝", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    menus["Edit"]!.addItem(copy)
    let undo = NSMenuItem(title: "撤销键入", action: Selector(("undo:")), keyEquivalent: "z")
    menus["Edit"]!.addItem(undo)
    let window = NSWindow(contentRect: .zero, styleMask: [], backing: .buffered, defer: true)
    window.isReleasedWhenClosed = false
    close.target = window
    let document = NSMenuItem(title: "Copy", action: #selector(NSWindow.makeKeyAndOrderFront(_:)), keyEquivalent: "")
    document.target = window
    menus["Window"]!.addItem(document)
    NativeMenuLocalization.shared.start()
    do {
      for code in ["en", "zh-Hans", "en"] {
        L10n.selectLanguage(code)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        for (key, menu) in menus {
          check(menu.title == L10n.text(key, language: code))
          check(menu.supermenu === main)
        }
        check(close.title == L10n.text("Close", language: code))
        check(close.accessibilityTitle() == close.title)
        check(close.accessibilityLabel() == close.title)
        check(copy.title == L10n.text("Copy", language: code))
        check(undo.title == L10n.text("Undo Typing", language: code))
        check(close.action == #selector(NSWindow.performClose(_:)))
        check(close.target === window)
        check(close.keyEquivalent == "w" && close.keyEquivalentModifierMask == [.command, .option])
        check(!close.isEnabled && close.state == .on && close.representedObject as AnyObject? === payload)
        check(copy.action == #selector(NSText.copy(_:)))
        check(document.title == "Copy" && document.target === window)
      }
      print("PASS all menu headings and standard actions switch both ways without changing behavior")
      // SwiftUI may replace native items after scene/focus changes.
      menus["File"]!.removeItem(close)
      let replacement = NSMenuItem(title: "关闭", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
      menus["File"]!.addItem(replacement)
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
      check(replacement.title == "Close" && replacement.keyEquivalent == "w")
      print("PASS rebuilt menu items are translated; document titles remain untouched")
    }
    for language in L10n.languages {
      for key in NativeMenuLocalization.headings + NativeMenuLocalization.standardTitles {
        check(language.strings[key] != nil)
      }
    }
    print("PASS native menu keys exist in every translation catalog")
  }
}
