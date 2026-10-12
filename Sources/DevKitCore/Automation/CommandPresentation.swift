import Foundation

/// Human-facing output is separate from the stable JSON contract and exact text mode.
enum CommandPresentation {
  static func list() -> String {
    let tools = ToolRegistry.all.map { $0.metadata }
    let width = (tools.map { $0.id.count }.max() ?? 0) + 3
    var lines = [L10n.tr("DevKit · \(tools.count) tools"), ""]
    for category in ToolCategory.allCases {
      let group = tools.filter { $0.category == category }
      guard !group.isEmpty else { continue }
      lines.append("\(category.title) · \(group.count)")
      for tool in group {
        lines.append("  " + tool.id.padding(toLength: width, withPad: " ", startingAt: 0)
          + tool.name + (tool.network ? L10n.tr("  [Network]") : ""))
      }
      lines.append("")
    }
    lines += [L10n.tr("Inspect options  devkit describe <tool-id>"), L10n.tr("Run a tool       devkit run <tool-id> [options]"),
      L10n.tr("Example          devkit run base64 --text hello"), "", L10n.tr("AI and scripts can add --format json for structured output.")]
    return lines.joined(separator: "\n") + "\n"
  }

  static func describe(_ tool: [String: Any]) -> String {
    let id = tool["id"] as? String ?? ""
    let name = tool["name"] as? String ?? id
    let styles = ["text": L10n.tr("Text"), "pair": L10n.tr("Two Text Inputs"), "file": L10n.tr("Binary File"), "generator": L10n.tr("Generator (input optional)")]
    let style = tool["inputStyle"] as? String ?? "text"
    var lines = ["\(name) · \(id)", tool["summary"] as? String ?? "", "",
      L10n.tr("Category  \(ToolCategory(rawValue: tool["category"] as? String ?? "")?.title ?? "")"),
      L10n.tr("Input     \(styles[style] ?? style)"),
      L10n.tr("Network   ") + (tool["network"] as? Bool == true ? L10n.tr("Requires --allow-network") : L10n.tr("Local Processing")), "", L10n.tr("Parameters")]
    let fields = tool["options"] as? [[String: Any]] ?? []
    if fields.isEmpty { lines.append(L10n.tr("  No additional options required.")) }
    for field in fields {
      let key = field["id"] as? String ?? ""
      let label = field["label"] as? String ?? key
      let inactive = field["visible"] as? Bool == false ? L10n.tr(" · Used by other operations") : ""
      let type = field["type"] as? String ?? "string"
      let typeName = ["string": L10n.tr("Text"), "integer": L10n.tr("Integer"), "boolean": L10n.tr("Boolean")][type] ?? type
      let value = field["secret"] as? Bool == true ? L10n.tr("(Sensitive value hidden)") : literal(field["default"])
      lines += ["  \(key) · \(label)\(inactive)", L10n.tr("    \(typeName) · Current value: \(value)")]
      if let choices = field["enum"] as? [String] {
        lines.append(L10n.tr("    Choices: ") + choices.map { literal($0) }.joined(separator: " / "))
      }
      if let lower = field["minimum"] as? Int, let upper = field["maximum"] as? Int {
        lines.append(L10n.tr("    Range: \(lower)–\(upper)"))
      }
    }
    lines += ["", L10n.tr("Usage"), L10n.tr("  devkit run \(id) --option name=value"),
      L10n.tr("  Text: --text 'content' or --input-file path")]
    if style == "pair" { lines.append(L10n.tr("  Second text: --secondary 'content' or --secondary-file path")) }
    if style == "file" { lines.append(L10n.tr("  Binary file: --file path")) }
    if let input = tool["exampleInput"] as? [String: Any] {
      for (key, title) in [("text", L10n.tr("Example Input")), ("secondary", L10n.tr("Example Second Input"))] {
        if let value = input[key] as? String, !value.isEmpty, key == "text" || style == "pair" {
          lines += ["", title, indent(value)]
        }
      }
    }
    lines += ["", L10n.tr("Limits  Combined text 5 MiB · File 32 MiB · Main result 32 MiB · Up to 25 seconds"),
      L10n.tr("        Some tools have lower limits. AI and scripts can add --format json.")]
    return lines.joined(separator: "\n") + "\n"
  }

  static func output(_ output: ToolOutput) -> String {
    var sections = [String]()
    if !output.text.isEmpty { sections.append(output.text) }
    if let report = output.report {
      let state = ["success": L10n.tr("Pass"), "failure": L10n.tr("Failed"), "warning": L10n.tr("Notice")][report.state] ?? report.state
      sections.append("\(state) · \(report.title)\n\(report.detail)"
        + (report.metrics.isEmpty ? "" : "\n" + rows(report.metrics)))
    }
    if !output.rows.isEmpty { sections.append(L10n.tr("Detailed Results\n") + rows(output.rows)) }
    if let note = output.note, !note.isEmpty { sections.append(L10n.tr("Note: ") + note) }
    if !output.artifacts.isEmpty {
      sections.append(L10n.tr("Attachments\n") + output.artifacts.map {
        L10n.tr("  \($0.name) · \($0.mime) · \($0.data.count) bytes")
      }.joined(separator: "\n") + L10n.tr("\nAttachments have not been saved. Use --format json for the full attachment data."))
    }
    if output.html != nil { sections.append(L10n.tr("Includes an HTML preview. Retrieve it with --format json.")) }
    if sections.isEmpty { return L10n.tr("(Empty result)\n") }
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
    guard let value, !(value is NSNull) else { return L10n.tr("(None)") }
    if let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .withoutEscapingSlashes]),
      let text = String(data: data, encoding: .utf8) { return text }
    return String(describing: value)
  }
}
