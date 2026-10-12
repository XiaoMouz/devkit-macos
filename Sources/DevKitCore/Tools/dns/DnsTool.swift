import Foundation

public enum DnsTool: ToolModule {
  public struct Options: ToolOptions {
    public var record: String = "A"
    public var resolver: String = ""
    public var port: Int = 53
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "dns", "DNS Lookup", .web, "Run system dig queries for A, AAAA, CNAME, MX, TXT, and NS records manually.", sample: "example.com",
    secondary: "", input: .text, network: true)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "record", L10n.tr("Record Type"), \.record,
        choices: ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "CAA"]),
      .init("resolver", L10n.tr("Resolver IP (empty for system default)"), \.resolver),
      .init("port", L10n.tr("Resolver Port"), \.port, range: 1...65535),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let host = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      !host.hasPrefix("-")
        && host.range(of: "^[A-Za-z0-9_.-]{1,253}$", options: .regularExpression) != nil,
      L10n.tr("Enter an ASCII domain name. Use Punycode for internationalized domains."))
    try require(
      ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "CAA"].contains(options.record), L10n.tr("Invalid record type."))
    try require((1...65535).contains(options.port), L10n.tr("Invalid resolver port."))
    var args = [
      "-p", String(options.port), host, options.record, "+time=3", "+tries=1", "+noall", "+answer",
      "+comments", "+stats",
    ]
    if !options.resolver.isEmpty {
      try require(
        options.resolver.range(of: "^[0-9a-fA-F:.]+$", options: .regularExpression) != nil,
        L10n.tr("The resolver must be an IPv4 or IPv6 address."))
      args.insert("@" + options.resolver, at: 0)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/dig")
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    try require(process.terminationStatus == 0, L10n.tr("DNS query failed or timed out. Check the domain and resolver."))
    return ToolOutput(try utf8(data), note: L10n.tr("The output includes the resolver and query duration. No background polling."))
  }
}
