import AppKit
import DevKitCore
import SwiftUI

struct ColorValueControl: View {
  let title: String
  @Binding var text: String
  var supportsOpacity = true
  private var color: Binding<Color> {
    Binding(get: {
      guard let value = try? ColorValue.parse(text) else { return .accentColor }
      return Color(.sRGB, red: value.r, green: value.g, blue: value.b, opacity: value.a)
    }, set: { value in
      guard let color = NSColor(value).usingColorSpace(.sRGB) else { return }
      let channels = [color.redComponent, color.greenComponent, color.blueComponent]
      text = "#" + channels.map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined()
      if supportsOpacity && color.alphaComponent < 1 { text += String(format: "%02X", Int((color.alphaComponent * 255).rounded())) }
    })
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ColorPicker(title, selection: color, supportsOpacity: supportsOpacity)
      TextField("#3478F6 / rgb() / hsl()", text: $text).textFieldStyle(.roundedBorder)
        .font(.system(.body, design: .monospaced)).accessibilityLabel(title + "色值")
      RoundedRectangle(cornerRadius: 10).fill(color.wrappedValue).frame(height: 72)
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(.separator) }
    }
  }
}

struct DateValueControl: View {
  let title: String
  @Binding var text: String
  private var date: Binding<Date> {
    Binding(get: { Dates.parse(text) ?? Date() }, set: { text = Dates.iso($0) })
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      DatePicker(title, selection: date, displayedComponents: [.date, .hourAndMinute])
      HStack {
        TextField("ISO 8601（含时区）", text: $text).textFieldStyle(.roundedBorder)
          .font(.system(.body, design: .monospaced)).accessibilityLabel(title + " ISO 日期")
        Button { text = Dates.iso(Date()) } label: { Label("现在", systemImage: "clock") }.buttonStyle(.bordered)
      }
    }
  }
}

/// Ordered rows keep duplicate query keys and distinguish a flag from an empty value.
struct KeyValueEditor: View {
  enum Kind { case query, headers, template }
  struct Entry: Identifiable, Equatable {
    var id = UUID()
    var name = ""
    var value = ""
    var hasValue = true
  }
  @Binding var text: String
  var kind: Kind = .query
  @State private var rows: [Entry] = []
  @State private var serialized = ""
  @State private var sourceRows: [Entry] = []
  @State private var error: String?
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach($rows) { $row in
        HStack(alignment: .center, spacing: 8) {
          TextField(kind == .headers ? "Header" : "名称", text: $row.name)
            .accessibilityLabel(kind == .headers ? "请求头名称" : "字段名称")
          if kind == .template {
            Picker("字段类型", selection: $row.value) {
              ForEach(["index", "name", "email", "boolean", "integer", "uuid"], id: \.self) { type in
                Text(ToolOptionLabels.title(type)).tag(type)
              }
            }.labelsHidden()
          } else {
            TextField("值", text: $row.value).disabled(!row.hasValue)
              .accessibilityLabel(kind == .headers ? "请求头值" : "参数值")
          }
          if kind == .query { Toggle("有值", isOn: $row.hasValue).toggleStyle(.checkbox).fixedSize() }
          Button { rows.removeAll { $0.id == row.id } } label: { Image(systemName: "minus.circle") }
            .buttonStyle(.plain).accessibilityLabel("删除这一行")
        }.textFieldStyle(.roundedBorder)
      }
      Button { rows.append(Entry(value: kind == .template ? "name" : "")) } label: {
        Label(kind == .headers ? "添加请求头" : "添加字段", systemImage: "plus")
      }.buttonStyle(.bordered)
      if let error { Text(error).font(.caption).foregroundStyle(.orange) }
    }
    .onAppear { read() }
    .onChange(of: text) { _, value in if value != serialized { read() } }
    .onChange(of: rows) { _, value in if value != sourceRows { write() } }
  }
  private func read() {
    serialized = text
    defer { sourceRows = rows }
    guard !text.isEmpty else { rows = []; error = nil; return }
    do {
      let object = try JSONSerialization.jsonObject(with: Data(text.utf8))
      if kind == .query, let values = object as? [[String: Any]] {
        rows = values.map { Entry(name: $0["name"] as? String ?? "", value: $0["value"] as? String ?? "", hasValue: $0["value"] is String) }
      } else if kind != .query, let values = object as? [String: String] {
        rows = values.keys.sorted().map { Entry(name: $0, value: values[$0]!) }
      } else { throw ToolFailure("字段格式无效。") }
      error = nil
    } catch { self.error = "无法读取字段，请清空后重新添加。"; rows = [] }
  }
  private func write() {
    let active = rows.filter { !$0.name.isEmpty || !$0.value.isEmpty }
    let names = active.map { kind == .headers ? $0.name.lowercased() : $0.name }
    if kind != .query && Set(names).count != active.count {
      error = "名称不能重复。"
      // Keep the execution input invalid until the duplicate is fixed.
      serialized = "[重复字段]"; text = serialized
      return
    }
    if kind != .query && active.contains(where: { $0.name.isEmpty }) {
      error = "请填写名称。"; serialized = "[缺少字段名称]"; text = serialized
      return
    }
    let value: Any
    if kind == .query {
      value = active.map { ["name": $0.name, "value": $0.hasValue ? $0.value as Any : NSNull()] }
    } else { value = Dictionary(uniqueKeysWithValues: active.map { ($0.name, $0.value) }) }
    if let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
      let string = String(data: data, encoding: .utf8) {
      serialized = string
      if text != string { text = string }
      error = nil
    }
  }
}

