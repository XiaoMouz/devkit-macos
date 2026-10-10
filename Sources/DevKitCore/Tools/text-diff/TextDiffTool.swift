import Foundation

public enum TextDiffTool: ToolModule {
  public struct Options: ToolOptions {
    public var ignoreWhitespace: Bool = false
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "text-diff", "文本对比", .text, "逐行比较，保留两份输入，输出增删行。", sample: "hello\nworld",
    secondary: "hello\nWeb developer", input: .pair, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("ignoreWhitespace", "忽略行首尾空白", \.ignoreWhitespace)
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let original = input.text.components(separatedBy: "\n")
    let changed = input.secondary.components(separatedBy: "\n")
    try require(original.count + changed.count <= 10000, "逐行对比限制为共 10000 行。")
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
    let rows = removed.sorted().map { ResultRow("− 原文第 \($0 + 1) 行", original[$0]) }
      + inserted.sorted().map { ResultRow("+ 对比第 \($0 + 1) 行", changed[$0]) }
    let same = rows.isEmpty
    return ToolOutput(
      output.joined(separator: "\n"), rows: rows,
      html: ComparisonPreview.documents([
        ("原始文本", original.enumerated().map { (text: $0.element, kind: removed.contains($0.offset) ? "remove" : "") }),
        ("对比文本", changed.enumerated().map { (text: $0.element, kind: inserted.contains($0.offset) ? "add" : "") }),
      ]), note: options.ignoreWhitespace ? "已忽略行首尾空白。" : "逐行比较，包含行首尾空白。",
      report: ResultReport(same ? "success" : "difference", same ? "两份文本一致" : "发现文本差异",
        same ? "所有行均通过比较，可在下方查看完整内容。" : "明细列出变化行号；高亮对照显示原文删除行和对比文本新增行。",
        metrics: [ResultRow("新增行", String(inserted.count)), ResultRow("删除行", String(removed.count)), ResultRow("原文行数", String(original.count)), ResultRow("对比行数", String(changed.count))]))
  }
}
