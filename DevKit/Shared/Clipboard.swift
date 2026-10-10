import AppKit
import DevKitCore
import UniformTypeIdentifiers

@MainActor
enum Clipboard {
  @discardableResult static func copy(_ value: String) -> Bool {
    NSPasteboard.general.clearContents()
    return NSPasteboard.general.setString(value, forType: .string)
  }
  @discardableResult static func copyImage(_ artifact: Artifact) -> Bool {
    guard let image = NSImage(data: artifact.data), let tiff = image.tiffRepresentation,
      let type = UTType(mimeType: artifact.mime) else { return false }
    let item = NSPasteboardItem()
    guard item.setData(artifact.data, forType: NSPasteboard.PasteboardType(type.identifier)) else {
      return false
    }
    if type != .tiff { item.setData(tiff, forType: .tiff) }
    NSPasteboard.general.clearContents()
    return NSPasteboard.general.writeObjects([item])
  }
}
