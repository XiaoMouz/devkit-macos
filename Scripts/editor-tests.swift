@main struct EditorRegression {
  @MainActor static func main() async throws {
    func check(_ condition: Bool, line: Int = #line) {
      if !condition { print("FAIL at line \(line)"); exit(1) }
    }
    let app = NSApplication.shared
    app.finishLaunching()
    let original = "{\"名称\":\"🐈 &amp; <tag>\",\"enabled\":true}"
    var value = original
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 400),
      styleMask: [.titled, .resizable], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    let host = NSHostingView(rootView: CodeEditor(text: Binding(get: { value }, set: { value = $0 }), label: "Editor regression", language: .json))
    window.contentView = host
    window.layoutIfNeeded()
    host.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .milliseconds(400))
    func editor(in root: NSView) -> WorkspaceTextView? {
      if let text = root as? WorkspaceTextView { return text }
      return root.subviews.lazy.compactMap { editor(in: $0) }.first
    }
    guard let view = editor(in: host), let layout = view.layoutManager, let scroll = view.enclosingScrollView else {
      fatalError("Native editor did not mount")
    }
    check(view.string == original)
    let key = (original as NSString).range(of: "名称")
    check(layout.temporaryAttribute(.foregroundColor, atCharacterIndex: key.location, effectiveRange: nil) != nil)
    view.setSelectedRange(key)
    try await Task.sleep(for: .milliseconds(150))
    check(view.selectedRange() == key && view.string == original)
    print("PASS native highlighter preserves UTF-16 text and selection")

    window.makeFirstResponder(view)
    view.setSelectedRange(NSRange(location: 0, length: 0))
    view.insertText(" ", replacementRange: view.selectedRange())
    view.breakUndoCoalescing()
    try await Task.sleep(for: .milliseconds(180))
    check(view.string == " " + original)
    check(view.undoManager?.canUndo == true)
    view.undoManager?.undo()
    try await Task.sleep(for: .milliseconds(180))
    check(view.string == original && value == original)
    print("PASS syntax coloring adds no undo steps")

    view.setSelectedRange(NSRange(location: 0, length: (original as NSString).length))
    let board = NSPasteboard.withUniqueName()
    check(view.writeSelection(to: board, types: view.writablePasteboardTypes))
    check(board.string(forType: .string) == original)
    board.releaseGlobally()
    print("PASS copied text contains no highlighting markup")

    view.setMarkedText("中", selectedRange: NSRange(location: 1, length: 0), replacementRange: NSRange(location: 0, length: 0))
    try await Task.sleep(for: .milliseconds(180))
    check(view.hasMarkedText())
    check(view.string == "中" + original)
    view.unmarkText()
    print("PASS marked text survives highlighting updates")

    let long = "{\"value\":\"" + String(repeating: "abcdef", count: 200) + "\"}"
    view.setSelectedRange(NSRange(location: 0, length: (view.string as NSString).length))
    view.insertText(long, replacementRange: view.selectedRange())
    window.layoutIfNeeded()
    try await Task.sleep(for: .milliseconds(180))
    check(view.textContainer!.containerSize.width <= scroll.contentView.bounds.width)
    let first = layout.lineFragmentRect(forGlyphAt: 0, effectiveRange: nil)
    let last = layout.lineFragmentRect(forGlyphAt: layout.glyphIndexForCharacter(at: long.utf16.count - 1), effectiveRange: nil)
    check(last.minY > first.minY)
    check(view.frame.width <= scroll.contentView.bounds.width + 1)
    print("PASS long lines wrap inside the gutter-adjusted viewport")

    let palette = SyntaxPalette.color(.key)
    var components: [CGFloat] = []
    for name in [NSAppearance.Name.aqua, .darkAqua] {
      app.appearance = NSAppearance(named: name)
      app.appearance!.performAsCurrentDrawingAppearance {
        components.append(palette.usingColorSpace(.sRGB)!.redComponent)
      }
    }
    check(components[0] != components[1])
    print("PASS syntax palette adapts to light and dark appearances")

    let multiline = "a\r\n🐈\rb\nc\u{85}d\u{2028}e\u{2029}"
    view.insertText(multiline, replacementRange: NSRange(location: 0, length: view.string.utf16.count))
    check(view.lineStarts == [0, 3, 6, 8, 10, 12, 14])
    view.insertText("\n", replacementRange: NSRange(location: 6, length: 0))
    check(view.lineStarts == [0, 3, 7, 9, 11, 13, 15])
    view.breakUndoCoalescing()
    view.undoManager?.undo()
    check(view.string == multiline)
    check(view.lineStarts == [0, 3, 6, 8, 10, 12, 14])
    print("PASS Unicode line numbers remain correct after editing and undo")

    // An unrelated SwiftUI refresh must not reset selection or reinsert text.
    let selection = NSRange(location: 3, length: 2)
    view.setSelectedRange(selection)
    host.rootView = CodeEditor(text: Binding(get: { value }, set: { value = $0 }), label: "Editor regression", language: .json)
    host.layoutSubtreeIfNeeded()
    check(view.string == multiline && view.selectedRange() == selection)
    print("PASS unchanged editor updates preserve text and selection")

    let couldUndo = view.undoManager?.canUndo
    host.rootView = CodeEditor(text: Binding(get: { value }, set: { value = $0 }), label: "Translated editor label", language: .json)
    host.layoutSubtreeIfNeeded()
    check(editor(in: host) === view)
    check(view.accessibilityLabel() == "Translated editor label")
    check(view.string == multiline && view.selectedRange() == selection)
    check(view.undoManager?.canUndo == couldUndo)
    print("PASS translated editor labels preserve native identity, text, selection and undo")

    for source in ["é", "e\u{301}"] {
      value = source
      host.rootView = CodeEditor(text: Binding(get: { value }, set: { value = $0 }), label: "Editor regression", language: .json)
      host.layoutSubtreeIfNeeded()
      check(view.string.utf8.elementsEqual(source.utf8))
      check(view.plainText.utf8.elementsEqual(source.utf8))
    }
    print("PASS canonically equivalent replacements preserve exact input bytes")
    window.close()
    if CommandLine.arguments.contains("--benchmark") { try await benchmark() }
  }
}

