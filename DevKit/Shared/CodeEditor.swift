import AppKit
import DevKitCore
import SwiftUI

struct CodeEditor: View {
  @Binding var text: String
  var editable = true
  var label: String
  var language: SyntaxLanguage = .automatic
  var status: PaneStatus? = nil
  var contentSettled: () -> Void = {}
  var editingBegan: () -> Void = {}
  @State private var languageOverride: SyntaxLanguage?
  private var effectiveLanguage: SyntaxLanguage { languageOverride ?? language }
  var body: some View {
    VStack(spacing: 0) {
      NativeCodeEditor(text: $text, editable: editable, label: label, language: effectiveLanguage,
        contentSettled: contentSettled, editingBegan: editingBegan).clipped()
      HStack(spacing: 8) {
        if let status {
          PaneStatusLabel(status: status)
        } else { Text("\(text.count) 字符").monospacedDigit() }
        Spacer(minLength: 8)
        if status != nil { Text("\(text.count) 字符").monospacedDigit() }
        if text.utf16.count > SyntaxHighlighter.maximumLength { Text("大文本 · 纯文本显示") }
        else {
          Menu {
            Button("跟随工具") { languageOverride = nil }
            Divider()
            ForEach(SyntaxLanguage.allCases, id: \.self) { item in
              Button { languageOverride = item } label: {
                if languageOverride == item { Label(item.title, systemImage: "checkmark") }
                else { Text(item.title) }
              }
            }
          } label: { Text(effectiveLanguage.resolved(for: text).title) }
            .menuStyle(.borderlessButton).fixedSize().help("语法高亮语言")
        }
        Text("UTF-8").foregroundStyle(.tertiary)
      }.font(.system(size: 10)).foregroundStyle(.secondary)
        .padding(.horizontal, 16).frame(height: 28)
        .background(.primary.opacity(0.025))
        .overlay(alignment: .top) { Divider().opacity(0.5) }
    }.onChange(of: language) { _, _ in languageOverride = nil }
  }
}

