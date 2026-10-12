import Foundation

public enum HttpStatusTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "http-status", "HTTP Status Code", .web, "Look up HTTP status meanings locally without sending a request.", sample: "404", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let code = Int(input.text.trimmingCharacters(in: .whitespacesAndNewlines)),
      (100...599).contains(code)
    else { throw ToolFailure(L10n.tr("Enter a status code from 100 to 599.")) }
    let descriptions: [Int: String] = [
      200: L10n.tr("Request succeeded"), 201: L10n.tr("Resource created"), 202: L10n.tr("Accepted for asynchronous processing"), 204: L10n.tr("Succeeded with no response body"), 301: L10n.tr("Permanent redirect"), 302: L10n.tr("Temporary redirect"),
      304: L10n.tr("Cached resource not modified"), 307: L10n.tr("Temporary redirect preserving the method"), 308: L10n.tr("Permanent redirect preserving the method"), 400: L10n.tr("Malformed request"), 401: L10n.tr("Missing or invalid credentials"),
      403: L10n.tr("Access denied"), 404: L10n.tr("Resource not found"), 405: L10n.tr("Method not allowed"), 408: L10n.tr("Request timeout"), 409: L10n.tr("Resource state conflict"), 410: L10n.tr("Resource permanently removed"),
      413: L10n.tr("Request body too large"), 415: L10n.tr("Unsupported media type"), 418: L10n.tr("I’m a teapot (reserved)"), 422: L10n.tr("Content cannot be processed"), 429: L10n.tr("Too many requests"),
      500: L10n.tr("Internal server error"), 502: L10n.tr("Invalid gateway response"), 503: L10n.tr("Service temporarily unavailable"), 504: L10n.tr("Gateway timeout"),
    ]
    let phrase = Self.phrase(code)
    let group = [1: L10n.tr("Informational"), 2: L10n.tr("Success"), 3: L10n.tr("Redirection"), 4: L10n.tr("Client Error"), 5: L10n.tr("Server Error")][code / 100]!
    return ToolOutput(
      "\(code) · \(phrase)\n\(descriptions[code] ?? L10n.tr("The system provides no specific description. Consult the IANA status code registry."))",
      rows: [ResultRow(L10n.tr("Status Code"), String(code)), ResultRow(L10n.tr("Category"), group), ResultRow(L10n.tr("Status"), phrase), ResultRow(L10n.tr("Meaning"), descriptions[code] ?? L10n.tr("No Specific Description"))],
      note: L10n.tr("Protocol reference: RFC 9110 / IANA HTTP Status Code Registry. Common English names come from a local IANA registry snapshot (2026-10-11), independent of generic system error names."))
  }
  public static func phrase(_ code: Int) -> String {
    // IANA HTTP Status Code Registry, checked 2026-10-11.
    let names: [Int: String] = [
      100: "Continue", 101: "Switching Protocols", 102: "Processing", 103: "Early Hints",
      104: "Upload Resumption Supported (temporary until 2026-11-13)",
      200: "OK", 201: "Created", 202: "Accepted", 203: "Non-Authoritative Information",
      204: "No Content", 205: "Reset Content", 206: "Partial Content", 207: "Multi-Status",
      208: "Already Reported", 226: "IM Used", 300: "Multiple Choices", 301: "Moved Permanently",
      302: "Found", 303: "See Other", 304: "Not Modified", 305: "Use Proxy", 306: "Unused",
      307: "Temporary Redirect", 308: "Permanent Redirect", 400: "Bad Request", 401: "Unauthorized",
      402: "Payment Required", 403: "Forbidden", 404: "Not Found", 405: "Method Not Allowed",
      406: "Not Acceptable", 407: "Proxy Authentication Required", 408: "Request Timeout",
      409: "Conflict", 410: "Gone", 411: "Length Required", 412: "Precondition Failed",
      413: "Content Too Large", 414: "URI Too Long", 415: "Unsupported Media Type",
      416: "Range Not Satisfiable", 417: "Expectation Failed", 418: "Unused (I'm a teapot)",
      421: "Misdirected Request", 422: "Unprocessable Content", 423: "Locked", 424: "Failed Dependency",
      425: "Too Early", 426: "Upgrade Required", 428: "Precondition Required", 429: "Too Many Requests",
      431: "Request Header Fields Too Large", 451: "Unavailable For Legal Reasons",
      500: "Internal Server Error", 501: "Not Implemented", 502: "Bad Gateway", 503: "Service Unavailable",
      504: "Gateway Timeout", 505: "HTTP Version Not Supported", 506: "Variant Also Negotiates",
      507: "Insufficient Storage", 508: "Loop Detected", 510: "Not Extended (obsolete)",
      511: "Network Authentication Required",
    ]
    return names[code] ?? "Unassigned"
  }

}
