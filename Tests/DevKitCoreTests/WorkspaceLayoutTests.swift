import Testing

@testable import DevKitCore

@Suite("Adaptive workspace layout") struct WorkspaceLayoutTests {
  @Test func shortContentsUseColumnsOnlyWhenThereIsRoom() {
    var layout = WorkspaceLayoutPolicy()
    layout.evaluate(texts: ["hello", "aGVsbG8="])
    #expect(layout.mode(width: 1000) == .split)
    #expect(layout.mode(width: 600) == .split)
    #expect(layout.mode(width: 540) == .focused)
  }
  @Test func longInputOutputOrManyLinesUseTheWholeViewport() {
    for value in [
      String(repeating: "a", count: 3000), String(repeating: "line\n", count: 26),
      String(repeating: "b", count: 600),
    ] {
      var layout = WorkspaceLayoutPolicy()
      layout.evaluate(texts: ["hello", value])
      #expect(layout.mode(width: 1200) == .focused)
    }
  }
  @Test func manualChoiceSurvivesContentAndWindowChanges() {
    var layout = WorkspaceLayoutPolicy()
    layout.preference = .split
    layout.evaluate(texts: [String(repeating: "a", count: 3000)])
    #expect(layout.mode(width: 1200) == .split)
    #expect(layout.mode(width: 540) == .focused)
    #expect(layout.preference == .split)
    #expect(layout.mode(width: 1200) == .split)
    layout.preference = .focused
    layout.evaluate(texts: [""])
    #expect(layout.mode(width: 1200) == .focused)
  }
  @Test func borderlineEditsDoNotOscillateAndClearingRecoversColumns() {
    var layout = WorkspaceLayoutPolicy()
    layout.evaluate(texts: [String(repeating: "x\n", count: 30)])
    layout.evaluate(texts: [String(repeating: "x\n", count: 20)])
    #expect(layout.mode(width: 1200) == .focused)
    layout.evaluate(texts: [""])
    #expect(layout.mode(width: 1200) == .split)
  }
}
