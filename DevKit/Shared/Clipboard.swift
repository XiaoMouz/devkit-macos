import AppKit

@MainActor
enum Clipboard {
  @discardableResult static func copy(_ value: String) -> Bool {
    NSPasteboard.general.clearContents()
    return NSPasteboard.general.setString(value, forType: .string)
  }
}
