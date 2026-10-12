import AppKit
import DevKitCore
import SwiftUI

/// Preserve exact source bytes (including normalization form), using a bulk
/// comparison instead of Unicode normalization or a Debug-mode byte iterator.
private func sameEditorText(_ lhs: String?, _ rhs: String) -> Bool {
  guard var lhs else { return false }
  var rhs = rhs
  return lhs.withUTF8 { left in
    rhs.withUTF8 { right in
      left.count == right.count
        && (left.isEmpty || memcmp(left.baseAddress!, right.baseAddress!, left.count) == 0)
    }
  }
}

struct CodeEditor: View {
  @Binding var text: String
  var editable = true
  var label: String
  var language: SyntaxLanguage = .automatic
  var status: PaneStatus? = nil
  var contentSettled: () -> Void = {}
  var editingBegan: () -> Void = {}
  var state: EditorViewState? = nil
  var contentID = 0
  @State private var localState = EditorViewState()
  @State private var analysis = EditorTextAnalysis()
  @AppStorage("wrapLines") private var requestedWrap = true
  private var editorState: EditorViewState { state ?? localState }
  private var effectiveLanguage: SyntaxLanguage { editorState.languageOverride ?? language }
  private func replaceLarge(_ range: NSRange, _ replacement: String) -> Bool {
    guard editable, NSMaxRange(range) <= (text as NSString).length else { return false }
    let updated = (text as NSString).replacingCharacters(in: range, with: replacement)
    editorState.largeUndo = text; editorState.largeRedo = nil; editorState.largeExpected = updated
    editorState.page = EditorPage(); editorState.pageRevision += 1
    text = updated
    contentSettled()
    return true
  }
  private func restoreLarge(redo: Bool) {
    guard editorState.largeExpected == text,
      let value = redo ? editorState.largeRedo : editorState.largeUndo else { return }
    if redo { editorState.largeUndo = text; editorState.largeRedo = nil }
    else { editorState.largeRedo = text; editorState.largeUndo = nil }
    editorState.largeExpected = value
    editorState.page = EditorPage(); editorState.pageRevision += 1
    text = value
    contentSettled()
  }
  var body: some View {
    let summary = analysis.summary(for: text)
    let paged = summary.paged
    return VStack(spacing: 0) {
      if paged {
        PagedCodeEditor(text: $text, editable: editable, label: label, state: editorState,
          contentSettled: contentSettled, editingBegan: editingBegan,
          undoLarge: { restoreLarge(redo: false) }, redoLarge: { restoreLarge(redo: true) })
      } else {
        NativeCodeEditor(text: $text, editable: editable, label: label, language: effectiveLanguage,
          contentSettled: contentSettled, editingBegan: editingBegan, state: editorState, contentID: contentID,
          replaceLarge: replaceLarge, undoLarge: { restoreLarge(redo: false) }, redoLarge: { restoreLarge(redo: true) },
          canUndoLarge: { editorState.largeExpected == text && editorState.largeUndo != nil },
          canRedoLarge: { editorState.largeExpected == text && editorState.largeRedo != nil }).clipped()
      }
      HStack(spacing: 8) {
        if let status {
          PaneStatusLabel(status: status)
        } else { Text(L10n.tr("Characters: \(summary.characters)")).monospacedDigit() }
        Spacer(minLength: 8)
        if status != nil { Text(L10n.tr("Characters: \(summary.characters)")).monospacedDigit() }
        if !paged && requestedWrap && !summary.wrap { Text(L10n.tr("Long line · Scroll horizontally")) }
        if paged { Text(L10n.tr("Paged editing · Plain text")) }
        else {
          Menu {
            Button(L10n.tr("Follow Tool")) { editorState.languageOverride = nil }
            Divider()
            ForEach(SyntaxLanguage.allCases, id: \.self) { item in
              Button { editorState.languageOverride = item } label: {
                if editorState.languageOverride == item { Label(item.title, systemImage: "checkmark") }
                else { Text(item.title) }
              }
            }
          } label: { Text(effectiveLanguage.resolved(for: text).title) }
            .menuStyle(.borderlessButton).fixedSize().help(L10n.tr("Syntax Highlighting Language"))
        }
        Text("UTF-8").foregroundStyle(.tertiary)
      }.font(.system(size: 10)).foregroundStyle(.secondary)
        .padding(.horizontal, 16).frame(height: 28)
        .background(.primary.opacity(0.025))
        .overlay(alignment: .top) { Divider().opacity(0.5) }
    }.onChange(of: language) { _, _ in editorState.languageOverride = nil }
      .onChange(of: text) { _, value in
        if let expected = editorState.largeExpected, expected != value { editorState.clearLargeUndo() }
      }
  }
}

