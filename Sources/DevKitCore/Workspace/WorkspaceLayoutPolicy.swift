import Foundation

public enum WorkspaceLayoutPreference: String, CaseIterable, Sendable {
  case automatic, split, focused
}
public enum WorkspaceLayoutMode: Sendable { case split, focused }

/// Content decisions are committed at paste/import, editing boundaries, or execution.
/// Width is resolved per window; a manual preference is never overwritten by content.
public struct WorkspaceLayoutPolicy: Sendable, Equatable {
  public static let minimumSplitWidth = 560.0
  public var preference: WorkspaceLayoutPreference = .automatic
  public private(set) var contentMode: WorkspaceLayoutMode = .split
  public init() {}
  public mutating func evaluate(texts: [String], fileBytes: Int = 0) {
    if fileBytes > 2048 || texts.contains(where: Self.isLarge) {
      contentMode = .focused
    } else if fileBytes <= 1024 && texts.allSatisfy(Self.isSmall) {
      contentMode = .split
    }
  }
  public func mode(width: Double) -> WorkspaceLayoutMode {
    guard width >= Self.minimumSplitWidth else { return .focused }
    switch preference {
    case .automatic: return contentMode
    case .split: return .split
    case .focused: return .focused
    }
  }
  private static func isLarge(_ value: String) -> Bool {
    if value.utf8.count > 2048 { return true }
    let lines = value.split(separator: "\n", omittingEmptySubsequences: false)
    return lines.count > 24 || lines.contains { $0.count > 512 }
  }
  private static func isSmall(_ value: String) -> Bool {
    if value.utf8.count > 1024 { return false }
    let lines = value.split(separator: "\n", omittingEmptySubsequences: false)
    return lines.count <= 12 && lines.allSatisfy { $0.count <= 256 }
  }
}

/// Breaking a multi-megabyte paragraph on the main thread can be quadratic in
/// CoreText. Keep such lines intact and horizontally scroll them instead.
public enum EditorTextPolicy {
  public static let maximumWrappedLineLength = 16_384
  public static func shouldWrap(_ text: String) -> Bool {
    var length = 0
    for unit in text.utf16 {
      switch unit {
      case 10, 13, 0x85, 0x2028, 0x2029: length = 0
      default:
        length += 1
        if length > maximumWrappedLineLength { return false }
      }
    }
    return true
  }
}


/// An editing window into the full document. UTF-16 boundaries never split a
/// surrogate pair; edits replace only the visible range and preserve the rest.
public struct EditorPage: Sendable {
  public static let size = 32_768
  public var range = NSRange(location: 0, length: size)
  public var previousRanges: [NSRange] = []
  public init() {}
  public func resolvedRange(in text: String) -> NSRange {
    let source = text as NSString
    func boundary(_ offset: Int) -> Int {
      let value = min(max(0, offset), source.length)
      if value > 0 && value < source.length {
        let unit = source.character(at: value)
        let previous = source.character(at: value - 1)
        if (0xDC00...0xDFFF).contains(unit) && (0xD800...0xDBFF).contains(previous) { return value - 1 }
      }
      return value
    }
    let start = boundary(range.location)
    let end = boundary(min(source.length, range.location + range.length))
    return NSRange(location: start, length: max(0, end - start))
  }
  public func content(in text: String) -> String { (text as NSString).substring(with: resolvedRange(in: text)) }
  public func hasNext(in text: String) -> Bool { NSMaxRange(resolvedRange(in: text)) < (text as NSString).length }
  public mutating func next(in text: String) {
    let current = resolvedRange(in: text)
    guard NSMaxRange(current) < (text as NSString).length else { return }
    previousRanges.append(current)
    range = NSRange(location: NSMaxRange(current), length: Self.size)
  }
  public mutating func previous() {
    if let prior = previousRanges.popLast() { range = prior }
  }
  public mutating func replace(with value: String, in text: String) -> String {
    let current = resolvedRange(in: text)
    let updated = (text as NSString).replacingCharacters(in: current, with: value)
    range = NSRange(location: current.location, length: (value as NSString).length)
    return updated
  }
}
