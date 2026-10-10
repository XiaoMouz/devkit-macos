import Foundation

public enum DnsTool: ToolModule {
  public struct Options: ToolOptions {
    public var record: String = "A"
    public var resolver: String = ""
    public var port: Int = 53
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "dns", "DNS 查询", .web, "调用系统 dig；A / AAAA / CNAME / MX / TXT / NS，手动执行。", sample: "example.com",
    secondary: "", input: .text, network: true)
  public static var fields: [OptionField<Options>] {
    [
      .init(
        "record", "记录类型", \.record,
        choices: ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "CAA"]),
      .init("resolver", "解析器 IP（空为系统）", \.resolver),
      .init("port", "解析器端口", \.port, range: 1...65535),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let host = input.text.trimmingCharacters(in: .whitespacesAndNewlines)
    try require(
      !host.hasPrefix("-")
        && host.range(of: "^[A-Za-z0-9_.-]{1,253}$", options: .regularExpression) != nil,
      "请输入 ASCII 域名；国际化域名请使用 Punycode。")
    try require(
      ["A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "CAA"].contains(options.record), "记录类型无效。")
    try require((1...65535).contains(options.port), "解析器端口无效。")
    var args = [
      "-p", String(options.port), host, options.record, "+time=3", "+tries=1", "+noall", "+answer",
      "+comments", "+stats",
    ]
    if !options.resolver.isEmpty {
      try require(
        options.resolver.range(of: "^[0-9a-fA-F:.]+$", options: .regularExpression) != nil,
        "解析器需要 IPv4 / IPv6 地址。")
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
    try require(process.terminationStatus == 0, "DNS 查询失败或超时，请检查域名与解析器。")
    return ToolOutput(try utf8(data), note: "解析器和查询耗时显示在输出中；无后台轮询。")
  }
}