/// A per-editor memo, independent of status, selection, and window layout.
/// Comparing an unchanged String is cheap; counting graphemes and scanning lines is not.
@MainActor private final class EditorTextAnalysis {
  struct Summary {
    let characters: Int
    let paged: Bool
    let wrap: Bool
  }
  private var text: String?
  private var cached = Summary(characters: 0, paged: false, wrap: true)
  func summary(for value: String) -> Summary {
    if !sameEditorText(text, value) {
      let paged = value.utf16.count > 131_072
      cached = Summary(characters: value.count, paged: paged,
        wrap: !paged && EditorTextPolicy.shouldWrap(value))
      text = value
    }
    return cached
  }
}

/// Only the current fragment is laid out. Editing patches the full document,
/// so execution/export never operate on a truncated preview.
private struct PagedCodeEditor: View {
  @Binding var text: String
  let editable: Bool
  let label: String
  @Bindable var state: EditorViewState
  let contentSettled: () -> Void
  let editingBegan: () -> Void
  let undoLarge: () -> Void
  let redoLarge: () -> Void
  @State private var expected = ""
  private var fragment: Binding<String> {
    Binding(get: { state.page.content(in: text) }, set: { value in
      let updated = state.page.replace(with: value, in: text)
      expected = updated
      text = updated
    })
  }
  private func move(back: Bool) {
    if back { state.page.previous() } else { state.page.next(in: text) }
    state.pageRevision += 1
    state.selection = NSRange(location: 0, length: 0); state.scrollOrigin = .zero
  }
  private func replaceLarge(_ range: NSRange, _ replacement: String) -> Bool {
    let current = state.page.resolvedRange(in: text)
    guard editable, NSMaxRange(range) <= current.length else { return false }
    let fullRange = NSRange(location: current.location + range.location, length: range.length)
    let updated = (text as NSString).replacingCharacters(in: fullRange, with: replacement)
    state.largeUndo = text; state.largeRedo = nil; state.largeExpected = updated
    state.page.range = NSRange(location: current.location, length: EditorPage.size)
    state.pageRevision += 1
    expected = updated; text = updated
    contentSettled()
    return true
  }
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 10) {
        Button(L10n.tr("Previous Page")) { move(back: true) }.disabled(state.page.previousRanges.isEmpty)
        Text(L10n.tr("Page \(state.page.previousRanges.count + 1)")).monospacedDigit()
        Button(L10n.tr("Next Page")) { move(back: false) }.disabled(!state.page.hasNext(in: text))
        Spacer()
        Button(L10n.tr("Copy All Text")) { Clipboard.copy(text) }
        Text(editable ? L10n.tr("Edits update the full text") : L10n.tr("Full text retained; browse page by page"))
      }.font(.caption).padding(8).background(.primary.opacity(0.025))
      NativeCodeEditor(text: fragment, editable: editable, label: label + L10n.tr("(Current page)"), language: .plain,
        contentSettled: contentSettled, editingBegan: editingBegan, state: state,
        contentID: -(state.pageRevision + 1), replaceLarge: replaceLarge,
        undoLarge: undoLarge, redoLarge: redoLarge,
        canUndoLarge: { state.largeExpected == text && state.largeUndo != nil },
        canRedoLarge: { state.largeExpected == text && state.largeRedo != nil }).clipped()
    }.onAppear { expected = text }
      .onChange(of: text) { _, value in
        if expected != value { state.page = EditorPage(); state.pageRevision += 1; expected = value }
      }
  }
}

