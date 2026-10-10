import Foundation

public enum Base64Codec {
  public static func decode(_ input: String, urlSafe: Bool = false) throws -> Data {
    var value = input.unicodeScalars.filter { ![9, 10, 13, 32].contains($0.value) }.map(String.init)
      .joined()
    let alphabet =
      urlSafe
      ? "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="
      : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    try require(value.allSatisfy { alphabet.contains($0) }, "Base64 包含非法字符，检查字母表设置。")
    let unpadded = String(value.prefix { $0 != "=" })
    let pad = value.count - unpadded.count
    try require(
      pad <= 2 && value.dropFirst(unpadded.count).allSatisfy { $0 == "=" }, "Base64 填充位置或数量无效。")
    try require(unpadded.count % 4 != 1 && (pad == 0 || value.count % 4 == 0), "Base64 长度或填充无效。")
    if urlSafe {
      value = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(
        of: "_", with: "/")
    }
    if pad == 0 { value += String(repeating: "=", count: (4 - value.count % 4) % 4) }
    guard let data = Data(base64Encoded: value) else { throw ToolFailure("Base64 数据无效。") }
    // Reject nonzero unused bits instead of silently accepting ambiguous encodings.
    try require(data.base64EncodedString() == value, "Base64 尾部填充位无效。")
    return data
  }
}

public struct Base64Command: Sendable {
  public let operation: String
  public let payload: String
  public static func parse(_ command: String) throws -> Base64Command {
    try require(command.utf8.count <= 16 * 1024, "Spotlight 输入上限为 16 KiB，请在工具箱处理。")
    let value = command.hasPrefix("base64 ") ? String(command.dropFirst(7)) : command
    guard let space = value.firstIndex(of: " ") else {
      throw ToolFailure("用法：encode hello 或 decode aGVsbG8=；空文本用 encode --。")
    }
    let operation = String(value[..<space])
    try require(["encode", "decode"].contains(operation), "操作必须是 encode 或 decode。")
    var payload = String(value[value.index(after: space)...])
    try require(!payload.isEmpty, "缺少文本；编码空文本请使用 encode --。")
    if payload == "--" {
      payload = ""
    } else if payload.hasPrefix("-- ") {
      payload = String(payload.dropFirst(3))
    }
    return Base64Command(operation: operation, payload: payload)
  }
}
