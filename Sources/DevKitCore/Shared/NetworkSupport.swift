import Foundation

public enum NetworkSupport {
  public static func session(persistentConnection: Bool = false) -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 15
    config.timeoutIntervalForResource = persistentConnection ? 24 * 60 * 60 : 20
    config.httpCookieStorage = nil
    config.httpShouldSetCookies = false
    config.urlCredentialStorage = nil
    config.urlCache = nil
    return URLSession(configuration: config)
  }
  public static func headers(_ text: String) throws -> [String: String] {
    guard let values = try jsonObject(text) as? [String: String] else {
      throw ToolFailure("请求头需要 JSON 字符串字典。")
    }
    for (key, value) in values {
      try require(
        key.range(of: "^[!#$%&'*+.^_`|~0-9A-Za-z-]+$", options: .regularExpression) != nil
          && !value.contains("\r") && !value.contains("\n"), "请求头包含无效名称或换行。")
    }
    return values
  }
}
