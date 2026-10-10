import Foundation
import Testing

@testable import DevKitCore

@Suite("Core behavior") struct CoreTests {
  @Test func base64Vectors() async throws {
    var options = Base64Tool.Options()
    #expect(
      try await Base64Tool.execute(ToolInput(text: "hello"), options: options).text == "aGVsbG8=")
    options.operation = "decode"
    #expect(
      try await Base64Tool.execute(
        ToolInput(text: "MTIzMTIzMTIzYXNkZmFkc2ZzZGFmCg"), options: options
      ).text == "123123123asdfadsfsdaf\n")
    #expect(try Base64Codec.decode("Zg") == Data("f".utf8))
    for invalid in ["Z", "Zg=", "Zg===", "Z=g=", "Zh==", "Zg$=", "Zg\u{a0}=="] {
      #expect(throws: (any Error).self) { try Base64Codec.decode(invalid) }
    }
    #expect(try Base64Codec.decode(" Zg==\n") == Data("f".utf8))
    #expect(try Base64Codec.decode("_w", urlSafe: true) == Data([255]))
  }
  @Test func commandsPreservePayload() throws {
    #expect(try Base64Command.parse("encode hello ").payload == "hello ")
    #expect(try Base64Command.parse("base64 encode --  hello\n").payload == " hello\n")
    #expect(try Base64Command.parse("encode --").payload == "")
    #expect(try Base64Command.parse("encode 'hello'").payload == "'hello'")
    #expect(throws: (any Error).self) { try Base64Command.parse("encode") }
    #expect(throws: (any Error).self) { try Base64Command.parse("encode ") }
  }
  @Test func digestVectors() {
    #expect(
      Digest.compute(Data("hello".utf8), algorithm: "MD5") == "5d41402abc4b2a76b9719d911017c592")
    #expect(
      Digest.compute(Data("abc".utf8), algorithm: "SHA-256")
        == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
  }
  @Test func jsonKeepsNumbers() async throws {
    let value = "{\"n\":9007199254740993,\"decimal\":0.12345678901234567890123456789}"
    let result = try await JsonTool.execute(ToolInput(text: value), options: .init())
    #expect(result.text.contains("9007199254740993"))
    #expect(result.text.contains("0.12345678901234567890123456789"))
  }
  @Test func registryUnique() {
    let ids = ToolRegistry.all.map { $0.metadata.id }
    #expect(Set(ids).count == ids.count)
  }
  @Test func randomConstraints() async throws {
    var options = RandomStringTool.Options()
    options.alphabet = "aab😀"
    options.length = 64
    options.count = 3
    options.excludeSimilar = false
    let result = try await RandomStringTool.execute(ToolInput(), options: options)
    #expect(result.rows.count == 3)
    #expect(
      result.rows.allSatisfy { $0.value.count == 64 && Set($0.value).isSubset(of: Set("ab😀")) })
    let uuid = try await UuidTool.execute(ToolInput(), options: .init())
    #expect(
      uuid.rows.allSatisfy { UUID(uuidString: $0.value) != nil && Array($0.value)[14] == "4" })
  }
  @Test func allTextSamples() async throws {
    for tool in ToolRegistry.all
    where !tool.metadata.sample.isEmpty && !tool.metadata.network
      && tool.metadata.inputStyle != .file && tool.metadata.id != "hmac"
    {
      do { _ = try await sample(tool) } catch {
        Issue.record("\(tool.metadata.id) sample failed: \(error)")
      }
    }
  }
  private func sample<T: ToolModule>(_ tool: T.Type) async throws -> ToolOutput {
    try await T.execute(
      ToolInput(text: T.metadata.sample, secondary: T.metadata.secondary), options: T.Options())
  }
}
