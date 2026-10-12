import Foundation

public enum Base64Codec {
  public static func decode(_ input: String, urlSafe: Bool = false) throws -> Data {
    var value = input.unicodeScalars.filter { ![9, 10, 13, 32].contains($0.value) }.map(String.init)
      .joined()
    let alphabet =
      urlSafe
      ? "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="
      : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    try require(value.allSatisfy { alphabet.contains($0) }, L10n.tr("Base64 contains invalid characters. Check the alphabet setting."))
    let unpadded = String(value.prefix { $0 != "=" })
    let pad = value.count - unpadded.count
    try require(
      pad <= 2 && value.dropFirst(unpadded.count).allSatisfy { $0 == "=" }, L10n.tr("Invalid Base64 padding position or length."))
    try require(unpadded.count % 4 != 1 && (pad == 0 || value.count % 4 == 0), L10n.tr("Invalid Base64 length or padding."))
    if urlSafe {
      value = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(
        of: "_", with: "/")
    }
    if pad == 0 { value += String(repeating: "=", count: (4 - value.count % 4) % 4) }
    guard let data = Data(base64Encoded: value) else { throw ToolFailure(L10n.tr("Invalid Base64 data.")) }
    // Reject nonzero unused bits instead of silently accepting ambiguous encodings.
    try require(data.base64EncodedString() == value, L10n.tr("Invalid Base64 trailing padding bits."))
    return data
  }
}

public struct Base64Command: Sendable {
  public let operation: String
  public let payload: String
  public static func parse(_ command: String) throws -> Base64Command {
    try require(command.utf8.count <= 16 * 1024, L10n.tr("Spotlight input is limited to 16 KiB. Use the main app."))
    let value = command.hasPrefix("base64 ") ? String(command.dropFirst(7)) : command
    guard let space = value.firstIndex(of: " ") else {
      throw ToolFailure(L10n.tr("Usage: encode hello or decode aGVsbG8=. For empty text, use encode --."))
    }
    let operation = String(value[..<space])
    try require(["encode", "decode"].contains(operation), L10n.tr("Operation must be encode or decode."))
    var payload = String(value[value.index(after: space)...])
    try require(!payload.isEmpty, L10n.tr("Missing text. To encode empty text, use encode --."))
    if payload == "--" {
      payload = ""
    } else if payload.hasPrefix("-- ") {
      payload = String(payload.dropFirst(3))
    }
    return Base64Command(operation: operation, payload: payload)
  }
}