private struct NativeCodeEditor: NSViewRepresentable {
  @Binding var text: String
  let editable: Bool
  let label: String
  let language: SyntaxLanguage
  let contentSettled: () -> Void
  let editingBegan: () -> Void
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.workspaceActive) private var workspaceActive
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @AppStorage("wrapLines") private var wrap = true

  func makeNSView(context: Context) -> NSScrollView {
    // Explicit TextKit 1: temporary layout attributes never enter undo or clipboard data.
    let storage = NSTextStorage()
    let manager = NSLayoutManager()
    storage.addLayoutManager(manager)
    let container = NSTextContainer(size: NSSize(width: 320, height: CGFloat.greatestFiniteMagnitude))
    manager.addTextContainer(container)
    let view = WorkspaceTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 320), textContainer: container)
    let scroll = EditorScrollView()
    scroll.wantsLayer = true
    scroll.layer?.masksToBounds = true
    scroll.documentView = view
    scroll.hasVerticalScroller = true
    scroll.drawsBackground = false
    scroll.borderType = .noBorder
    view.delegate = context.coordinator
    view.isRichText = false
    view.isAutomaticQuoteSubstitutionEnabled = false
    view.isAutomaticDashSubstitutionEnabled = false
    view.isAutomaticTextReplacementEnabled = false
    view.isAutomaticSpellingCorrectionEnabled = false
    view.isContinuousSpellCheckingEnabled = false
    view.isGrammarCheckingEnabled = false
    view.isAutomaticLinkDetectionEnabled = false
    view.allowsUndo = editable
    view.usesFindBar = true
    view.isIncrementalSearchingEnabled = true
    view.isVerticallyResizable = true
    view.minSize = NSSize.zero
    view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    view.textContainerInset = NSSize(width: 8, height: 16)
    view.drawsBackground = false
    view.textColor = NSColor.textColor
    view.insertionPointColor = NSColor.controlAccentColor
    view.setAccessibilityLabel(label)
    scroll.verticalRulerView = EditorLineRuler(scrollView: scroll, orientation: .verticalRuler)
    scroll.hasVerticalRuler = true
    scroll.rulersVisible = true
    configure(view, scroll: scroll)
    view.string = text
    view.rebuildLines()
    context.coordinator.schedule(view)
    return scroll
  }
  private func configure(_ view: WorkspaceTextView, scroll: NSScrollView) {
    view.isEditable = editable && isEnabled
    if !isEnabled && view.window?.firstResponder === view { view.window?.makeFirstResponder(nil) }
    view.isSelectable = isEnabled
    scroll.setAccessibilityHidden(!isEnabled)
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    if view.font != font { view.font = font; view.needsDisplay = true; scroll.verticalRulerView?.needsDisplay = true }
    view.isHorizontallyResizable = !wrap
    (scroll as? EditorScrollView)?.wrapLines = wrap
    view.autoresizingMask = wrap ? [.width] : []
    view.textContainer?.widthTracksTextView = wrap
    view.textContainer?.containerSize = NSSize(
      width: wrap ? max(0, scroll.contentView.bounds.width - view.textContainerInset.width * 2) : .greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude)
    scroll.hasHorizontalScroller = !wrap
    scroll.tile()
  }
  func updateNSView(_ scroll: NSScrollView, context: Context) {
    context.coordinator.parent = self
    guard let view = scroll.documentView as? WorkspaceTextView else { return }
    configure(view, scroll: scroll)
    if view.string != text && !view.hasMarkedText() {
      let range = view.selectedRange()
      view.string = text
      view.setSelectedRange(NSRange(location: min(range.location, (text as NSString).length), length: 0))
      view.rebuildLines()
    }
    context.coordinator.schedule(view)
  }
  static func dismantleNSView(_ scroll: NSScrollView, coordinator: Coordinator) {
    coordinator.highlightTask?.cancel()
    (scroll.documentView as? NSTextView)?.delegate = nil
  }
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize? {
    CGSize(width: max(0, proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? 320),
      height: max(0, proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? 320))
  }
  @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
    var parent: NativeCodeEditor
    var bulkEdit = false
    var highlightTask: Task<Void, Never>?
    private var scheduledText: String?
    private var scheduledLanguage: SyntaxLanguage?
    private var revision = 0
    init(_ parent: NativeCodeEditor) { self.parent = parent }
    func schedule(_ view: WorkspaceTextView) {
      guard parent.isEnabled && parent.workspaceActive else {
        highlightTask?.cancel(); scheduledText = nil; return
      }
      guard !view.hasMarkedText() else { highlightTask?.cancel(); scheduledText = nil; return }
      let snapshot = view.string
      let language = parent.language
      guard scheduledText != snapshot || scheduledLanguage != language else { return }
      scheduledText = snapshot; scheduledLanguage = language
      highlightTask?.cancel()
      revision += 1
      let requested = revision
      let count = (snapshot as NSString).length
      guard language.resolved(for: snapshot) != .plain, count <= SyntaxHighlighter.maximumLength, count > 0 else {
        view.layoutManager?.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(location: 0, length: count))
        return
      }
      highlightTask = Task { [weak self, weak view] in
        do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
        let tokens = await SyntaxHighlighter.shared.tokens(for: snapshot, language: language)
        guard !Task.isCancelled, let self, requested == self.revision, let view,
          view.string == snapshot, !view.hasMarkedText() else { return }
        // Replace colours together, after parsing, so typing doesn't flash the
        // whole document back to monochrome during the debounce interval.
        view.layoutManager?.removeTemporaryAttribute(.foregroundColor, forCharacterRange: NSRange(location: 0, length: count))
        for token in tokens {
          view.layoutManager?.addTemporaryAttribute(.foregroundColor,
            value: SyntaxPalette.color(token.kind), forCharacterRange: token.range)
        }
        view.needsDisplay = true
      }
    }
    func textDidChange(_ notification: Notification) {
      guard let view = notification.object as? WorkspaceTextView else { return }
      view.rebuildLines()
      parent.text = view.string
      schedule(view)
      if bulkEdit { bulkEdit = false; parent.contentSettled() }
    }
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange,
      replacementString: String?) -> Bool {
      bulkEdit = (replacementString?.utf8.count ?? 0) > 128 || affectedCharRange.length > 128
      return true
    }
    func textViewDidChangeSelection(_ notification: Notification) {
      guard let view = notification.object as? WorkspaceTextView else { return }
      view.needsDisplay = true
      view.enclosingScrollView?.verticalRulerView?.needsDisplay = true
    }
    func textDidEndEditing(_ notification: Notification) { parent.contentSettled() }
    func textDidBeginEditing(_ notification: Notification) { parent.editingBegan() }
  }
}

