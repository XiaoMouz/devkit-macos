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
      ToolFormRow(title: title) { ColorPicker(title, selection: color, supportsOpacity: supportsOpacity).labelsHidden() }
      TextField("#3478F6 / rgb() / hsl()", text: $text).textFieldStyle(.roundedBorder)
        .font(.system(.body, design: .monospaced)).accessibilityLabel(title + "色值")
      RoundedRectangle(cornerRadius: 10).fill(color.wrappedValue).frame(height: 72)
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(.separator) }
    }
  }
}

/// A common label column keeps form labels and controls aligned across tools.
struct ToolFormRow<Content: View>: View {
  let title: String
  @ViewBuilder var content: () -> Content
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(title).font(.callout).foregroundStyle(.secondary)
        .frame(width: 92, alignment: .leading).padding(.top, 4)
      content().frame(maxWidth: .infinity, alignment: .leading).layoutPriority(1)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Native menu items are created only when the menu opens, not as hundreds of
/// SwiftUI subgraphs in every date/time tool and every hidden layout candidate.
struct TimeZoneControl: NSViewRepresentable {
  let title: String
  @Binding var selection: String
  @Environment(\.isEnabled) private var isEnabled
  private static let entries = Dates.timeZoneIdentifiers.map { identifier in
    let zone = TimeZone(identifier: identifier)!
    let name = zone.localizedName(for: .generic, locale: Locale(identifier: "zh_CN")) ?? identifier
    return (identifier, name + " · " + identifier)
  }
  private static let common = Set([TimeZone.current.identifier, "UTC", "Asia/Shanghai", "Asia/Hong_Kong",
    "Asia/Tokyo", "Asia/Singapore", "Europe/London", "Europe/Paris", "America/New_York", "America/Los_Angeles", "Australia/Sydney"])
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  func makeNSView(context: Context) -> NSPopUpButton {
    let button = NSPopUpButton(frame: .zero, pullsDown: false)
    button.target = context.coordinator
    button.action = #selector(Coordinator.changed(_:))
    button.menu?.autoenablesItems = false
    button.menu?.delegate = context.coordinator
    context.coordinator.button = button
    return button
  }
  func updateNSView(_ button: NSPopUpButton, context: Context) {
    context.coordinator.parent = self
    button.isEnabled = isEnabled
    button.setAccessibilityLabel(title)
    button.toolTip = "从列表选择时区；日期显示会同步使用所选时区。"
    guard button.selectedItem?.representedObject as? String != selection else { return }
    if let item = button.itemArray.first(where: { $0.representedObject as? String == selection }) {
      button.select(item)
    } else {
      button.removeAllItems()
      let zone = TimeZone(identifier: selection)
      let name = zone?.localizedName(for: .generic, locale: Locale(identifier: "zh_CN")) ?? selection
      button.addItem(withTitle: name + " · " + selection)
      button.lastItem?.representedObject = selection
    }
  }
  func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
    CGSize(width: max(160, proposal.width ?? 240), height: nsView.intrinsicContentSize.height)
  }
  @MainActor final class Coordinator: NSObject, NSMenuDelegate {
    var parent: TimeZoneControl
    weak var button: NSPopUpButton?
    init(_ parent: TimeZoneControl) { self.parent = parent }
    func menuNeedsUpdate(_ menu: NSMenu) {
      guard menu.items.count <= 1, let button else { return }
      menu.removeAllItems()
      for (heading, common) in [("常用时区", true), ("所有时区", false)] {
        let section = NSMenuItem(title: heading, action: nil, keyEquivalent: "")
        section.isEnabled = false
        menu.addItem(section)
        for entry in TimeZoneControl.entries where TimeZoneControl.common.contains(entry.0) == common {
          let item = NSMenuItem(title: entry.1, action: #selector(selected(_:)), keyEquivalent: "")
          item.target = self
          item.representedObject = entry.0
          menu.addItem(item)
        }
      }
      button.select(menu.items.first { $0.representedObject as? String == parent.selection })
    }
    @objc func selected(_ item: NSMenuItem) {
      guard let identifier = item.representedObject as? String, identifier != parent.selection else { return }
      parent.selection = identifier
    }
    @objc func changed(_ sender: NSPopUpButton) {
      guard let identifier = sender.selectedItem?.representedObject as? String,
        identifier != parent.selection else { return }
      parent.selection = identifier
    }
  }
}

struct DateValueControl: View {
  let title: String
  @Binding var text: String
  var timeZone: TimeZone = .current
  var allowsCurrent = false
  @State private var fallback = Date()
  @State private var calendarPresented = false
  private var date: Binding<Date> {
    Binding(get: { Dates.parse(text, timeZone: timeZone) ?? fallback }, set: { text = Dates.iso($0) })
  }
  var body: some View {
    ToolFormRow(title: title) {
      VStack(alignment: .leading, spacing: 8) {
        if allowsCurrent {
          Toggle("执行时使用当前时间", isOn: Binding(get: { text.isEmpty }, set: { text = $0 ? "" : Dates.iso(Date()) }))
            .toggleStyle(.checkbox)
        }
        HStack(spacing: 8) {
          if allowsCurrent && text.isEmpty {
            Text("执行时取当前时间").font(.system(size: 12, design: .monospaced))
              .foregroundStyle(.tertiary).frame(width: 230, height: 26, alignment: .leading)
              .accessibilityLabel(title)
          } else {
            NativeDateTimePicker(date: date, timeZone: timeZone, title: title)
              .frame(width: 230, height: 26)
          }
          Button { calendarPresented = true } label: { Image(systemName: "calendar") }
            .buttonStyle(.bordered).buttonBorderShape(.capsule).help("打开日历选择日期").accessibilityLabel(title + "选择日期")
            .popover(isPresented: $calendarPresented) {
              VStack(alignment: .leading, spacing: 12) {
                DatePicker(title, selection: date, in: Dates.supportedRange, displayedComponents: [.date])
                  .datePickerStyle(.graphical).labelsHidden()
                  .environment(\.timeZone, timeZone).environment(\.locale, Locale(identifier: "zh_CN"))
                Button("完成") { calendarPresented = false }.buttonStyle(.bordered)
              }.padding(16).frame(width: 290)
            }
          Button { text = Dates.iso(Date()) } label: { Image(systemName: "clock") }
            .buttonStyle(.bordered).buttonBorderShape(.capsule).help("使用现在的日期时间").accessibilityLabel(title + "设为现在")
        }
        if !text.isEmpty && Dates.parse(text, timeZone: timeZone) == nil {
          Text("日期无效，请重新选择日期时间。").font(.caption).foregroundStyle(.red)
        }
        Text(Dates.zoneLabel(timeZone, at: date.wrappedValue)).font(.caption).foregroundStyle(.secondary)
      }
    }
    .onAppear { if text.isEmpty && !allowsCurrent { text = Dates.iso(fallback) } }
  }
}

/// Native calendar overlay plus editable year/month/day/hour/minute/second fields.
private struct NativeDateTimePicker: NSViewRepresentable {
  @Binding var date: Date
  let timeZone: TimeZone
  let title: String
  @Environment(\.isEnabled) private var isEnabled
  func makeNSView(context: Context) -> NSDatePicker {
    let picker = NSDatePicker()
    picker.datePickerStyle = .textFieldAndStepper
    picker.datePickerElements = [.yearMonthDay, .hourMinuteSecond]
    picker.presentsCalendarOverlay = true
    picker.locale = Locale(identifier: "zh_CN")
    picker.calendar = Calendar(identifier: .gregorian)
    picker.isBezeled = true
    picker.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    picker.minDate = Dates.supportedRange.lowerBound
    picker.maxDate = Dates.supportedRange.upperBound
    picker.target = context.coordinator
    picker.action = #selector(Coordinator.changed(_:))
    return picker
  }
  func updateNSView(_ picker: NSDatePicker, context: Context) {
    context.coordinator.parent = self
    if picker.timeZone != timeZone {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = timeZone
      picker.calendar = calendar
      picker.timeZone = timeZone
    }
    picker.isEnabled = isEnabled
    picker.setAccessibilityLabel(title)
    if picker.dateValue != date { picker.dateValue = date }
  }
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  @MainActor final class Coordinator: NSObject {
    var parent: NativeDateTimePicker
    init(_ parent: NativeDateTimePicker) { self.parent = parent }
    @objc func changed(_ sender: NSDatePicker) { parent.date = sender.dateValue }
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
      }.buttonStyle(.bordered).buttonBorderShape(.capsule)
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
  private var timeZone: TimeZone {
    let identifier = (options as? CronTool.Options)?.timezone
      ?? (options as? TimestampTool.Options)?.timezone ?? (options as? DateTimeTool.Options)?.zone
      ?? TimeZone.current.identifier
    return TimeZone(identifier: identifier) ?? .current
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      ForEach(fields) { field in fieldView(field) }
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
    } else if ["timezone", "zone", "sourceZone"].contains(field.id) {
      ToolFormRow(title: field.label) { TimeZoneControl(title: field.label, selection: binding(field)) }
    } else if ["start", "other"].contains(field.id) {
      DateValueControl(title: field.id == "start" ? "起始时间" : "对比日期", text: binding(field), timeZone: timeZone, allowsCurrent: field.id == "start")
    } else {
      ToolFormRow(title: field.label) {
        switch field.kind {
        case .toggle:
          Toggle(field.label, isOn: Binding(get: { field.read(options) == "true" }, set: { field.write(&options, String($0)) }))
            .labelsHidden().toggleStyle(.switch).controlSize(.small).accessibilityLabel(field.label)
        case .choice(let choices):
          Picker(field.label, selection: binding(field)) {
            ForEach(choices, id: \.self) { Text(ToolOptionLabels.title($0)).tag($0) }
          }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading).accessibilityLabel(field.label)
        case .integer(let range):
          HStack(spacing: 8) {
            TextField(field.label, value: Binding(get: { Int(field.read(options)) ?? range.lowerBound }, set: { field.write(&options, String($0)) }), format: .number.grouping(.never))
              .textFieldStyle(.roundedBorder).frame(width: 100)
            Stepper(field.label, value: Binding(get: { Int(field.read(options)) ?? range.lowerBound }, set: { field.write(&options, String($0)) }), in: range)
              .labelsHidden().fixedSize().accessibilityLabel(field.label)
          }
        case .secret:
          SecureField(field.label, text: binding(field)).textFieldStyle(.roundedBorder)
        default:
          TextField(field.label, text: binding(field)).textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
        }
      }
    }
  }
  private func binding(_ field: OptionField<Options>) -> Binding<String> {
    Binding(get: { field.read(options) }, set: { field.write(&options, $0) })
  }
}
