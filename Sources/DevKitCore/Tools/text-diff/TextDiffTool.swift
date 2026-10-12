import Foundation

public enum TextDiffTool: ToolModule {
  public struct Options: ToolOptions {
    public var ignoreWhitespace: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "text-diff", "Text Diff", .text, "Compare line by line, preserve both inputs, and show added and removed lines.", sample: "hello\nworld",
    secondary: "hello\nWeb developer", input: .pair, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("ignoreWhitespace", L10n.tr("Ignore Leading and Trailing Whitespace"), \.ignoreWhitespace)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let original = input.text.components(separatedBy: "\n")
    let changed = input.secondary.components(separatedBy: "\n")
    try require(original.count + changed.count <= 10000, L10n.tr("Line-by-line comparison is limited to 10,000 total lines."))
    let a =
      options.ignoreWhitespace ? original.map { $0.trimmingCharacters(in: .whitespaces) } : original
    let b =
      options.ignoreWhitespace ? changed.map { $0.trimmingCharacters(in: .whitespaces) } : changed
    let diff = b.difference(from: a)
    let removed = Set(
      diff.removals.compactMap { change -> Int? in
        if case .remove(let i, _, _) = change { return i }
        return nil
      })
    let inserted = Set(
      diff.insertions.compactMap { change -> Int? in
        if case .insert(let i, _, _) = change { return i }
        return nil
      })
    var output = [String]()
    var i = 0
    var j = 0
    while i < a.count || j < b.count {
      if i < a.count && removed.contains(i) {
        output.append("− " + original[i])
        i += 1
      } else if j < b.count && inserted.contains(j) {
        output.append("+ " + changed[j])
        j += 1
      } else if i < a.count && j < b.count {
        output.append("  " + changed[j])
        i += 1
        j += 1
      } else {
        break
      }
    }
    let rows = removed.sorted().map { ResultRow(L10n.tr("− Original Line \($0 + 1)"), original[$0]) }
      + inserted.sorted().map { ResultRow(L10n.tr("+ Comparison Line \($0 + 1)"), changed[$0]) }
    let same = rows.isEmpty
    return ToolOutput(
      output.joined(separator: "\n"), rows: rows,
      html: ComparisonPreview.documents([
        (L10n.tr("Original Text"), original.enumerated().map { (text: $0.element, kind: removed.contains($0.offset) ? "remove" : "") }),
        (L10n.tr("Compare Text"), changed.enumerated().map { (text: $0.element, kind: inserted.contains($0.offset) ? "add" : "") }),
      ]), note: options.ignoreWhitespace ? L10n.tr("Leading and trailing whitespace is ignored.") : L10n.tr("Line-by-line comparison includes leading and trailing whitespace."),
      report: ResultReport(same ? "success" : "difference", same ? L10n.tr("The Texts Match") : L10n.tr("Text Differences Found"),
        same ? L10n.tr("All lines match. View the full content below.") : L10n.tr("Details list changed line numbers. The highlighted comparison shows removed lines in the original and added lines in the comparison."),
        metrics: [ResultRow(L10n.tr("Added Lines"), String(inserted.count)), ResultRow(L10n.tr("Removed Lines"), String(removed.count)), ResultRow(L10n.tr("Original Lines"), String(original.count)), ResultRow(L10n.tr("Comparison Lines"), String(changed.count))]))
  }
}