struct ToolParameterFields<Options: ToolOptions>: View {
  @Binding var options: Options
  let fields: [OptionField<Options>]
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(fields) { field in
        fieldView(field)
      }
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
  @ViewBuilder private func fieldView(_ field: OptionField<Options>) -> some View {
    if field.id == "headers" {
      VStack(alignment: .leading, spacing: 8) {
        Text("请求头").font(.callout.weight(.medium))
        KeyValueEditor(text: binding(field), kind: .headers)
      }
    } else if field.id == "background" {
      ColorValueControl(title: field.label, text: binding(field), supportsOpacity: false)
    } else if ["start", "other"].contains(field.id) {
      DateValueControl(title: field.id == "start" ? "起始时间" : "对比日期", text: binding(field))
    } else {
      switch field.kind {
      case .toggle:
        Toggle(field.label, isOn: Binding(get: { field.read(options) == "true" }, set: { field.write(&options, String($0)) }))
          .toggleStyle(.switch).controlSize(.small)
      case .choice(let choices):
        Picker(field.label, selection: binding(field)) {
          ForEach(choices, id: \.self) { Text(ToolOptionLabels.title($0)).tag($0) }
        }
      case .integer(let range):
        HStack {
          Text(field.label)
          Spacer(minLength: 10)
          TextField(field.label, value: Binding(get: { Int(field.read(options)) ?? range.lowerBound }, set: { field.write(&options, String($0)) }), format: .number.grouping(.never))
            .textFieldStyle(.roundedBorder).frame(width: 95)
          Stepper(field.label, value: Binding(get: { Int(field.read(options)) ?? range.lowerBound }, set: { field.write(&options, String($0)) }), in: range)
            .labelsHidden().fixedSize()
        }
      case .secret:
        VStack(alignment: .leading, spacing: 6) {
          Text(field.label).font(.caption).foregroundStyle(.secondary)
          SecureField(field.label, text: binding(field)).textFieldStyle(.roundedBorder)
        }
      default:
        VStack(alignment: .leading, spacing: 6) {
          Text(field.label).font(.caption).foregroundStyle(.secondary)
          HStack {
            TextField(field.label, text: binding(field)).textFieldStyle(.roundedBorder)
              .font(.system(.body, design: .monospaced))
            if ["timezone", "zone"].contains(field.id) {
              Menu("选择") {
                ForEach(Array(Set([TimeZone.current.identifier, "UTC", "Asia/Shanghai", "Asia/Tokyo", "Europe/London", "Europe/Paris", "America/New_York", "America/Los_Angeles"])).sorted(), id: \.self) { zone in
                  Button(zone) { field.write(&options, zone) }
                }
              }.fixedSize()
            }
          }
        }
      }
    }
  }
  private func binding(_ field: OptionField<Options>) -> Binding<String> {
    Binding(get: { field.read(options) }, set: { field.write(&options, $0) })
  }
}
