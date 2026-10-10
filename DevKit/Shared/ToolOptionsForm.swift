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
          Label("工具配置", systemImage: "slider.horizontal.3").font(.system(size: 12, weight: .semibold))
          Spacer()
          Button {
            options = Options()
            modified()
          } label: {
            Label("重置", systemImage: "arrow.counterclockwise")
          }.font(.caption).buttonStyle(.glass).buttonBorderShape(.capsule).foregroundStyle(.secondary).help("恢复默认配置")
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
      "encode": "编码", "decode": "解码", "format": "格式化", "minify": "压缩", "validate": "校验",
      "tree": "路径列表", "parse": "解析", "build": "生成", "sort": "排序", "component": "参数组件",
      "url": "完整 URL", "form": "表单参数", "seconds": "秒", "milliseconds": "毫秒", "match": "匹配",
      "replace": "替换", "compress": "压缩", "decompress": "解压", "generate": "生成", "scan": "识别",
      "scale": "等比缩放", "fit": "放入透明画布", "fill": "居中裁剪",
      "query": "路径查询", "diff": "结构对比", "schema": "Schema 校验", "typescript": "TypeScript",
      "jsonpath": "JSONPath", "pointer": "JSON Pointer", "json": "JSON", "csv": "CSV",
      "zones": "时区转换", "add-days": "日期加减", "difference": "时间差",
      "plain": "四舍五入", "bankers": "银行家舍入", "down": "向负无穷舍入", "up": "向正无穷舍入",
      "deduplicate": "去重", "reverse-sort": "降序排序", "remove-empty": "删除空行", "number": "添加行号", "affix": "添加前后缀",
      "javascript": "JavaScript", "html": "HTML", "css": "CSS", "sql": "SQL", "png": "PNG", "jpeg": "JPEG", "heic": "HEIC",
      "index": "序号", "name": "姓名", "email": "邮箱", "boolean": "布尔值", "integer": "整数", "uuid": "UUID",
      "camelCase": "camelCase", "PascalCase": "PascalCase", "snake_case": "snake_case", "kebab-case": "kebab-case",
      "lowercase": "小写", "uppercase": "大写", "L": "L · 约 7%", "M": "M · 约 15%", "Q": "Q · 约 25%", "H": "H · 约 30%",
    ][value] ?? value
  }
}
