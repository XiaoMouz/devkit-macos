import Foundation
import Security

public func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
  if !condition() { throw ToolFailure(message) }
}
public func utf8(_ data: Data) throws -> String {
  guard let value = String(data: data, encoding: .utf8) else {
    throw ToolFailure(L10n.tr("The result is not valid UTF-8 text. Export it as a binary file."), code: "encoding")
  }
  return value
}
public func prettyJSON(_ object: Any) throws -> String {
  try utf8(
    JSONSerialization.data(
      withJSONObject: object,
      options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]))
}
public func jsonObject(_ text: String) throws -> Any {
  do {
    return try JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed])
  } catch { throw ToolFailure(L10n.tr("Invalid JSON: \(error.localizedDescription)")) }
}
public func randomBytes(_ count: Int) throws -> [UInt8] {
  try require((0...1_000_000).contains(count), L10n.tr("Random data length is out of range."))
  var bytes = [UInt8](repeating: 0, count: count)
  if count > 0, SecRandomCopyBytes(kSecRandomDefault, count, &bytes) != errSecSuccess {
    throw ToolFailure(L10n.tr("The system’s secure random source is unavailable."), code: "random")
  }
  return bytes
}
public func randomText(length: Int, alphabet: String) throws -> String {
  let chars = Array(Set(alphabet)).sorted()
  try require(
    !chars.isEmpty && chars.count <= 65_536 && (0...100_000).contains(length), L10n.tr("Invalid character set or length."))
  var result = [Character]()
  result.reserveCapacity(length)
  // Uniform rejection sampling, including custom Unicode alphabets.
  let limit = 65_536 - 65_536 % chars.count
  while result.count < length {
    let bytes = try randomBytes(max(128, min((length - result.count) * 2, 65_536)))
    for i in stride(from: 0, to: bytes.count - 1, by: 2) {
      let n = Int(bytes[i]) << 8 | Int(bytes[i + 1])
      if n < limit {
        result.append(chars[n % chars.count])
        if result.count == length { break }
      }
    }
  }
  return String(result)
}
public func hex(_ data: some Sequence<UInt8>) -> String {
  data.map { String(format: "%02x", $0) }.joined()
}
public func unhex(_ value: String) throws -> Data {
  let s = value.filter { !$0.isWhitespace }
  try require(s.count % 2 == 0, L10n.tr("Hexadecimal bytes must have two digits each."))
  var data = Data()
  var i = s.startIndex
  while i < s.endIndex {
    let end = s.index(i, offsetBy: 2)
    guard let byte = UInt8(s[i..<end], radix: 16) else { throw ToolFailure(L10n.tr("Contains invalid hexadecimal characters.")) }
    data.append(byte)
    i = end
  }
  return data
}
public func htmlEscape(_ value: String) -> String {
  value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    .replacingOccurrences(of: "'", with: "&#39;")
}
public func textOrArtifact(
  _ data: Data, name: String = "result.bin", mime: String = "application/octet-stream"
) -> ToolOutput {
  if let text = String(data: data, encoding: .utf8) {
    return ToolOutput(text, artifacts: [Artifact(name, mime, data)])
  }
  return ToolOutput(
    hex(data.prefix(4096)), artifacts: [Artifact(name, mime, data)],
    note: L10n.tr("Binary result · \(data.count) bytes. The preview shows the first 4,096 bytes as Hex; export includes all data."))
}