private final class EditorScrollView: NSScrollView {
  var wrapLines = true
  private var adjustingDocument = false
  override func tile() {
    super.tile()
    guard !adjustingDocument, let view = documentView as? NSTextView else { return }
    adjustingDocument = true
    defer { adjustingDocument = false }
    view.minSize = NSSize(width: 0, height: contentView.bounds.height)
    if wrapLines {
      let width = max(0, contentView.bounds.width)
      if abs(view.frame.width - width) > 0.5 {
        view.setFrameSize(NSSize(width: width, height: max(view.frame.height, contentView.bounds.height)))
      }
      view.textContainer?.containerSize.width = max(0, width - view.textContainerInset.width * 2)
    }
  }
}

private final class WorkspaceTextView: NSTextView {
  var lineStarts = [0]
  func rebuildLines() {
    lineStarts = [0]
    var previous: UInt16 = 0
    for (index, unit) in string.utf16.enumerated() {
      if unit == 10 && previous == 13 { lineStarts[lineStarts.count - 1] = index + 1 }
      else if unit == 10 || unit == 13 || unit == 0x2028 || unit == 0x2029 { lineStarts.append(index + 1) }
      previous = unit
    }
    if let ruler = enclosingScrollView?.verticalRulerView {
      let width = max(34, CGFloat(String(lineStarts.count).count) * 7 + 16)
      if ruler.ruleThickness != width { ruler.ruleThickness = width }
      ruler.needsDisplay = true
    }
    needsDisplay = true
  }
  func lineIndex(at location: Int) -> Int {
    var low = 0, high = lineStarts.count
    while low < high {
      let middle = (low + high) / 2
      if lineStarts[middle] <= location { low = middle + 1 } else { high = middle }
    }
    return max(0, low - 1)
  }
  override func becomeFirstResponder() -> Bool { let result = super.becomeFirstResponder(); needsDisplay = true; return result }
  override func resignFirstResponder() -> Bool { let result = super.resignFirstResponder(); needsDisplay = true; return result }
  override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    needsDisplay = true; enclosingScrollView?.verticalRulerView?.needsDisplay = true
  }
  override func drawBackground(in rect: NSRect) {
    super.drawBackground(in: rect)
    guard isEditable, window?.firstResponder === self, selectedRange().length == 0, !hasMarkedText(),
      let manager = layoutManager else { return }
    let location = selectedRange().location
    var line: NSRect
    if string.isEmpty || location == (string as NSString).length && string.hasSuffix("\n") {
      line = manager.extraLineFragmentRect
      if line.height == 0 { line = NSRect(x: 0, y: 0, width: bounds.width, height: (font?.pointSize ?? 13) * 1.4) }
    } else {
      let glyph = manager.glyphIndexForCharacter(at: min(location, max(0, (string as NSString).length - 1)))
      line = manager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
    }
    line.origin.y += textContainerOrigin.y
    line.origin.x = visibleRect.minX + 4
    line.size.width = max(0, visibleRect.width - 8)
    NSColor.controlAccentColor.withAlphaComponent(0.06).setFill()
    NSBezierPath(roundedRect: line, xRadius: 3, yRadius: 3).fill()
  }
}

