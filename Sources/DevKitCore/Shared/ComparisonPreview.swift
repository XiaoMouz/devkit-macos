import Foundation

/// Static HTML only: all input is escaped and SafePreview disables scripts and network access.
public enum ComparisonPreview {
  public static func documents(_ documents: [(title: String, lines: [(text: String, kind: String)])]) -> String {
    let columns = documents.map { document in
      let lines = document.lines.enumerated().map { index, line in
        "<div class='line \(line.kind)'><span class='number'>\(index + 1)</span><span>\(htmlEscape(line.text).isEmpty ? " " : htmlEscape(line.text))</span></div>"
      }.joined()
      return "<section><h3>\(htmlEscape(document.title))</h3><div class='code'>\(lines)</div></section>"
    }.joined()
    return """
      <style>
      body{margin:0;padding:16px!important}.columns{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(300px,100%),1fr));gap:16px}
      section{min-width:0;border:1px solid light-dark(#dde2ea,#39404a);border-radius:10px;overflow:hidden}h3{font-size:12px;margin:0;padding:12px;background:light-dark(#f3f5f8,#242830)}
      .code{padding:10px;font:13px/1.8 ui-monospace,SFMono-Regular,Menlo,monospace}.line{display:flex;gap:12px;padding:0 5px;white-space:pre-wrap;overflow-wrap:anywhere;min-height:24px}
      .number{color:light-dark(#758195,#9aa8bc);min-width:28px;text-align:right;user-select:none}.add{background:light-dark(#e0f4e8,#173e2b);border-left:3px solid #36a465}.remove,.error{background:light-dark(#fce5e8,#4d252c);border-left:3px solid #d25b70}
      .legend{font-size:12px;color:light-dark(#526174,#becbdc);margin-bottom:12px}
      </style><div class='legend'>\(htmlEscape(L10n.tr("Green ＋ Added / Actual value · Red − Removed / Failed")))</div><div class='columns'>\(columns)</div>
      """
  }
}