private struct NativeCodeEditor: NSViewRepresentable {
  @Binding var text: String
  let editable: Bool
  let label: String
  let language: SyntaxLanguage
  let contentSettled: () -> Void
  let editingBegan: () -> Void
  let state: EditorViewState
  let contentID: Int
  var replaceLarge: ((NSRange, String) -> Bool)? = nil
  var undoLarge: (() -> Void)? = nil
  var redoLarge: (() -> Void)? = nil
  var canUndoLarge: (() -> Bool)? = nil
  var canRedoLarge: (() -> Bool)? = nil
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.workspaceActive) private var workspaceActive
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @AppStorage("wrapLines") private var wrap = true

  func makeNSView(context: Context) -> EditorContainer {
    // Explicit TextKit 1: temporary layout attributes never enter undo or clipboard data.
    let storage = NSTextStorage()
    let manager = NSLayoutManager()
    manager.allowsNonContiguousLayout = true
    // A process-wide typesetter retains its largest paragraph buffers even
    // after an editor closes. Give this editor a concrete, owned typesetter.
    let typesetter = NSATSTypesetter()
    typesetter.usesFontLeading = manager.usesFontLeading
    typesetter.typesetterBehavior = manager.typesetterBehavior
    manager.typesetter = typesetter
    storage.addLayoutManager(manager)
    let container = NSTextContainer(size: NSSize(width: 320, height: CGFloat.greatestFiniteMagnitude))
    manager.addTextContainer(container)
    let view = WorkspaceTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 320), textContainer: container)
    let scroll = EditorScrollView()
    let host = EditorContainer(scroll: scroll)
    scroll.wantsLayer = true
    scroll.layer?.masksToBounds = true
    scroll.documentView = view
    scroll.hasVerticalScroller = true
    scroll.drawsBackground = false
    scroll.automaticallyAdjustsContentInsets = false
    scroll.borderType = .noBorder
    view.delegate = context.coordinator
    view.undoLarge = { [weak coordinator = context.coordinator] in coordinator?.parent.undoLarge?() }
    view.redoLarge = { [weak coordinator = context.coordinator] in coordinator?.parent.redoLarge?() }
    view.canUndoLarge = { [weak coordinator = context.coordinator] in coordinator?.parent.canUndoLarge?() ?? false }
    view.canRedoLarge = { [weak coordinator = context.coordinator] in coordinator?.parent.canRedoLarge?() ?? false }
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
    configure(view, scroll: scroll)
    // A binding can change before SwiftUI removes the previous (unpaged)
    // branch. Never give that transient native view the full large document.
    let visibleText = text.utf16.count > 131_072 ? EditorPage().content(in: text) : text
    view.string = visibleText
    view.rebuildLines()
    if state.contentID != contentID {
      state.contentID = contentID
      state.selection = NSRange(location: 0, length: 0)
      state.scrollOrigin = .zero
    }
    let length = (visibleText as NSString).length
    let location = min(state.selection.location, length)
    view.setSelectedRange(NSRange(location: location, length: min(state.selection.length, length - location)))
    scroll.pendingScrollOrigin = state.scrollOrigin
    context.coordinator.schedule(view)
    return host
  }
  private func configure(_ view: WorkspaceTextView, scroll: EditorScrollView, forceUnwrapped: Bool = false) {
    let wrap = !forceUnwrapped && self.wrap && view.allowsWrapping(text)
    if view.isEditable != (editable && isEnabled) { view.isEditable = editable && isEnabled }
    if !isEnabled && view.window?.firstResponder === view { view.window?.makeFirstResponder(nil) }
    if view.isSelectable != isEnabled { view.isSelectable = isEnabled }
    scroll.setAccessibilityHidden(!isEnabled)
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    if view.font != font { view.font = font; view.needsDisplay = true; scroll.lineRuler?.needsDisplay = true }
    let changedWrap = scroll.wrapLines != wrap
    if view.isHorizontallyResizable != !wrap { view.isHorizontallyResizable = !wrap }
    if changedWrap { scroll.wrapLines = wrap }
    let mask: NSView.AutoresizingMask = wrap ? [.width] : []
    if view.autoresizingMask != mask { view.autoresizingMask = mask }
    if view.textContainer?.widthTracksTextView != wrap { view.textContainer?.widthTracksTextView = wrap }
    let containerSize = NSSize(
      width: wrap ? max(0, scroll.contentView.bounds.width - view.textContainerInset.width * 2) : .greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude)
    if view.textContainer?.containerSize != containerSize { view.textContainer?.containerSize = containerSize }
    if scroll.hasHorizontalScroller != !wrap { scroll.hasHorizontalScroller = !wrap }
    if changedWrap { scroll.tile() }
  }
  func updateNSView(_ host: EditorContainer, context: Context) {
    let scroll = host.scroll
    context.coordinator.parent = self
    guard let view = scroll.documentView as? WorkspaceTextView else { return }
    if view.accessibilityLabel() != label { view.setAccessibilityLabel(label) }
    guard text.utf16.count <= 131_072 else { return }
    context.coordinator.updatingView = true
    defer { context.coordinator.updatingView = false }
    let changedPage = state.contentID != contentID
    if changedPage {
      state.contentID = contentID
      state.selection = NSRange(location: 0, length: 0); state.scrollOrigin = .zero
      view.undoManager?.removeAllActions()
      view.setSelectedRange(NSRange(location: 0, length: 0))
      scroll.pendingScrollOrigin = .zero
      scroll.contentView.scroll(to: .zero)
      scroll.reflectScrolledClipView(scroll.contentView)
    }
    if !sameEditorText(view.plainText, text) && !view.hasMarkedText() {
      // Stop wrapping before inserting a huge paragraph; when clearing it,
      // replace the text before restoring normal wrapping.
      if !view.allowsWrapping(text) { configure(view, scroll: scroll, forceUnwrapped: true) }
      let range = view.selectedRange()
      view.string = text
      view.setSelectedRange(NSRange(location: editable ? min(range.location, (text as NSString).length) : 0, length: 0))
      if !editable || text.isEmpty { view.undoManager?.removeAllActions() }
      view.rebuildLines()
      if !editable || changedPage {
        state.selection = NSRange(location: 0, length: 0)
        state.scrollOrigin = .zero
        scroll.pendingScrollOrigin = .zero
        scroll.contentView.scroll(to: .zero)
        scroll.reflectScrolledClipView(scroll.contentView)
      }
    }
    configure(view, scroll: scroll)
    context.coordinator.schedule(view)
  }
  static func dismantleNSView(_ host: EditorContainer, coordinator: Coordinator) {
    let scroll = host.scroll
    coordinator.release()
    if let view = scroll.documentView as? NSTextView {
      if coordinator.parent.state.contentID == coordinator.parent.contentID {
        coordinator.parent.state.selection = view.selectedRange()
        coordinator.parent.state.scrollOrigin = scroll.contentView.bounds.origin
      }
      view.delegate = nil
      view.undoManager?.removeAllActions()
      view.string = ""
    }
    scroll.documentView = nil
    scroll.lineRuler = nil
    host.ruler.scrollView = nil
  }
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  func sizeThatFits(_ proposal: ProposedViewSize, nsView: EditorContainer, context: Context) -> CGSize? {
    CGSize(width: max(0, proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? 320),
      height: max(0, proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? 320))
  }
  @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
    var parent: NativeCodeEditor
    var bulkEdit = false
    var updatingView = false
    var highlightTask: Task<Void, Never>?
    private var scheduledText: String?
    private var scheduledLanguage: SyntaxLanguage?
    private var revision = 0
    init(_ parent: NativeCodeEditor) { self.parent = parent }
    func release() {
      if (scheduledText?.utf8.count ?? 0) > 256 * 1024 {
        Task { await IdleMemoryCleanup.shared.schedule() }
      }
      highlightTask?.cancel()
      highlightTask = nil
      scheduledText = nil
      scheduledLanguage = nil
      revision += 1
    }
    func schedule(_ view: WorkspaceTextView) {
      guard parent.isEnabled && parent.workspaceActive else {
        highlightTask?.cancel(); scheduledText = nil; return
      }
      guard !view.hasMarkedText() else { highlightTask?.cancel(); scheduledText = nil; return }
      let snapshot = view.plainText
      let language = parent.language
      guard !sameEditorText(scheduledText, snapshot) || scheduledLanguage != language else { return }
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
          sameEditorText(view.plainText, snapshot), !view.hasMarkedText() else { return }
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
      guard !updatingView else { return }
      guard parent.text.utf16.count <= 131_072 else { return }
      guard let view = notification.object as? WorkspaceTextView else { return }
      view.rebuildLines()
      parent.text = view.plainText
      schedule(view)
      if bulkEdit { bulkEdit = false; parent.contentSettled() }
    }
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange,
      replacementString: String?) -> Bool {
      if let replacementString, (textView.textStorage?.length ?? 0) - affectedCharRange.length + replacementString.utf16.count > 131_072,
        parent.replaceLarge?(affectedCharRange, replacementString) == true { return false }
      bulkEdit = (replacementString?.utf8.count ?? 0) > 128 || affectedCharRange.length > 128
      if let replacementString, !EditorTextPolicy.shouldWrap(replacementString),
        let view = textView as? WorkspaceTextView, let scroll = view.enclosingScrollView as? EditorScrollView {
        parent.configure(view, scroll: scroll, forceUnwrapped: true)
      }
      return true
    }
    func textViewDidChangeSelection(_ notification: Notification) {
      guard let view = notification.object as? WorkspaceTextView else { return }
      view.needsDisplay = true
      (view.enclosingScrollView as? EditorScrollView)?.lineRuler?.needsDisplay = true
    }
    func textDidEndEditing(_ notification: Notification) {
      guard !updatingView else { return }
      parent.contentSettled()
    }
    func textDidBeginEditing(_ notification: Notification) {
      guard !updatingView else { return }
      parent.editingBegan()
    }
  }
}

