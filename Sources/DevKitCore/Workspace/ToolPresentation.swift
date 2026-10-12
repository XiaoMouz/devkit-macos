import Foundation

/// Describes what people provide and receive, independently of the execution engine.
public struct ToolPresentation: Sendable {
  public enum Control: Sendable, Equatable { case editor, field, color, date, timestamp, pairs, template, request, image, file, generator }
  public var control: Control = .editor
  public var inputTitle = L10n.tr("Text")
  public var placeholder = L10n.tr("Enter or paste text…")
  public var secondaryTitle = L10n.tr("Modified Text")
  public var outputTitle = L10n.tr("Result")
  public var action = L10n.tr("Process")
  public var acceptsBinary = false
  public var exportName = "result.txt"
  public var exportMIME = "text/plain"
  public init(id: String, style: InputStyle, values: [String: String]) {
    let operation = values["operation"] ?? ""
    switch id {
    case "json":
      inputTitle = operation == "diff" ? L10n.tr("Original JSON") : L10n.tr("JSON Data")
      placeholder = L10n.tr("Enter or import JSON…")
      secondaryTitle = operation == "schema" ? "JSON Schema" : L10n.tr("Comparison JSON")
      action = ["format":L10n.tr("Format"), "minify":L10n.tr("Minify"), "validate":L10n.tr("Validate"), "tree":L10n.tr("View Paths"), "query":L10n.tr("Query"), "diff":L10n.tr("Compare"), "schema":L10n.tr("Validate Schema"), "typescript":L10n.tr("Generate Types")][operation] ?? L10n.tr("Process")
      outputTitle = operation == "typescript" ? "TypeScript" : operation == "diff" ? L10n.tr("Structural Differences") : L10n.tr("Result")
      exportName = operation == "typescript" ? "types.ts" : "result.json"
      exportMIME = operation == "typescript" ? "text/plain" : "application/json"
      if ["validate", "tree", "diff", "schema"].contains(operation) { exportName = "report.txt"; exportMIME = "text/plain" }
    case "qr-code":
      control = operation == "scan" ? .image : .editor
      inputTitle = operation == "scan" ? L10n.tr("QR Image") : L10n.tr("QR Content")
      placeholder = L10n.tr("Enter a URL or text…"); outputTitle = operation == "scan" ? L10n.tr("Recognized Content") : L10n.tr("QR Code")
      action = operation == "scan" ? L10n.tr("Scan QR Code") : L10n.tr("Generate QR Code")
    case "data-url":
      control = style == .file ? .image : .editor
      inputTitle = style == .file ? L10n.tr("Original Image") : L10n.tr("Image Data URL")
      placeholder = L10n.tr("Paste data:image/…"); outputTitle = style == .file ? "Data URL" : L10n.tr("Image")
      action = style == .file ? L10n.tr("Generate Data URL") : L10n.tr("Restore Image")
    case "image-convert", "image-resize", "image-compress", "image-metadata", "favicon":
      control = .image; inputTitle = L10n.tr("Original Image"); outputTitle = id == "image-metadata" ? L10n.tr("Image Information") : L10n.tr("Processed Image")
      if id == "image-metadata" { exportName = "metadata.json"; exportMIME = "application/json" }
      action = ["image-convert":L10n.tr("Convert Format"), "image-resize":L10n.tr("Resize"), "image-compress":L10n.tr("Compress Image"), "image-metadata":L10n.tr("Read Information"), "favicon":L10n.tr("Generate Icons")][id]!
      if id == "image-metadata", values["strip"] == "true" { action = L10n.tr("Remove Metadata") }
    case "file-checksum":
      control = .file; inputTitle = L10n.tr("File to Verify")
      action = (values["expected"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.tr("Calculate Digest") : L10n.tr("Verify File")
    case "base64":
      inputTitle = operation == "decode" ? "Base64" : L10n.tr("Text")
      action = operation == "decode" ? L10n.tr("Decode") : L10n.tr("Encode")
    case "hash", "hmac":
      inputTitle = L10n.tr("Text or File"); acceptsBinary = true; action = L10n.tr("Calculate Digest")
    case "pem-certificate":
      inputTitle = L10n.tr("PEM / DER Certificate"); placeholder = L10n.tr("Paste a PEM certificate or import a certificate file…"); acceptsBinary = true; action = L10n.tr("Parse Certificate")
    case "uuid", "nanoid", "random-string": control = .generator; inputTitle = L10n.tr("Generation Parameters"); action = L10n.tr("Generate")
    case "ulid":
      control = style == .generator ? .generator : .field
      inputTitle = style == .generator ? L10n.tr("Generation Parameters") : "ULID"; placeholder = L10n.tr("26-character ULID")
      action = style == .generator ? L10n.tr("Generate ULID") : L10n.tr("Parse Time")
    case "mock-data": control = .template; inputTitle = L10n.tr("Data Fields"); action = L10n.tr("Generate Data"); exportName = "mock.json"; exportMIME = "application/json"
    case "timestamp": control = .timestamp; inputTitle = L10n.tr("Timestamp and Date"); action = L10n.tr("Converted Time")
    case "date-time": control = .date; inputTitle = L10n.tr("Start Date"); action = operation == "difference" ? L10n.tr("Calculate Difference") : operation == "add-days" ? L10n.tr("Calculate Date") : L10n.tr("Convert Time Zone")
    case "cron": control = .field; inputTitle = L10n.tr("Cron Expression"); placeholder = "*/15 9-18 * * 1-5"; action = L10n.tr("Preview Run Times")
    case "number-base", "number-format", "unit-convert", "css-unit":
      control = .field; inputTitle = L10n.tr("Numeric Value"); placeholder = id == "number-base" ? "255" : L10n.tr("Enter a number")
      action = id == "number-format" ? L10n.tr("Format Number") : L10n.tr("Convert")
    case "color", "contrast":
      control = .color; inputTitle = id == "contrast" ? L10n.tr("Foreground Color") : L10n.tr("Color")
      action = id == "contrast" ? L10n.tr("Check Contrast") : L10n.tr("Convert Color")
    case "http-status": control = .field; inputTitle = L10n.tr("HTTP Status Code"); placeholder = "200、404、500…"; action = L10n.tr("Query")
    case "mime-types": control = .field; inputTitle = L10n.tr("File Extension or MIME"); placeholder = L10n.tr("png or image/png"); action = L10n.tr("Query")
    case "dns": control = .field; inputTitle = L10n.tr("Domain"); placeholder = "example.com"; action = L10n.tr("Look Up DNS")
    case "url-parser": control = .field; inputTitle = "URL"; placeholder = "https://example.com/path?q=hello"; action = L10n.tr("Parse URL")
    case "query-string":
      control = operation == "build" ? .pairs : .field
      inputTitle = operation == "build" ? L10n.tr("Query Parameters") : L10n.tr("Query String or URL")
      placeholder = L10n.tr("q=hello&tag=swift or a full URL"); action = operation == "build" ? L10n.tr("Build Query String") : operation == "sort" ? L10n.tr("Sort Parameters") : L10n.tr("Parse Parameters")
    case "http-client": control = .request; inputTitle = L10n.tr("Request"); action = L10n.tr("Send Request"); outputTitle = L10n.tr("Response Body")
    case "websocket": control = .request; inputTitle = L10n.tr("Connection and Messages"); action = L10n.tr("Connect")
    case "cookie": inputTitle = values["mode"] == "cookie" ? L10n.tr("Cookie Request Header") : L10n.tr("Set-Cookie Response Header"); action = L10n.tr("Parse Cookie")
    case "curl-convert": inputTitle = L10n.tr("cURL Command"); placeholder = L10n.tr("Paste a cURL command…"); action = L10n.tr("Convert Request")
    case "jwt": inputTitle = L10n.tr("JWT Token"); placeholder = L10n.tr("Paste Header.Payload.Signature…"); action = values["verify"] == "true" ? L10n.tr("Verify Signature") : L10n.tr("Parse Token")
    case "regex": inputTitle = L10n.tr("Test Text"); action = operation == "replace" ? L10n.tr("Preview Replacement") : L10n.tr("Match")
    case "text-diff": inputTitle = L10n.tr("Original Text"); action = L10n.tr("Compare Text"); outputTitle = L10n.tr("Text Differences")
    case "text-case": inputTitle = L10n.tr("Name or Text"); action = L10n.tr("Convert Naming")
    case "text-lines": inputTitle = L10n.tr("Text Lines"); action = L10n.tr("Process Lines")
    case "text-replace": inputTitle = L10n.tr("Text to Replace"); action = L10n.tr("Replace")
    case "text-stats": inputTitle = L10n.tr("Text to Count"); action = L10n.tr("Analyze Text")
    case "url-codec": inputTitle = operation == "decode" ? L10n.tr("URL-Encoded Content") : L10n.tr("URL or Parameters"); action = operation == "decode" ? L10n.tr("Decode") : L10n.tr("Encode")
    case "markdown": inputTitle = "Markdown"; action = L10n.tr("Preview"); outputTitle = L10n.tr("Preview / HTML"); exportName = "preview.html"; exportMIME = "text/html"
    case "svg": inputTitle = L10n.tr("SVG Source"); action = L10n.tr("Optimize and Preview"); outputTitle = L10n.tr("Preview / SVG"); exportName = "result.svg"; exportMIME = "image/svg+xml"
    case "code-format", "code-minify":
      inputTitle = L10n.tr("Source Code"); action = id == "code-format" ? L10n.tr("Format Code") : L10n.tr("Minify Code")
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
