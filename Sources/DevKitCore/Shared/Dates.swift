import Foundation

public enum Dates {
  public static let timeZoneIdentifiers = Array(Set(TimeZone.knownTimeZoneIdentifiers + ["UTC", TimeZone.current.identifier])).sorted()
  public static let supportedRange = Date(timeIntervalSince1970: -62_135_596_800)...Date(timeIntervalSince1970: 253_402_300_799.999)

  /// ISO is accepted for imported data; ordinary dates are interpreted in the chosen zone.
  public static func parse(_ text: String, timeZone: TimeZone = .current) -> Date? {
    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.range(of: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})$"#, options: .regularExpression) != nil {
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = f.date(from: value) { return date }
      f.formatOptions = [.withInternetDateTime]
      return f.date(from: value)
    }
    let pattern = #"^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?: (\d{1,2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3}))?)?)?$"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) else { return nil }
    func part(_ index: Int) -> String? { Range(match.range(at: index), in: value).map { String(value[$0]) } }
    let year = Int(part(1)!)!, month = Int(part(2)!)!, day = Int(part(3)!)!
    let hour = Int(part(4) ?? "0")!, minute = Int(part(5) ?? "0")!, second = Int(part(6) ?? "0")!
    guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day),
      (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second) else { return nil }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
    guard let date = calendar.date(from: components) else { return nil }
    let actual = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    // Reject invalid dates and daylight-saving gaps instead of silently normalizing them.
    guard actual == components else { return nil }
    let fraction = Double("0." + (part(7) ?? "0")) ?? 0
    return date.addingTimeInterval(fraction)
  }
  public static func display(_ date: Date, timeZone: TimeZone = .current, milliseconds: Bool = false) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = Calendar(identifier: .gregorian)
    f.timeZone = timeZone
    f.dateFormat = milliseconds ? "yyyy-MM-dd HH:mm:ss.SSS" : "yyyy-MM-dd HH:mm:ss"
    return f.string(from: date)
  }
  public static func zoneLabel(_ zone: TimeZone, at date: Date = Date()) -> String {
    if ["GMT", "UTC", "Etc/UTC", "Etc/GMT"].contains(zone.identifier) { return "UTC" }
    return "\(zone.identifier) · \(offsetLabel(zone, at: date))"
  }
  public static func offsetLabel(_ zone: TimeZone, at date: Date) -> String {
    let seconds = zone.secondsFromGMT(for: date)
    let sign = seconds < 0 ? "−" : "+"
    let offset = seconds == 0 ? "UTC" : String(format: "UTC%@%02d:%02d", sign, abs(seconds) / 3600, abs(seconds) % 3600 / 60)
    return offset
  }
  /// Internal interchange only. User-facing dates use display(_:timeZone:milliseconds:).
  public static func iso(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: date)
  }
  public static func timestamp(_ date: Date, milliseconds: Bool) -> String {
    let value = milliseconds ? date.timeIntervalSince1970 * 1000 : date.timeIntervalSince1970
    if milliseconds { return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value) }
    return String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), value)
      .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
  }
}
