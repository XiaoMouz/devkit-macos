import Foundation

public struct ColorValue: Sendable {
  public let r: Double, g: Double, b: Double, a: Double
  public var hexValue: String {
    let rgb = String(
      format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()),
      Int((b * 255).rounded()))
    return a < 1 ? rgb + String(format: "%02X", Int((a * 255).rounded())) : rgb
  }
  public var css: String {
    String(
      format: "rgb(%d %d %d / %.3g)", Int((r * 255).rounded()), Int((g * 255).rounded()),
      Int((b * 255).rounded()), a)
  }
  public var hsl: String {
    let maxV = max(r, g, b)
    let minV = min(r, g, b)
    let delta = maxV - minV
    let l = (maxV + minV) / 2
    var h = 0.0
    if delta > 0 {
      if maxV == r {
        h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
      } else if maxV == g {
        h = (b - r) / delta + 2
      } else {
        h = (r - g) / delta + 4
      }
      h *= 60
      if h < 0 { h += 360 }
    }
    let s = delta == 0 ? 0 : delta / (1 - abs(2 * l - 1))
    return String(format: "hsl(%.2f %.2f%% %.2f%% / %.3g)", h, s * 100, l * 100, a)
  }
  public var luminance: Double {
    func f(_ n: Double) -> Double { n <= 0.04045 ? n / 12.92 : pow((n + 0.055) / 1.055, 2.4) }
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
  }
  public static func parse(_ raw: String) throws -> ColorValue {
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if text.hasPrefix("#") {
      var value = String(text.dropFirst())
      if value.count == 3 || value.count == 4 { value = value.map { "\($0)\($0)" }.joined() }
      try require(value.count == 6 || value.count == 8, L10n.tr("HEX colors require 3, 4, 6, or 8 digits."))
      let bytes = try unhex(value)
      try require(bytes.count == 3 || bytes.count == 4, L10n.tr("HEX colors cannot contain whitespace or omit channels."))
      return ColorValue(
        r: Double(bytes[0]) / 255, g: Double(bytes[1]) / 255, b: Double(bytes[2]) / 255,
        a: bytes.count == 4 ? Double(bytes[3]) / 255 : 1)
    }
    let hsl = text.hasPrefix("hsl(") || text.hasPrefix("hsla(")
    try require(hsl || text.hasPrefix("rgb(") || text.hasPrefix("rgba("), L10n.tr("Supports #HEX, rgb(), and hsl()."))
    guard let start = text.firstIndex(of: "("), text.hasSuffix(")") else {
      throw ToolFailure(L10n.tr("Invalid color function format."))
    }
    let pieces = text[text.index(after: start)..<text.index(before: text.endIndex)].split {
      $0 == "," || $0 == "/" || $0.isWhitespace
    }.map(String.init)
    try require(pieces.count == 3 || pieces.count == 4, L10n.tr("Invalid number of color parameters."))
    var numbers = [Double]()
    for (index, piece) in pieces.enumerated() {
      guard
        let n = Double(
          piece.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "deg", with: "")),
        n.isFinite
      else { throw ToolFailure(L10n.tr("Color parameters must be finite numbers.")) }
      numbers.append(piece.hasSuffix("%") ? n / 100 : index == 3 || hsl ? n : n / 255)
    }
    let alpha = numbers.count == 4 ? numbers[3] : 1
    try require((0...1).contains(alpha), L10n.tr("Opacity must be between 0 and 1."))
    if !hsl {
      try require(numbers.prefix(3).allSatisfy { (0...1).contains($0) }, L10n.tr("RGB values must be 0–255 or 0%–100%."))
      return ColorValue(r: numbers[0], g: numbers[1], b: numbers[2], a: alpha)
    }
    try require(
      pieces[1].hasSuffix("%") && pieces[2].hasSuffix("%") && (0...1).contains(numbers[1])
        && (0...1).contains(numbers[2]), L10n.tr("HSL saturation and lightness must be 0%–100%."))
    let h =
      (numbers[0].truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
      / 60
    let s = numbers[1]
    let l = numbers[2]
    let c = (1 - abs(2 * l - 1)) * s
    let m = l - c / 2
    let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
    let rgb: (Double, Double, Double)
    switch h {
    case 0..<1: rgb = (c, x, 0)
    case 1..<2: rgb = (x, c, 0)
    case 2..<3: rgb = (0, c, x)
    case 3..<4: rgb = (0, x, c)
    case 4..<5: rgb = (x, 0, c)
    default: rgb = (c, 0, x)
    }
    return ColorValue(r: rgb.0 + m, g: rgb.1 + m, b: rgb.2 + m, a: alpha)
  }
}

public func cssPreview(_ css: String, content: String = "DevKit") -> String {
  "<div style='display:grid;place-items:center;min-height:280px;padding:40px'><div style='width:220px;min-height:150px;display:grid;place-items:center;background:#3478f6;color:white;font:600 24px -apple-system;\(htmlEscape(css))'>\(content)</div></div>"
}
