import Foundation

/// Describes what people provide and receive, independently of the execution engine.
public struct ToolPresentation: Sendable {
  public enum Control: Sendable, Equatable { case editor, field, color, date, timestamp, pairs, template, request, image, file, generator }
  public var control: Control = .editor
  public var inputTitle = "文本"
  public var placeholder = "输入或粘贴文本…"
  public var secondaryTitle = "修改后的文本"
  public var outputTitle = "结果"
  public var action = "处理"
  public var acceptsBinary = false
  public var exportName = "result.txt"
  public var exportMIME = "text/plain"
  public init(id: String, style: InputStyle, values: [String: String]) {
    let operation = values["operation"] ?? ""
    switch id {
    case "json":
      inputTitle = operation == "diff" ? "原始 JSON" : "JSON 数据"
      placeholder = "输入或导入 JSON…"
      secondaryTitle = operation == "schema" ? "JSON Schema" : "对比 JSON"
      action = ["format":"格式化", "minify":"压缩", "validate":"校验", "tree":"查看路径", "query":"查询", "diff":"对比", "schema":"校验 Schema", "typescript":"生成类型"][operation] ?? "处理"
      outputTitle = operation == "typescript" ? "TypeScript" : operation == "diff" ? "结构差异" : "结果"
      exportName = operation == "typescript" ? "types.ts" : "result.json"
      exportMIME = operation == "typescript" ? "text/plain" : "application/json"
      if ["validate", "tree", "diff", "schema"].contains(operation) { exportName = "report.txt"; exportMIME = "text/plain" }
    case "qr-code":
      control = operation == "scan" ? .image : .editor
      inputTitle = operation == "scan" ? "二维码图片" : "二维码内容"
      placeholder = "输入网址或文字…"; outputTitle = operation == "scan" ? "识别内容" : "二维码"
      action = operation == "scan" ? "识别二维码" : "生成二维码"
    case "data-url":
      control = style == .file ? .image : .editor
      inputTitle = style == .file ? "原始图片" : "图片 Data URL"
      placeholder = "粘贴 data:image/…"; outputTitle = style == .file ? "Data URL" : "图片"
      action = style == .file ? "生成 Data URL" : "还原图片"
    case "image-convert", "image-resize", "image-compress", "image-metadata", "favicon":
      control = .image; inputTitle = "原始图片"; outputTitle = id == "image-metadata" ? "图片信息" : "处理后的图片"
      if id == "image-metadata" { exportName = "metadata.json"; exportMIME = "application/json" }
      action = ["image-convert":"转换格式", "image-resize":"调整尺寸", "image-compress":"压缩图片", "image-metadata":"读取信息", "favicon":"生成图标"][id]!
      if id == "image-metadata", values["strip"] == "true" { action = "移除元数据" }
    case "file-checksum": control = .file; inputTitle = "待校验文件"; action = "计算摘要"
    case "base64":
      inputTitle = operation == "decode" ? "Base64" : "文本或文件"; acceptsBinary = operation == "encode"
      action = operation == "decode" ? "解码" : "编码"
    case "hash", "hmac":
      inputTitle = "文本或文件"; acceptsBinary = true; action = "计算摘要"
    case "pem-certificate":
      inputTitle = "PEM / DER 证书"; placeholder = "粘贴 PEM 证书或导入证书文件…"; acceptsBinary = true; action = "解析证书"
    case "uuid", "nanoid", "random-string": control = .generator; inputTitle = "生成参数"; action = "生成"
    case "ulid":
      control = style == .generator ? .generator : .field
      inputTitle = style == .generator ? "生成参数" : "ULID"; placeholder = "26 位 ULID"
      action = style == .generator ? "生成 ULID" : "解析时间"
    case "mock-data": control = .template; inputTitle = "数据字段"; action = "生成数据"; exportName = "mock.json"; exportMIME = "application/json"
    case "timestamp": control = .timestamp; inputTitle = "时间戳与日期"; action = "转换时间"
    case "date-time": control = .date; inputTitle = "起始日期"; action = operation == "difference" ? "计算时间差" : operation == "add-days" ? "计算日期" : "转换时区"
    case "cron": control = .field; inputTitle = "Cron 表达式"; placeholder = "*/15 9-18 * * 1-5"; action = "预览执行时间"
    case "number-base", "number-format", "unit-convert", "css-unit":
      control = .field; inputTitle = "数值"; placeholder = id == "number-base" ? "255" : "输入数值"
      action = id == "number-format" ? "格式化数字" : "换算"
    case "color", "contrast":
      control = .color; inputTitle = id == "contrast" ? "前景颜色" : "颜色"
      action = id == "contrast" ? "检查对比度" : "转换颜色"
    case "http-status": control = .field; inputTitle = "HTTP 状态码"; placeholder = "200、404、500…"; action = "查询"
    case "mime-types": control = .field; inputTitle = "文件扩展名或 MIME"; placeholder = "png 或 image/png"; action = "查询"
    case "dns": control = .field; inputTitle = "域名"; placeholder = "example.com"; action = "查询 DNS"
    case "url-parser": control = .field; inputTitle = "URL"; placeholder = "https://example.com/path?q=hello"; action = "解析 URL"
    case "query-string":
      control = operation == "build" ? .pairs : .field
      inputTitle = operation == "build" ? "查询参数" : "查询字符串或 URL"
      placeholder = "q=hello&tag=swift 或完整 URL"; action = operation == "build" ? "生成查询字符串" : operation == "sort" ? "排序参数" : "解析参数"
    case "http-client": control = .request; inputTitle = "请求"; action = "发送请求"; outputTitle = "响应正文"
    case "websocket": control = .request; inputTitle = "连接与消息"; action = "连接"
    case "cookie": inputTitle = values["mode"] == "cookie" ? "Cookie 请求头" : "Set-Cookie 响应头"; action = "解析 Cookie"
    case "curl-convert": inputTitle = "cURL 命令"; placeholder = "粘贴 cURL 命令…"; action = "转换请求"
    case "jwt": inputTitle = "JWT 令牌"; placeholder = "粘贴 Header.Payload.Signature…"; action = "解析令牌"
    case "regex": inputTitle = "测试文本"; action = operation == "replace" ? "预览替换" : "匹配"
    case "text-diff": inputTitle = "原始文本"; action = "对比文本"; outputTitle = "文本差异"
    case "text-case": inputTitle = "名称或文本"; action = "转换命名"
    case "text-lines": inputTitle = "文本行"; action = "处理文本行"
    case "text-replace": inputTitle = "待替换文本"; action = "替换"
    case "text-stats": inputTitle = "待统计文本"; action = "统计"
    case "url-codec": inputTitle = operation == "decode" ? "URL 编码内容" : "URL 或参数"; action = operation == "decode" ? "解码" : "编码"
    case "markdown": inputTitle = "Markdown"; action = "预览"; outputTitle = "预览 / HTML"; exportName = "preview.html"; exportMIME = "text/html"
    case "svg": inputTitle = "SVG 源码"; action = "优化并预览"; outputTitle = "预览 / SVG"; exportName = "result.svg"; exportMIME = "image/svg+xml"
    case "code-format", "code-minify":
      inputTitle = "源代码"; action = id == "code-format" ? "格式化代码" : "压缩代码"
      let ext = ["javascript":"js", "typescript":"ts", "html":"html", "css":"css", "sql":"sql"][values["language"] ?? ""] ?? "txt"
      exportName = "result." + ext
    default: break
    }
    if id == "mock-data", values["format"] == "csv" { exportName = "mock.csv"; exportMIME = "text/csv" }
  }
  public var isForm: Bool {
    switch control {
    case .field, .color, .date, .timestamp, .pairs, .template, .generator: true
    default: false
    }
  }
  public var isImage: Bool { control == .image }
}
