import CryptoKit
import Foundation
import Testing

@testable import DevKitCore

@Suite("Digest and local token semantics") struct SecurityTests {
  @Test func basicAuthRoundTrip() async throws {
    var options = BasicAuthTool.Options()
    options.username = "ada"
    options.password = "hello:世界"
    let encoded = try await BasicAuthTool.execute(.init(), options: options)
    options.operation = "decode"
    #expect(
      try await BasicAuthTool.execute(.init(text: encoded.text), options: options).text
        == "ada:hello:世界")
  }
  @Test func JWTAuthenticationIsSeparateFromParsing() async throws {
    func b64(_ data: Data) -> String {
      data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    let header = b64(Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8))
    let payload = b64(Data("{\"sub\":\"fixture\",\"iat\":1700000000}".utf8))
    let content = header + "." + payload
    let mac = HMAC<SHA256>.authenticationCode(
      for: Data(content.utf8), using: SymmetricKey(data: Data("fixture-key".utf8)))
    let token = content + "." + b64(Data(mac))
    #expect(
      try await JwtTool.execute(.init(text: token), options: .init()).note?.contains("未验证") == true)
    var options = JwtTool.Options()
    options.verify = true
    options.key = "fixture-key"
    #expect(
      try await JwtTool.execute(.init(text: token), options: options).note?.contains("签名有效") == true
    )
    options.key = "wrong-key"
    #expect(try await JwtTool.execute(.init(text: token), options: options).note == "签名无效")
    let none = b64(Data("{\"alg\":\"none\"}".utf8)) + "." + payload + "."
    await #expect(throws: (any Error).self) {
      try await JwtTool.execute(.init(text: none), options: options)
    }
  }
  @Test func certificateAndFileDigest() async throws {
    let url = try #require(
      Bundle.module.url(forResource: "certificate", withExtension: "pem", subdirectory: "Fixtures"))
    let pem = try String(contentsOf: url, encoding: .utf8)
    let certificate = try await PemCertificateTool.execute(.init(text: pem), options: .init())
    #expect(certificate.rows.first?.value == "devkit-fixture.test")
    #expect(certificate.rows.contains { $0.label == "到期时间" })
    var options = FileChecksumTool.Options()
    options.expected = Digest.compute(Data(pem.utf8), algorithm: "SHA-256")
    #expect(
      try await FileChecksumTool.execute(.init(file: Data(pem.utf8)), options: options).note
        == "校验一致")
  }
}
