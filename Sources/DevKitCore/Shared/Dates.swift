import Foundation

public enum Dates {
  public static let timeZoneIdentifiers = Array(Set(TimeZone.knownTimeZoneIdentifiers + ["UTC", TimeZone.current.identifier])).sorted()
  public static let supportedRange = Date(timeIntervalSince1970: -62_135_596_800)...Date(timeIntervalSince1970: 253_402_300_799.999)

  /// ISO is accepted for imported data; ordinary dates are interpreted in the chosen zone.
  public static func parse(_ text: String, timeZone: TimeZone = .current) -> Date? {
    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let isoPattern = #"^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:?\d{2})$"#
    if let regex = try? NSRegularExpression(pattern: isoPattern),
      let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) {
      func capture(_ index: Int) -> String? { Range(match.range(at: index), in: value).map { String(value[$0]) } }
      let suffix = capture(4)!
      var offset = 0
      if suffix != "Z" {
        let digits = suffix.dropFirst().replacingOccurrences(of: ":", with: "")
        guard let hours = Int(digits.prefix(2)), let minutes = Int(digits.suffix(2)), hours <= 23, minutes < 60 else { return nil }
        offset = (hours * 3600 + minutes * 60) * (suffix.hasPrefix("-") ? -1 : 1)
      }
      guard let zone = TimeZone(secondsFromGMT: offset),
        let date = parse(capture(1)! + " " + capture(2)!, timeZone: zone) else { return nil }
      return date.addingTimeInterval(Double("0." + (capture(3) ?? "0")) ?? 0)
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
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = calendar
    f.gregorianStartDate = Date(timeIntervalSince1970: -63_000_000_000)
    f.timeZone = timeZone
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    f.isLenient = false
    let canonical = String(format: "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)
    // Modern dates retain Calendar's first occurrence during a DST overlap.
    guard let date = year >= 1583 ? calendar.date(from: components) : f.date(from: canonical),
      display(date, timeZone: timeZone) == canonical else { return nil }
    let fraction = Double("0." + (part(7) ?? "0")) ?? 0
    return date.addingTimeInterval(fraction)
  }
  public static func display(_ date: Date, timeZone: TimeZone = .current, milliseconds: Bool = false) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.calendar = Calendar(identifier: .gregorian)
    // Use the proleptic Gregorian calendar over the entire advertised range.
    f.gregorianStartDate = Date(timeIntervalSince1970: -63_000_000_000)
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
    display(date, timeZone: TimeZone(secondsFromGMT: 0)!, milliseconds: true)
      .replacingOccurrences(of: " ", with: "T") + "Z"
  }
  public static func timestamp(_ date: Date, milliseconds: Bool) -> String {
    let value = milliseconds ? date.timeIntervalSince1970 * 1000 : date.timeIntervalSince1970
    if milliseconds { return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value) }
    return String(format: "%.3f", locale: Locale(identifier: "en_US_POSIX"), value)
      .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
  }
}
