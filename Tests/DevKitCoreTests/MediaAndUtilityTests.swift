import CoreGraphics
import Foundation
import Testing

@testable import DevKitCore

@Suite("Media and utility behavior") struct MediaAndUtilityTests {
  @Test func compressionRoundTripsAndRejectsTrailingBytes() throws {
    let bytes = Data((0..<256).map(UInt8.init)) + Data("hello 你好".utf8)
    for format in ["gzip", "zlib", "deflate"] {
      let compressed = try ZlibCodec.process(bytes, decompress: false, format: format)
      #expect(try ZlibCodec.process(compressed, decompress: true, format: format) == bytes)
      #expect(throws: (any Error).self) {
        try ZlibCodec.process(compressed.dropLast(2), decompress: true, format: format)
      }
      #expect(throws: (any Error).self) {
        try ZlibCodec.process(compressed + Data([0]), decompress: true, format: format)
      }
    }
  }
  @Test func base64BinaryAndDataURL() async throws {
    var options = DataUrlTool.Options()
    options.operation = "decode"
    let result = try await DataUrlTool.execute(
      .init(text: "data:application/octet-stream,%FF%00"), options: options)
    #expect(result.artifacts.first?.data == Data([255, 0]))
    #expect(result.text == "ff00")
  }
  @Test func colorsAndContrast() async throws {
    #expect(try ColorValue.parse("hsl(120 100% 50%)").hexValue == "#00FF00")
    #expect(try ColorValue.parse("#abc8").hexValue == "#AABBCC88")
    var options = ContrastTool.Options()
    options.background = "#000000"
    let result = try await ContrastTool.execute(.init(text: "#ffffff"), options: options)
    #expect(result.rows.first?.value == "21.00:1")
    #expect(throws: (any Error).self) { try ColorValue.parse("rgb(999,0,0)") }
    #expect(throws: (any Error).self) { try ColorValue.parse("#    aabb") }
  }
  @Test func decimalRoundingAndBigInteger() async throws {
    #expect(
      try await NumberFormatTool.execute(.init(text: "1234567.895"), options: .init()).text
        == "1,234,567.90")
    #expect(
      try await NumberBaseTool.execute(.init(text: "18446744073709551616"), options: .init()).text
        == "10000000000000000")
  }
  @Test func URLFormRulesAndDuplicateKeys() async throws {
    var options = UrlCodecTool.Options()
    options.mode = "form"
    #expect(
      try await UrlCodecTool.execute(.init(text: "a+b c"), options: options).text == "a%2Bb+c")
    #expect(try await UrlCodecTool.execute(.init(text: "*~"), options: options).text == "*%7E")
    options.operation = "decode"
    #expect(
      try await UrlCodecTool.execute(.init(text: "a%2Bb+c"), options: options).text == "a+b c")
    let result = try await QueryStringTool.execute(
      .init(text: "tag=a&tag=b&flag&empty="), options: .init())
    #expect(result.rows.count == 4)
    #expect(result.rows.prefix(2).map(\.value) == ["a", "b"])
  }
  @Test func hmacStandardVector() async throws {
    var options = HmacTool.Options()
    options.key = "key"
    #expect(
      try await HmacTool.execute(
        .init(text: "The quick brown fox jumps over the lazy dog"), options: options
      ).text == "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8")
  }
  @Test func generatedIDs() async throws {
    var options = UuidTool.Options()
    options.version = "v7"
    options.count = 3
    let result = try await UuidTool.execute(.init(), options: options)
    #expect(
      result.rows.allSatisfy { UUID(uuidString: $0.value) != nil && Array($0.value)[14] == "7" })
    let ulids = try await UlidTool.execute(.init(), options: .init())
    var parse = UlidTool.Options()
    parse.operation = "parse"
    let timestamp = try await UlidTool.execute(.init(text: ulids.rows[0].value), options: parse)
    let date = try #require(Dates.parse(timestamp.text))
    #expect(abs(date.timeIntervalSinceNow) < 5)
  }
  @Test func imagesAndFavicon() async throws {
    let color = CGColorSpaceCreateDeviceRGB()
    let context = try #require(
      CGContext(
        data: nil, width: 64, height: 32, bitsPerComponent: 8, bytesPerRow: 64 * 4, space: color,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 64, height: 32))
    let image = try #require(context.makeImage())
    let png = try ImageCodec.encode(image)
    let input = ToolInput(file: png.data, fileName: "fixture.png")
    let resized = try await ImageResizeTool.execute(input, options: .init())
    let out = try ImageCodec.decode(.init(file: resized.artifacts[0].data))
    #expect(out.width == 800 && out.height == 600)
    #expect(try await ImageConvertTool.execute(input, options: .init()).artifacts.count == 1)
    #expect(
      try await ImageCompressTool.execute(input, options: .init()).artifacts[0].mime == "image/jpeg"
    )
    #expect(
      try await ImageMetadataTool.execute(input, options: .init()).text.contains("PixelWidth"))
    let favicon = try await FaviconTool.execute(input, options: .init())
    #expect(favicon.artifacts.count == 7)
    #expect(favicon.artifacts.last?.data.prefix(6) == Data([0, 0, 1, 0, 3, 0]))
  }
  @Test func QRRoundTrip() async throws {
    let result = try await QrCodeTool.execute(.init(text: "DevKit 你好"), options: .init())
    var scan = QrCodeTool.Options()
    scan.operation = "scan"
    let decoded = try await QrCodeTool.execute(.init(file: result.artifacts[0].data), options: scan)
    #expect(decoded.text == "DevKit 你好")
  }
  @Test func allGeneratorDefaults() async throws {
    for tool in ToolRegistry.all where tool.metadata.inputStyle == .generator {
      let result = try await run(tool)
      #expect(!result.text.isEmpty)
    }
  }
  private func run<T: ToolModule>(_ type: T.Type) async throws -> ToolOutput {
    try await T.execute(.init(), options: .init())
  }
}
