import DevKitCore
import Foundation
import Testing

@testable import DevKitSession

private actor Gate {
  private var continuations: [String: CheckedContinuation<ToolOutput, Never>] = [:]
  private(set) var started: Set<String> = []
  func run(_ request: WorkerRequest) async -> ToolOutput {
    started.insert(request.input.text)
    return await withCheckedContinuation { continuations[request.input.text] = $0 }
  }
  func finish(_ input: String, output: String) {
    continuations.removeValue(forKey: input)?.resume(returning: ToolOutput(output))
  }
  func hasStarted(_ text: String) -> Bool { started.contains(text) }
}

@Suite("Shared workspace session") @MainActor struct SharedSessionTests {
  private func waitUntil(_ condition: () async -> Bool) async throws {
    for _ in 0..<200 {
      if await condition() { return }
      try await Task.sleep(for: .milliseconds(5))
    }
    Issue.record("Session did not reach the expected state within one second")
  }
  @Test func dataURLSwitchingModesClearsIncompatibleInputAndOutput() async throws {
    let bridge = WorkspaceBridge()
    let session = ToolSession<DataUrlTool>(id: UUID(), bridge: bridge) { _ in
      ToolOutput("data:image/png;base64,fixture")
    }
    #expect(session.inputStyle == .file)
    session.input = ToolInput(file: Data([1, 2, 3]), fileName: "fixture.png")
    session.run()
    try await waitUntil { session.current }
    session.options.operation = "decode"
    #expect(session.inputStyle == .text)
    #expect(session.input.file == nil)
    #expect(session.output == nil)
    #expect(!session.current)
    session.input.text = "data:image/png;base64,fixture"
    session.options.operation = "encode"
    #expect(session.inputStyle == .file)
    #expect(session.input.text.isEmpty)
  }
  @Test func jsonSwitchesPreserveSourceAndSeparateSchemaFromComparison() {
    let session = ToolSession<JsonTool>(id: UUID(), bridge: WorkspaceBridge())
    session.input.text = "{\"version\":1}"
    session.options.operation = "diff"
    session.input.secondary = "{\"version\":2}"
    session.options.operation = "schema"
    #expect(session.input.text == "{\"version\":1}")
    #expect(session.input.secondary.isEmpty)
    session.input.secondary = "{\"type\":\"object\"}"
    session.options.operation = "typescript"
    #expect(session.input.text == "{\"version\":1}")
    session.options.operation = "diff"
    #expect(session.input.secondary == "{\"version\":2}")
    session.options.operation = "schema"
    #expect(session.input.secondary == "{\"type\":\"object\"}")
  }
  @Test func queryModesTranslateBetweenRowsAndURLWithoutLosingValues() {
    let session = ToolSession<QueryStringTool>(id: UUID(), bridge: WorkspaceBridge())
    session.input.text = "https://example.test/?tag=a&tag=b&q=hello%2Bworld"
    session.options.operation = "build"
    #expect(session.input.text.contains("hello+world"))
    session.options.operation = "parse"
    #expect(session.input.text == "tag=a&tag=b&q=hello%2Bworld")
  }
  @Test func qrGenerationPrefersImageAndScanningPrefersRecognizedText() async throws {
    let bridge = WorkspaceBridge()
    let session = ToolSession<QrCodeTool>(id: UUID(), bridge: bridge) { request in
      try await QrCodeTool.executeEncoded(request.input, options: request.options)
    }
    session.input.text = "https://example.test"
    session.run()
    try await waitUntil { session.current }
    let png = try #require(session.output?.artifacts.first?.data)
    #expect(session.recommendedDisplay == "preview")
    session.options.operation = "scan"
    #expect(session.inputStyle == .file)
    #expect(session.input.text.isEmpty)
    session.input = ToolInput(file: png, fileName: "qr.png")
    session.run()
    try await waitUntil { session.current }
    #expect(session.output?.text == "https://example.test")
    #expect(session.recommendedDisplay == "rows")
  }
  @Test func httpShowsBodyInsteadOfHidingItBehindResponseHeaders() async throws {
    let bridge = WorkspaceBridge()
    let session = ToolSession<HttpClientTool>(id: UUID(), bridge: bridge) { _ in
      ToolOutput("{\"ok\":true}", rows: [ResultRow("状态", "200")],
        artifacts: [Artifact("response.json", "application/json", Data("{\"ok\":true}".utf8))])
    }
    session.run()
    try await waitUntil { session.current }
    #expect(session.recommendedDisplay == "text")
  }
  @Test func textToolsRejectBinaryImportsAndFileChecksumKeepsTextFilesAsFiles() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let binary = directory.appendingPathComponent("invalid.bin")
    try Data([0xFF, 0x00]).write(to: binary)
    let json = ToolSession<JsonTool>(id: UUID(), bridge: WorkspaceBridge())
    json.input.text = "{}"
    json.loadFile(binary)
    try await waitUntil { json.error != nil }
    #expect(json.input.file == nil)
    #expect(json.input.text == "{}")
    let file = directory.appendingPathComponent("hello.txt")
    try Data("hello".utf8).write(to: file)
    let checksum = ToolSession<FileChecksumTool>(id: UUID(), bridge: WorkspaceBridge())
    checksum.loadFile(file)
    try await waitUntil { checksum.input.file != nil }
    #expect(checksum.input.file == Data("hello".utf8))
  }
  @Test func base64TextRoundTripUsesTextViewAndTextExport() async throws {
    let session = ToolSession<Base64Tool>(id: UUID(), bridge: WorkspaceBridge()) { request in
      try await Base64Tool.executeEncoded(request.input, options: request.options)
    }
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = directory.appendingPathComponent("hello.txt")
    try Data("hello".utf8).write(to: file)
    session.loadFile(file)
    try await waitUntil { session.input.text == "hello" }
    #expect(session.input.file == nil)
    session.run()
    try await waitUntil { session.current }
    let encoded = try #require(session.output?.text)
    session.options.operation = "decode"
    session.input.text = encoded
    session.run()
    try await waitUntil { session.current }
    #expect(session.output?.text == "hello")
    #expect(session.output?.artifacts.isEmpty == true)
    #expect(session.recommendedDisplay == "text")
    #expect(session.textArtifact.name == "result.txt")
    #expect(session.textArtifact.data == Data("hello".utf8))
    let binary = directory.appendingPathComponent("binary.bin")
    try Data([0xff, 0x80]).write(to: binary)
    session.loadFile(binary)
    try await waitUntil { session.error != nil }
    #expect(session.input.file == nil)
  }
  @Test func detachedViewsShareEditsAndInvalidateResultsWithoutRerunning() async throws {
    let bridge = WorkspaceBridge()
    let session = ToolSession<Base64Tool>(id: UUID(), bridge: bridge) { request in
      try await Base64Tool.executeEncoded(request.input, options: request.options)
    }
    session.input.text = "hello"
    session.run()
    try await waitUntil { !bridge.running }
    #expect(session.output?.text == "aGVsbG8=")
    let runID = session.completedRun
    session.detachedOpened()
    session.detachedOpened()
    #expect(session.completedRun == runID)
    #expect(session.current)
    session.input.text = "world"
    #expect(!session.current)
    #expect(session.output?.text == "aGVsbG8=")
    session.sourceClosed()
    session.run()
    try await waitUntil { !bridge.running }
    #expect(session.output?.text == "d29ybGQ=")
    #expect(session.current)
    session.detachedClosed()
    #expect(session.detachedCount == 1)
    #expect(session.current)
    session.detachedClosed()
  }
  @Test func cancelledOldExecutionCannotReplaceANewerResult() async throws {
    let gate = Gate()
    let bridge = WorkspaceBridge()
    let session = ToolSession<Base64Tool>(
      id: UUID(), bridge: bridge, execute: { await gate.run($0) })
    session.input.text = "first"
    session.run()
    try await waitUntil { await gate.hasStarted("first") }
    session.input.text = "second"
    session.run()
    try await waitUntil { await gate.hasStarted("second") }
    await gate.finish("second", output: "new")
    try await waitUntil { session.current }
    await gate.finish("first", output: "obsolete")
    try await Task.sleep(for: .milliseconds(20))
    #expect(session.output?.text == "new")
    #expect(session.completedRun == 1)
  }
  @Test func closingSourceKeepsAnOpenViewerButLastViewerCancels() async throws {
    let gate = Gate()
    let bridge = WorkspaceBridge()
    let session = ToolSession<Base64Tool>(
      id: UUID(), bridge: bridge, execute: { await gate.run($0) })
    session.detachedOpened()
    session.detachedOpened()
    session.input.text = "pending"
    session.run()
    try await waitUntil { await gate.hasStarted("pending") }
    session.sourceClosed()
    #expect(bridge.running)
    session.detachedClosed()
    #expect(bridge.running)
    session.detachedClosed()
    #expect(!bridge.running)
    await gate.finish("pending", output: "late")
    try await Task.sleep(for: .milliseconds(20))
    #expect(session.output == nil)
  }
  @Test func outputSizeCanSelectFocusAndManualChoiceSurvives() async throws {
    let bridge = WorkspaceBridge()
    let session = ToolSession<Base64Tool>(id: UUID(), bridge: bridge) { _ in
      ToolOutput(String(repeating: "a", count: 4000))
    }
    session.input.text = "tiny"
    session.run()
    try await waitUntil { !bridge.running }
    #expect(session.layoutPolicy.mode(width: 1200) == .focused)
    session.chooseLayout(.split)
    session.refreshLayout()
    #expect(session.layoutPolicy.mode(width: 1200) == .split)
  }
}