private final class EditorLineRuler: NSRulerView {
  override var isFlipped: Bool { true }
  override func drawHashMarksAndLabels(in rect: NSRect) {
    guard let view = scrollView?.documentView as? WorkspaceTextView,
      let manager = view.layoutManager, let container = view.textContainer else { return }
    let origin = view.textContainerOrigin
    let visible = view.visibleRect.offsetBy(dx: -origin.x, dy: -origin.y)
    let glyphs = manager.glyphRange(forBoundingRect: visible, in: container)
    let character = glyphs.length > 0 ? manager.characterIndexForGlyph(at: glyphs.location) : 0
    let start = view.lineIndex(at: character)
    let selected = view.lineIndex(at: view.selectedRange().location)
    let length = (view.string as NSString).length
    for index in start..<view.lineStarts.count {
      let offset = view.lineStarts[index]
      let fragment: NSRect
      if offset >= length { fragment = manager.extraLineFragmentRect }
      else { fragment = manager.lineFragmentRect(forGlyphAt: manager.glyphIndexForCharacter(at: offset), effectiveRange: nil) }
      let y = convert(NSPoint(x: 0, y: fragment.minY + origin.y), from: view).y
      if y > bounds.maxY { break }
      if y + fragment.height < bounds.minY { continue }
      let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: max(10, (view.font?.pointSize ?? 13) - 2), weight: .regular),
        .foregroundColor: index == selected && view.window?.firstResponder === view ? NSColor.controlAccentColor : NSColor.tertiaryLabelColor,
      ]
      let label = NSAttributedString(string: String(index + 1), attributes: attributes)
      label.draw(at: NSPoint(x: ruleThickness - label.size().width - 9, y: y + 2))
    }
  }
}

@MainActor private enum SyntaxPalette {
  private static let colors: [SyntaxToken.Kind: NSColor] = Dictionary(
    uniqueKeysWithValues: SyntaxToken.Kind.allCases.map { ($0, makeColor($0)) })
  static func color(_ kind: SyntaxToken.Kind) -> NSColor {
    colors[kind] ?? .textColor
  }
  private static func makeColor(_ kind: SyntaxToken.Kind) -> NSColor {
    NSColor(name: "syntax.\(kind.rawValue)") { appearance in
      let dark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
      let hex: Int
      switch kind {
      case .key: hex = dark ? 0x82B7FF : 0x226DB7
      case .string: hex = dark ? 0xEAAF91 : 0xA24928
      case .number: hex = dark ? 0x80C9BA : 0x287F71
      case .keyword: hex = dark ? 0xC3A5F5 : 0x8850AD
      case .type: hex = dark ? 0xE5C782 : 0x947027
      case .comment: return .secondaryLabelColor
      case .addition: hex = dark ? 0x89CDA5 : 0x278455
      case .deletion: hex = dark ? 0xEF929C : 0xB2394D
      }
      return NSColor(srgbRed: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255,
        blue: Double(hex & 255) / 255, alpha: 1)
    }
  }
}

/// Small structured results (JWT payloads, message rows) use the same grammar and palette.
struct HighlightedText: View {
  let text: String
  var language: SyntaxLanguage = .automatic
  var fontSize: CGFloat = 13
  @State private var rendered = AttributedString()
  @State private var renderedText = ""
  @Environment(\.colorScheme) private var colorScheme
  var body: some View {
    Text(renderedText == text ? rendered : AttributedString(text))
      .font(.system(size: fontSize, design: .monospaced))
      .task(id: Request(text: text, language: language, dark: colorScheme == .dark)) {
        let tokens = await SyntaxHighlighter.shared.tokens(for: text, language: language)
        guard !Task.isCancelled else { return }
        var value = AttributedString(text)
        for token in tokens {
          guard let range = Range(token.range, in: text),
            let lower = AttributedString.Index(range.lowerBound, within: value),
            let upper = AttributedString.Index(range.upperBound, within: value) else { continue }
          value[lower..<upper].foregroundColor = Color(nsColor: SyntaxPalette.color(token.kind))
        }
        rendered = value; renderedText = text
      }
  }
  private struct Request: Hashable { let text: String; let language: SyntaxLanguage; let dark: Bool }
}