private final class EditorContainer: NSView {
  let scroll: EditorScrollView
  let ruler = EditorLineRuler(frame: .zero)
  override var isFlipped: Bool { true }
  init(scroll: EditorScrollView) {
    self.scroll = scroll
    super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 320))
    ruler.scrollView = scroll
    scroll.lineRuler = ruler
    ruler.setAccessibilityHidden(true)
    addSubview(ruler)
    addSubview(scroll)
    ruler.frame = NSRect(x: 0, y: 0, width: 34, height: 320)
    scroll.frame = NSRect(x: 34, y: 0, width: 286, height: 320)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
  override func setFrameSize(_ newSize: NSSize) {
    guard newSize != frame.size else { return }
    super.setFrameSize(newSize)
    needsLayout = true
  }
  override func layout() {
    super.layout()
    let gutter = min(ruler.ruleThickness, bounds.width)
    let rulerFrame = NSRect(x: 0, y: 0, width: gutter, height: bounds.height)
    let scrollFrame = NSRect(x: gutter, y: 0, width: max(0, bounds.width - gutter), height: bounds.height)
    if ruler.frame != rulerFrame { ruler.frame = rulerFrame }
    if scroll.frame != scrollFrame { scroll.frame = scrollFrame }
  }
}

private final class EditorScrollView: NSScrollView {
  weak var lineRuler: EditorLineRuler?
  override func reflectScrolledClipView(_ clipView: NSClipView) {
    super.reflectScrolledClipView(clipView)
    lineRuler?.needsDisplay = true
  }
  var wrapLines = true
  var pendingScrollOrigin: CGPoint?
  private var adjustingDocument = false
  override func layout() {
    super.layout()
    synchronizeDocumentGeometry()
    if let origin = pendingScrollOrigin, window != nil, contentView.bounds.height > 0 {
      pendingScrollOrigin = nil
      if let view = documentView as? NSTextView, let manager = view.layoutManager, !view.string.isEmpty {
        manager.ensureLayout(forCharacterRange: NSRange(location: 0, length: 1))
      }
      let target = CGPoint(x: wrapLines ? 0 : max(0, origin.x),
        y: min(max(0, origin.y), max(0, (documentView?.frame.height ?? 0) - contentView.bounds.height)))
      contentView.scroll(to: target)
      reflectScrolledClipView(contentView)
    }
  }
  override func tile() {
    super.tile()
    synchronizeDocumentGeometry()
  }
  private func synchronizeDocumentGeometry() {
    guard !adjustingDocument, let view = documentView as? NSTextView else { return }
    adjustingDocument = true
    defer { adjustingDocument = false }
    let minimum = NSSize(width: 0, height: contentView.bounds.height)
    if view.minSize != minimum { view.minSize = minimum }
    if wrapLines {
      let width = max(0, contentView.bounds.width)
      if abs(view.frame.width - width) > 0.5 {
        view.setFrameSize(NSSize(width: width, height: max(view.frame.height, contentView.bounds.height)))
      }
      let containerWidth = max(0, width - view.textContainerInset.width * 2)
      if view.textContainer?.containerSize.width != containerWidth { view.textContainer?.containerSize.width = containerWidth }
      if contentView.bounds.origin.x != 0 {
        contentView.scroll(to: CGPoint(x: 0, y: contentView.bounds.origin.y))
        reflectScrolledClipView(contentView)
      }
    }
  }

}

