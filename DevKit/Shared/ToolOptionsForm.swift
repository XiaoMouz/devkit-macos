import DevKitCore
import SwiftUI

struct ToolOptionsForm<Options: ToolOptions>: View {
  @Binding var options: Options
  let fields: [OptionField<Options>]
  let modified: () -> Void
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          Label(L10n.tr("Tool Configuration"), systemImage: "slider.horizontal.3").font(.system(size: 12, weight: .semibold))
          Spacer()
          Button {
            options = Options()
            modified()
          } label: {
            Label(L10n.tr("Reset"), systemImage: "arrow.counterclockwise")
          }.font(.caption).buttonStyle(.bordered).buttonBorderShape(.capsule).foregroundStyle(.secondary).help(L10n.tr("Restore Default Configuration"))
        }
        ToolParameterFields(options: Binding(get: { options }, set: { options = $0; modified() }), fields: fields)
      }.padding(18)
    }
  }

}

enum ToolOptionLabels {
  /// SF Symbols for modes shown in the toolbar, so mode controls read as icon and text.
  static func symbol(_ value: String) -> String? {
    [
      "encode": "arrow.right.to.line", "decode": "arrow.left.to.line",
      "format": "text.alignleft", "minify": "arrow.down.right.and.arrow.up.left",
      "validate": "checkmark.seal", "tree": "list.bullet.indent", "query": "magnifyingglass",
      "diff": "plusminus", "schema": "checklist", "typescript": "chevron.left.forwardslash.chevron.right",
      "parse": "doc.text.magnifyingglass", "build": "hammer", "sort": "arrow.up.arrow.down",
      "match": "text.magnifyingglass", "replace": "arrow.2.squarepath",
      "generate": "sparkles", "scan": "qrcode.viewfinder",
      "component": "puzzlepiece", "url": "link", "form": "list.bullet.rectangle",
      "zones": "globe", "add-days": "calendar.badge.plus", "difference": "timer",
      "scale": "arrow.up.left.and.arrow.down.right", "fit": "rectangle.center.inset.filled", "fill": "crop",
      "set-cookie": "square.and.arrow.down", "cookie": "square.and.arrow.up",
    ][value]
  }
  static func title(_ value: String) -> String {
    [
      "utf8": "UTF-8", "hex": "Hex", "base64": "Base64",
      "mysql": "MySQL", "postgresql": "PostgreSQL", "sqlite": "SQLite", "transactsql": "T-SQL",
      "encode": L10n.tr("Encode"), "decode": L10n.tr("Decode"), "format": L10n.tr("Format"), "minify": L10n.tr("Minify"), "validate": L10n.tr("Validate"),
      "tree": L10n.tr("Path List"), "parse": L10n.tr("Parse"), "build": L10n.tr("Generate"), "sort": L10n.tr("Sort"), "component": L10n.tr("URL Component"),
      "url": L10n.tr("Full URL"), "form": L10n.tr("Form Parameters"), "seconds": L10n.tr("Seconds"), "milliseconds": L10n.tr("Milliseconds"), "match": L10n.tr("Match"),
      "replace": L10n.tr("Replace"), "compress": L10n.tr("Minify"), "decompress": L10n.tr("Decompress"), "generate": L10n.tr("Generate"), "scan": L10n.tr("Scan"),
      "scale": L10n.tr("Scale Proportionally"), "fit": L10n.tr("Fit on Transparent Canvas"), "fill": L10n.tr("Center Crop"),
      "query": L10n.tr("Path Query"), "diff": L10n.tr("Structural Diff"), "schema": L10n.tr("Schema Validation"), "typescript": "TypeScript",
      "jsonpath": "JSONPath", "pointer": "JSON Pointer", "json": "JSON", "csv": "CSV",
      "zones": L10n.tr("Time Zone Conversion"), "add-days": L10n.tr("Add or Subtract Days"), "difference": L10n.tr("Time Difference"),
      "plain": L10n.tr("Round Half Up"), "bankers": L10n.tr("Banker’s Rounding"), "down": L10n.tr("Round Toward Negative Infinity"), "up": L10n.tr("Round Toward Positive Infinity"),
      "deduplicate": L10n.tr("Remove Duplicates"), "reverse-sort": L10n.tr("Sort Descending"), "remove-empty": L10n.tr("Remove Empty Lines"), "number": L10n.tr("Add Line Numbers"), "affix": L10n.tr("Add Prefix and Suffix"),
      "javascript": "JavaScript", "html": "HTML", "css": "CSS", "sql": "SQL", "png": "PNG", "jpeg": "JPEG", "heic": "HEIC",
      "index": L10n.tr("Index"), "name": L10n.tr("Full Name"), "email": L10n.tr("Email"), "boolean": L10n.tr("Boolean"), "integer": L10n.tr("Integer"), "uuid": "UUID",
      "camelCase": "camelCase", "PascalCase": "PascalCase", "snake_case": "snake_case", "kebab-case": "kebab-case",
      "lowercase": L10n.tr("Lowercase"), "uppercase": L10n.tr("Uppercase"), "L": L10n.tr("L · Approx. 7%"), "M": L10n.tr("M · Approx. 15%"), "Q": L10n.tr("Q · Approx. 25%"), "H": L10n.tr("H · Approx. 30%"),
    ][value] ?? value
  }
}