// Optional diagnostic timings, not machine-dependent pass/fail thresholds.
extension EditorRegression {
  @MainActor static func benchmark() async throws {
    func measure(_ name: String, iterations: Int, _ work: () -> Void) {
      var values: [Double] = []
      for _ in 0..<iterations {
        let start = ContinuousClock.now
        work()
        let d = start.duration(to: .now).components
        values.append(Double(d.seconds) * 1000 + Double(d.attoseconds) / 1e15)
      }
      values.sort()
      print("BENCH \(name): median \(String(format: "%.2f", values[values.count / 2])) ms; max \(String(format: "%.2f", values.last!)) ms")
    }
    var value = String(repeating: "{\"title\":\"性能测试🐈\",\"value\":42}\n", count: 2500)
    let state = EditorViewState()
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 600), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    let makeRoot = { CodeEditor(text: Binding(get: { value }, set: { value = $0 }), label: "Benchmark", language: .plain, state: state) }
    let host = NSHostingView(rootView: makeRoot())
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    try await Task.sleep(for: .milliseconds(300))
    func editor(_ view: NSView) -> WorkspaceTextView? {
      if let text = view as? WorkspaceTextView { return text }
      return view.subviews.lazy.compactMap(editor).first
    }
    guard let view = editor(host) else { fatalError("missing editor") }
    print("SAMPLE UTF16=\(value.utf16.count), bytes=\(value.utf8.count)")
    measure("native typing", iterations: 30) {
      view.insertText("a", replacementRange: NSRange(location: 20, length: 0))
      host.rootView = makeRoot()
      host.layoutSubtreeIfNeeded()
    }
    measure("unchanged editor refresh", iterations: 30) {
      host.rootView = makeRoot()
      host.layoutSubtreeIfNeeded()
    }
    window.close()
  }
}
