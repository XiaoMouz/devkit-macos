import Foundation

public enum NetworkSupport {
  public static func message(for error: any Error) -> String {
    let e = error as NSError
    guard e.domain == NSURLErrorDomain else { return error.localizedDescription }
    let text: String
    switch e.code {
    case NSURLErrorTimedOut: text = L10n.tr("Request timed out. Check the address or network and try again.")
    case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed: text = L10n.tr("Could not resolve the host name.")
    case NSURLErrorCannotConnectToHost: text = L10n.tr("Could not connect to the server.")
    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost: text = L10n.tr("The network is unavailable or the connection was interrupted.")
    case NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasBadDate,
      NSURLErrorServerCertificateHasUnknownRoot, NSURLErrorServerCertificateNotYetValid,
      NSURLErrorSecureConnectionFailed: text = L10n.tr("TLS verification failed. Check the certificate and server configuration.")
    case NSURLErrorBadServerResponse: text = L10n.tr("The server returned an invalid response.")
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
      try require(names.count == rows.count && names.allSatisfy { !$0.isEmpty }, L10n.tr("Enter a header name."))
      try require(Set(names.map { $0.lowercased() }).count == names.count, L10n.tr("Header names must be unique (case insensitive)."))
      try require(rows.allSatisfy { $0["value"] != nil }, L10n.tr("Header values must be text."))
      values = Dictionary(uniqueKeysWithValues: rows.map { ($0["name"]!, $0["value"]!) })
    } else if let dictionary = object as? [String: String] { values = dictionary }
    else { throw ToolFailure(L10n.tr("Headers must be a list of names and values or a JSON string dictionary.")) }
    try require(Set(values.keys.map { $0.lowercased() }).count == values.count, L10n.tr("Header names must be unique (case insensitive)."))
    for (key, value) in values {
      try require(
        key.range(of: "^[!#$%&'*+.^_`|~0-9A-Za-z-]+$", options: .regularExpression) != nil
          && !value.contains("\r") && !value.contains("\n"), L10n.tr("Headers contain an invalid name or a newline."))
    }
    return values
  }
}
