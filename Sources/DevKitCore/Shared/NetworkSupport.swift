import Foundation

public enum NetworkSupport {
  public static func message(for error: any Error) -> String {
    let e = error as NSError
    guard e.domain == NSURLErrorDomain else { return error.localizedDescription }
    let text: String
    switch e.code {
    case NSURLErrorTimedOut: text = "请求超时，请检查地址或网络后重试。"
    case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed: text = "无法解析主机名。"
    case NSURLErrorCannotConnectToHost: text = "无法连接服务器。"
    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost: text = "网络不可用或连接已中断。"
    case NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasBadDate,
      NSURLErrorServerCertificateHasUnknownRoot, NSURLErrorServerCertificateNotYetValid,
      NSURLErrorSecureConnectionFailed: text = "TLS 验证失败，请检查证书与服务器配置。"
    case NSURLErrorBadServerResponse: text = "服务器返回无效响应。"
    default: text = error.localizedDescription
    }
    return "\(text)（\(e.code)）"
  }

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
    let object = try jsonObject(text)
    let values: [String: String]
    if let rows = object as? [[String: String]] {
      let names = rows.compactMap { $0["name"] }
      try require(names.count == rows.count && names.allSatisfy { !$0.isEmpty }, "请填写请求头名称。")
      try require(Set(names.map { $0.lowercased() }).count == names.count, "请求头名称不能重复（不区分大小写）。")
      try require(rows.allSatisfy { $0["value"] != nil }, "请求头值必须是文本。")
      values = Dictionary(uniqueKeysWithValues: rows.map { ($0["name"]!, $0["value"]!) })
    } else if let dictionary = object as? [String: String] { values = dictionary }
    else { throw ToolFailure("请求头需要名称和值的列表或 JSON 字符串字典。") }
    try require(Set(values.keys.map { $0.lowercased() }).count == values.count, "请求头名称不能重复（不区分大小写）。")
    for (key, value) in values {
      try require(
        key.range(of: "^[!#$%&'*+.^_`|~0-9A-Za-z-]+$", options: .regularExpression) != nil
          && !value.contains("\r") && !value.contains("\n"), "请求头包含无效名称或换行。")
    }
    return values
  }
}
