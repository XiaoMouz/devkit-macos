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
    window.close()
  }
}
