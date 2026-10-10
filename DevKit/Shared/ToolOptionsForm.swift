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
          Text("工具配置").font(.system(size: 12, weight: .semibold))
          Spacer()
          Button("重置") {
            options = Options()
            modified()
          }.font(.caption).buttonStyle(.plain).foregroundStyle(.secondary)
        }
        ForEach(fields) { field in
          VStack(alignment: .leading, spacing: 7) {
            switch field.kind {
            case .toggle:
              Toggle(
                field.label,
                isOn: Binding(
                  get: { field.read(options) == "true" },
                  set: {
                    field.write(&options, $0 ? "true" : "false")
                    modified()
                  })
              ).toggleStyle(.switch).controlSize(.small)
            case .choice(let choices):
              Text(field.label).font(.callout).foregroundStyle(.secondary)
              Picker(field.label, selection: binding(field)) {
                ForEach(choices, id: \.self) { Text(ToolOptionLabels.title($0)).tag($0) }
              }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading)
            case .secret:
              Text(field.label).font(.callout).foregroundStyle(.secondary)
              SecureField(field.label, text: binding(field)).textFieldStyle(.roundedBorder)
            case .integer(let range):
              Text(field.label).font(.callout).foregroundStyle(.secondary)
              TextField(field.label, text: binding(field)).textFieldStyle(.roundedBorder)
                .help("\(range.lowerBound)–\(range.upperBound)")
            default:
              Text(field.label).font(.callout).foregroundStyle(.secondary)
              TextField(field.label, text: binding(field), axis: .vertical)
                .lineLimit(1...5).textFieldStyle(.roundedBorder)
            }
          }.frame(maxWidth: .infinity, alignment: .leading)
          Divider().opacity(0.6)
        }
      }.padding(18)
    }
  }
  private func binding(_ field: OptionField<Options>) -> Binding<String> {
    Binding(
      get: { field.read(options) },
      set: {
        field.write(&options, $0)
        modified()
      })
  }
}

enum ToolOptionLabels {
  static func title(_ value: String) -> String {
    [
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
