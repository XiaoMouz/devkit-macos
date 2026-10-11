import Foundation

/// Human-facing output is separate from the stable JSON contract and exact text mode.
enum CommandPresentation {
  static func list() -> String {
    let tools = ToolRegistry.all.map { $0.metadata }
    let width = (tools.map { $0.id.count }.max() ?? 0) + 3
    var lines = ["DevKit · \(tools.count) 个工具", ""]
    for category in ToolCategory.allCases {
      let group = tools.filter { $0.category == category }
      guard !group.isEmpty else { continue }
      lines.append("\(category.rawValue) · \(group.count)")
      for tool in group {
        lines.append("  " + tool.id.padding(toLength: width, withPad: " ", startingAt: 0)
          + tool.name + (tool.network ? "  [联网]" : ""))
      }
      lines.append("")
    }
    lines += ["查看参数  devkit describe <工具 ID>", "执行工具  devkit run <工具 ID> [选项]",
      "例如      devkit run base64 --text hello", "", "AI / 脚本可加 --format json 获取结构化输出。"]
    return lines.joined(separator: "\n") + "\n"
  }

  static func describe(_ tool: [String: Any]) -> String {
    let id = tool["id"] as? String ?? ""
    let name = tool["name"] as? String ?? id
    let styles = ["text": "文本", "pair": "两份文本", "file": "二进制文件", "generator": "生成器（可留空）"]
    let style = tool["inputStyle"] as? String ?? "text"
    var lines = ["\(name) · \(id)", tool["summary"] as? String ?? "", "",
      "分类  \(tool["category"] as? String ?? "")",
      "输入  \(styles[style] ?? style)",
      "网络  " + (tool["network"] as? Bool == true ? "需要 --allow-network" : "本地处理"), "", "参数"]
    let fields = tool["options"] as? [[String: Any]] ?? []
    if fields.isEmpty { lines.append("  无需额外参数。") }
    for field in fields {
      let key = field["id"] as? String ?? ""
      let label = field["label"] as? String ?? key
      let inactive = field["visible"] as? Bool == false ? " · 其他操作使用" : ""
      let type = field["type"] as? String ?? "string"
      let typeName = ["string": "文本", "integer": "整数", "boolean": "布尔值"][type] ?? type
      let value = field["secret"] as? Bool == true ? "（敏感值不显示）" : literal(field["default"])
      lines += ["  \(key) · \(label)\(inactive)", "    \(typeName) · 当前值：\(value)"]
      if let choices = field["enum"] as? [String] {
        lines.append("    可选：" + choices.map { literal($0) }.joined(separator: " / "))
      }
      if let lower = field["minimum"] as? Int, let upper = field["maximum"] as? Int {
        lines.append("    范围：\(lower)–\(upper)")
      }
    }
    lines += ["", "用法", "  devkit run \(id) --option 参数名=值",
      "  文本：--text '内容' 或 --input-file 文件路径"]
    if style == "pair" { lines.append("  第二份文本：--secondary '内容' 或 --secondary-file 文件路径") }
    if style == "file" { lines.append("  二进制文件：--file 文件路径") }
    if let input = tool["exampleInput"] as? [String: Any] {
      for (key, title) in [("text", "输入示例"), ("secondary", "第二份文本示例")] {
        if let value = input[key] as? String, !value.isEmpty, key == "text" || style == "pair" {
          lines += ["", title, indent(value)]
        }
      }
    }
    lines += ["", "限制  文本合计 5 MiB · 文件 32 MiB · 主要结果 32 MiB · 最长 25 秒",
      "      部分工具有更低限制；AI / 脚本可加 --format json。"]
    return lines.joined(separator: "\n") + "\n"
  }

  static func output(_ output: ToolOutput) -> String {
    var sections = [String]()
    if !output.text.isEmpty { sections.append(output.text) }
    if let report = output.report {
      let state = ["success": "通过", "failure": "未通过", "warning": "提醒"][report.state] ?? report.state
      sections.append("\(state) · \(report.title)\n\(report.detail)"
        + (report.metrics.isEmpty ? "" : "\n" + rows(report.metrics)))
    }
    if !output.rows.isEmpty { sections.append("详细结果\n" + rows(output.rows)) }
    if let note = output.note, !note.isEmpty { sections.append("说明：" + note) }
    if !output.artifacts.isEmpty {
      sections.append("附件\n" + output.artifacts.map {
        "  \($0.name) · \($0.mime) · \($0.data.count) 字节"
      }.joined(separator: "\n") + "\n附件尚未保存；使用 --format json 获取完整附件数据。")
    }
    if output.html != nil { sections.append("包含 HTML 预览，可通过 --format json 获取。") }
    if sections.isEmpty { return "（空结果）\n" }
    let result = sections.joined(separator: "\n\n")
    return result.hasSuffix("\n") ? result : result + "\n"
  }

  private static func rows(_ values: [ResultRow]) -> String {
    values.map { "  \($0.label)：" + $0.value.replacingOccurrences(of: "\n", with: "\n    ") }
      .joined(separator: "\n")
  }
  private static func indent(_ value: String) -> String {
    value.components(separatedBy: "\n").map { "  " + $0 }.joined(separator: "\n")
  }
  private static func literal(_ value: Any?) -> String {
    guard let value, !(value is NSNull) else { return "（无）" }
    if let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .withoutEscapingSlashes]),
      let text = String(data: data, encoding: .utf8) { return text }
    return String(describing: value)
  }
}
