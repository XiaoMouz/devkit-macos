import CoreGraphics
import Foundation
import Testing

@testable import DevKitCore

@Suite("Image Data URL conversion") struct DataUrlTests {
  private func fixture(_ format: String = "png") throws -> Artifact {
    let context = try #require(CGContext(
      data: nil, width: 8, height: 4, bitsPerComponent: 8, bytesPerRow: 32,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.5))
    context.fill(CGRect(x: 0, y: 0, width: 8, height: 4))
    return try ImageCodec.encode(#require(context.makeImage()), format: format)
  }

  @Test(arguments: ["png", "jpeg", "heic"])
  func roundTripPreservesOriginalImageBytes(_ format: String) async throws {
    let original = try fixture(format)
    // MIME detection must use the bytes, not the selected filename.
    let encoded = try await DataUrlTool.execute(
      .init(file: original.data, fileName: "misleading.txt"), options: .init())
    #expect(encoded.text.hasPrefix("data:\(original.mime);base64,"))
    #expect(encoded.artifacts.isEmpty)
    var options = DataUrlTool.Options()
    options.operation = "decode"
    let decoded = try await DataUrlTool.execute(.init(text: " \n" + encoded.text + "\n"), options: options)
    let artifact = try #require(decoded.artifacts.first)
    #expect(artifact.data == original.data)
    #expect(artifact.mime == original.mime)
    #expect(artifact.name.hasSuffix(format == "jpeg" ? ".jpg" : "." + format))
    #expect(try ImageCodec.decode(.init(file: artifact.data)).width == 8)
  }

  @Test func percentEncodedImageAndBase64() async throws {
    let original = try fixture()
    var options = DataUrlTool.Options()
    options.operation = "decode"
    let payload = original.data.map { String(format: "%%%02X", $0) }.joined()
    let decoded = try await DataUrlTool.execute(.init(text: "data:image/png," + payload), options: options)
    #expect(decoded.artifacts.first?.data == original.data)
    let base64 = original.data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "/", with: "%2F")
      .replacingOccurrences(of: "=", with: "%3D")
    #expect(try await DataUrlTool.execute(
      .init(text: "DATA:IMAGE/PNG;BASE64," + base64), options: options).artifacts.first?.data == original.data)
  }

  @Test func rejectsTextCorruptImagesAndMismatchedMIME() async throws {
    for input in [ToolInput(text: "hello"), ToolInput(file: Data("hello".utf8), fileName: "fake.png")] {
      await #expect(throws: ToolFailure.self) {
        try await DataUrlTool.execute(input, options: .init())
      }
    }
    var options = DataUrlTool.Options()
    options.operation = "decode"
    let png = try fixture().data.base64EncodedString()
    for text in [
      "hello", "data:image/png", "data:text/plain;base64,aGVsbG8=",
      "data:image/png;base64,aGVsbG8=", "data:image/png;base64,%%%",
      "data:image/png,%F", "data:image/png,%GG", "data:image/png,",
      "data:image/jpeg;base64," + png,
    ] {
      await #expect(throws: ToolFailure.self) {
        try await DataUrlTool.execute(.init(text: text), options: options)
      }
    }
    options.operation = "invalid"
    await #expect(throws: ToolFailure.self) {
      try await DataUrlTool.execute(.init(), options: options)
    }
  }
}
