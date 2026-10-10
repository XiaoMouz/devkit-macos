import Foundation

public enum HttpStatusTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "http-status", "HTTP 状态码", .web, "本地查询 HTTP 状态含义；不发送请求。", sample: "404", secondary: "",
    input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let code = Int(input.text.trimmingCharacters(in: .whitespacesAndNewlines)),
      (100...599).contains(code)
    else { throw ToolFailure("请输入 100–599 的状态码。") }
    let descriptions: [Int: String] = [
      200: "请求成功", 201: "资源已创建", 202: "已接受异步处理", 204: "成功且无响应正文", 301: "永久重定向", 302: "临时重定向",
      304: "缓存未修改", 307: "临时重定向，保持方法", 308: "永久重定向，保持方法", 400: "请求格式有误", 401: "缺少或无效的身份凭证",
      403: "拒绝访问", 404: "未找到资源", 405: "方法不允许", 408: "请求超时", 409: "资源状态冲突", 410: "资源已永久移除",
      413: "请求体过大", 415: "不支持的媒体类型", 418: "I'm a teapot（保留）", 422: "内容无法处理", 429: "请求过多",
      500: "服务器内部错误", 502: "网关响应无效", 503: "服务暂不可用", 504: "网关超时",
    ]
    let phrase = HTTPURLResponse.localizedString(forStatusCode: code)
    let group = [1: "信息响应", 2: "成功", 3: "重定向", 4: "客户端错误", 5: "服务端错误"][code / 100]!
    return ToolOutput(
      "\(code) · \(phrase)\n\(descriptions[code] ?? "系统未提供专门说明，请查阅 IANA 状态码注册表。")",
      rows: [ResultRow("状态码", String(code)), ResultRow("类别", group), ResultRow("状态", phrase), ResultRow("含义", descriptions[code] ?? "未收录专门说明")],
      note: "协议参考：RFC 9110 / IANA HTTP Status Code Registry；名称由当前系统提供。")
  }
}