private final class WorkspaceTextView: NSTextView {
  // Do not retain closed editors through the window's shared undo history.
  private let editorUndoManager: UndoManager = {
    let manager = UndoManager()
    manager.levelsOfUndo = 50
    return manager
  }()
  override var undoManager: UndoManager? { editorUndoManager }
  var undoLarge: (() -> Void)?
  var redoLarge: (() -> Void)?
  var canUndoLarge: (() -> Bool)?
  var canRedoLarge: (() -> Bool)?
  @objc func undo(_ sender: Any?) {
    if editorUndoManager.canUndo { editorUndoManager.undo() } else { undoLarge?() }
  }
  @objc func redo(_ sender: Any?) {
    if editorUndoManager.canRedo { editorUndoManager.redo() } else { redoLarge?() }
  }
  override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(undo(_:)) { return isEditable && (editorUndoManager.canUndo || canUndoLarge?() == true) }
    if menuItem.action == #selector(redo(_:)) { return isEditable && (editorUndoManager.canRedo || canRedoLarge?() == true) }
    return super.validateMenuItem(menuItem)
  }
  var lineStarts = [0]
  /// NSTextView supplies an NSString-backed String. Repeated Swift equality and
  /// grapheme queries on that foreign storage normalize Unicode scalar by scalar.
  /// Materialize one native snapshot per edit, shared by the binding and highlighter.
  private(set) var plainText = ""
  private var wrapText: String?
  private var cachedWrap = true
  func allowsWrapping(_ text: String) -> Bool {
    if !sameEditorText(wrapText, text) {
      cachedWrap = EditorTextPolicy.shouldWrap(text)
      wrapText = text
    }
    return cachedWrap
  }
  func rebuildLines() {
    plainText = string
    plainText.makeContiguousUTF8()
    lineStarts = [0]
    let source = plainText as NSString
    var start = 0
    while start < source.length {
      var end = 0, contentsEnd = 0
      source.getLineStart(nil, end: &end, contentsEnd: &contentsEnd,
        for: NSRange(location: start, length: 0))
      if end > contentsEnd { lineStarts.append(end) }
      start = end
    }
    if let ruler = (enclosingScrollView as? EditorScrollView)?.lineRuler {
      let width = max(34, CGFloat(String(lineStarts.count).count) * 7 + 16)
      if ruler.ruleThickness != width { ruler.ruleThickness = width; ruler.superview?.needsLayout = true }
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
    needsDisplay = true; (enclosingScrollView as? EditorScrollView)?.lineRuler?.needsDisplay = true
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

private final class EditorLineRuler: NSView {
  weak var scrollView: EditorScrollView?
  var ruleThickness: CGFloat = 34
  override var isFlipped: Bool { true }
  override func draw(_ rect: NSRect) {
    NSColor.separatorColor.withAlphaComponent(0.5).setFill()
    NSRect(x: bounds.maxX - 0.5, y: bounds.minY, width: 0.5, height: bounds.height).fill()
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
