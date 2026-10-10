import AppKit
import SwiftUI

struct CodeEditor: NSViewRepresentable {
  @Binding var text: String
  var editable = true
  var label: String
  var contentSettled: () -> Void = {}
  var editingBegan: () -> Void = {}
  @Environment(\.isEnabled) private var isEnabled
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @AppStorage("wrapLines") private var wrap = true

  func makeNSView(context: Context) -> NSScrollView {
    let scroll = NSTextView.scrollableTextView()
    scroll.hasVerticalScroller = true
    scroll.hasHorizontalScroller = !wrap
    scroll.drawsBackground = false
    let view = scroll.documentView as! NSTextView
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
    view.textContainerInset = NSSize(width: 16, height: 16)
    // The pane paints and clips one continuous surface, including native editors.
    view.drawsBackground = false
    view.textColor = .textColor
    view.setAccessibilityLabel(label)
    configure(view, scroll: scroll)
    view.string = text
    return scroll
  }
  func configure(_ view: NSTextView, scroll: NSScrollView) {
    view.isEditable = editable && isEnabled
    if !isEnabled && view.window?.firstResponder === view { view.window?.makeFirstResponder(nil) }
    view.isSelectable = isEnabled
    // Keep the native view rendered during its parent's fade/resize transition.
    scroll.setAccessibilityHidden(!isEnabled)
    view.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
    view.isHorizontallyResizable = !wrap
    view.textContainer?.widthTracksTextView = wrap
    view.textContainer?.containerSize = NSSize(
      width: wrap ? scroll.contentSize.width : .greatestFiniteMagnitude,
      height: .greatestFiniteMagnitude)
    scroll.hasHorizontalScroller = !wrap
  }
  func updateNSView(_ scroll: NSScrollView, context: Context) {
    context.coordinator.parent = self
    guard let view = scroll.documentView as? NSTextView else { return }
    configure(view, scroll: scroll)
    if view.string != text {
      let range = view.selectedRange()
      view.string = text
      view.setSelectedRange(
        NSRange(location: min(range.location, (text as NSString).length), length: 0))
    }
  }
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSScrollView, context: Context) -> CGSize?
  {
    // Editor viewport follows the offered pane, not the document's intrinsic size.
    let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? 320
    let height = proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? 320
    return CGSize(width: max(0, width), height: max(0, height))
  }
  @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
    var parent: CodeEditor
    var bulkEdit = false
    init(_ parent: CodeEditor) { self.parent = parent }
    func textDidChange(_ notification: Notification) {
      guard let view = notification.object as? NSTextView else { return }
      parent.text = view.string
      if bulkEdit {
        bulkEdit = false
        parent.contentSettled()
      }
    }
    func textView(
      _ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange,
      replacementString: String?
    ) -> Bool {
      bulkEdit = (replacementString?.utf8.count ?? 0) > 128 || affectedCharRange.length > 128
      return true
    }
    func textDidEndEditing(_ notification: Notification) { parent.contentSettled() }
    func textDidBeginEditing(_ notification: Notification) { parent.editingBegan() }
  }
}
