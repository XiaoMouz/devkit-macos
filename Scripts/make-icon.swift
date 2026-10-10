import AppKit
import Foundation

// Vector-drawn application mark; reproducible at every asset size.
let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
var entries = [[String: String]]()
for size in [16, 32, 128, 256, 512] {
  for scale in [1, 2] {
    let pixels = size * scale
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
      samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
      bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let f = CGFloat(pixels) / 1024
    let transform = NSAffineTransform()
    transform.scale(by: f)
    transform.concat()
    let outer = NSBezierPath(
      roundedRect: NSRect(x: 24, y: 24, width: 976, height: 976), xRadius: 222, yRadius: 222)
    let gradient = NSGradient(
      starting: NSColor(srgbRed: 0.18, green: 0.64, blue: 1, alpha: 1),
      ending: NSColor(srgbRed: 0.10, green: 0.24, blue: 0.83, alpha: 1))!
    gradient.draw(in: outer, angle: -80)
    let inset = NSBezierPath(
      roundedRect: NSRect(x: 139, y: 180, width: 746, height: 665), xRadius: 104, yRadius: 104)
    NSColor.white.withAlphaComponent(0.11).setFill()
    inset.fill()
    NSColor.white.withAlphaComponent(0.25).setStroke()
    inset.lineWidth = 3
    inset.stroke()
    for direction: CGFloat in [-1, 1] {
      let path = NSBezierPath()
      func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: 512 + direction * x, y: y) }
      path.move(to: point(95, 724))
      path.curve(
        to: point(188, 637), controlPoint1: point(184, 724), controlPoint2: point(188, 724))
      path.line(to: point(188, 596))
      path.curve(
        to: point(242, 512), controlPoint1: point(188, 546), controlPoint2: point(200, 520))
      path.curve(
        to: point(188, 428), controlPoint1: point(200, 504), controlPoint2: point(188, 478))
      path.line(to: point(188, 387))
      path.curve(to: point(95, 300), controlPoint1: point(188, 300), controlPoint2: point(184, 300))
      NSColor.white.setStroke()
      path.lineWidth = 48
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      path.stroke()
    }
    NSColor.white.withAlphaComponent(0.9).setFill()
    NSBezierPath(ovalIn: NSRect(x: 483, y: 483, width: 58, height: 58)).fill()
    NSGraphicsContext.restoreGraphicsState()
    let name = "icon_\(size)x\(size)@\(scale)x.png"
    try bitmap.representation(using: .png, properties: [:])!.write(
      to: directory.appendingPathComponent(name))
    entries.append([
      "idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": name,
    ])
  }
}
let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted).write(
  to: directory.appendingPathComponent("Contents.json"))
