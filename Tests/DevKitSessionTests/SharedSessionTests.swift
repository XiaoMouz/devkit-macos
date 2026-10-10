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
