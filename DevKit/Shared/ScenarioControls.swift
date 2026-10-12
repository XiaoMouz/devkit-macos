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
        .font(.system(.body, design: .monospaced)).accessibilityLabel(title + L10n.tr("Color Value"))
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
struct TimeZoneControl: View {
  let title: String
  @Binding var selection: String
  @State private var searching = false
  @State private var query = ""
  var body: some View {
    HStack(spacing: 6) {
      NativeTimeZoneMenu(title: title, selection: $selection)
      Button { searching = true; query = "" } label: { Image(systemName: "magnifyingglass") }
        .accessibilityLabel(L10n.tr("Search") + title).help(L10n.tr("Search by city, time zone identifier, or offset"))
        .popover(isPresented: $searching) {
          VStack(spacing: 10) {
            TextField(L10n.tr("Search cities, identifiers, or UTC offsets"), text: $query).textFieldStyle(.roundedBorder)
            let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let now = Date()
            let matches = NativeTimeZoneMenu.entries.filter { entry in
              let offset = Dates.offsetLabel(TimeZone(identifier: entry.0)!, at: now)
              if term.uppercased() == "UTC" { return offset == "UTC" }
              return term.isEmpty || (entry.1 + " " + offset).localizedCaseInsensitiveContains(term)
            }.sorted { lhs, rhs in
              let leftExact = lhs.0.caseInsensitiveCompare(term) == .orderedSame
              let rightExact = rhs.0.caseInsensitiveCompare(term) == .orderedSame
              if leftExact != rightExact { return leftExact }
              return lhs.0 < rhs.0
            }
            ScrollView {
              LazyVStack(alignment: .leading) {
                ForEach(matches, id: \.0) { entry in
                  Button { selection = entry.0; searching = false } label: {
                    Text(entry.1).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                  }.buttonStyle(.plain)
                }
                if matches.isEmpty { Text(L10n.tr("No Matching Time Zones")).foregroundStyle(.secondary) }
              }
            }
          }.padding(14).frame(width: 380, height: 360)
        }
    }
  }
}

private struct NativeTimeZoneMenu: NSViewRepresentable {
  let title: String
  @Binding var selection: String
  @Environment(\.isEnabled) private var isEnabled
  private static var cachedEntries: [String: [(String, String)]] = [:]
  static var entries: [(String, String)] {
    let language = L10n.language
    if let cached = cachedEntries[language] { return cached }
    let values = Dates.timeZoneIdentifiers.map { identifier in
      let zone = TimeZone(identifier: identifier)!
      let name = zone.localizedName(for: .generic, locale: L10n.locale) ?? identifier
      return (identifier, name + " · " + identifier)
    }
    cachedEntries[language] = values
    return values
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
    button.toolTip = L10n.tr("Choose a time zone from the list. Dates will display in that time zone.")
    if context.coordinator.language != L10n.language {
      context.coordinator.language = L10n.language
      button.removeAllItems()
    }
    guard button.selectedItem?.representedObject as? String != selection else { return }
    if let item = button.itemArray.first(where: { $0.representedObject as? String == selection }) {
      button.select(item)
    } else {
      button.removeAllItems()
      let zone = TimeZone(identifier: selection)
      let name = zone?.localizedName(for: .generic, locale: L10n.locale) ?? selection
      button.addItem(withTitle: name + " · " + selection)
      button.lastItem?.representedObject = selection
    }
  }
  func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
    CGSize(width: max(160, proposal.width ?? 240), height: nsView.intrinsicContentSize.height)
  }
  @MainActor final class Coordinator: NSObject, NSMenuDelegate {
    var language = ""
    var parent: NativeTimeZoneMenu
    weak var button: NSPopUpButton?
    init(_ parent: NativeTimeZoneMenu) { self.parent = parent }
    func menuNeedsUpdate(_ menu: NSMenu) {
      guard menu.items.count <= 1, let button else { return }
      menu.removeAllItems()
      for (heading, common) in [(L10n.tr("Common Time Zones"), true), (L10n.tr("All Time Zones"), false)] {
        let section = NSMenuItem(title: heading, action: nil, keyEquivalent: "")
        section.isEnabled = false
        menu.addItem(section)
        for entry in NativeTimeZoneMenu.entries where NativeTimeZoneMenu.common.contains(entry.0) == common {
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
          Toggle(L10n.tr("Use the current time when running"), isOn: Binding(get: { text.isEmpty }, set: { text = $0 ? "" : Dates.iso(Date()) }))
            .toggleStyle(.checkbox)
        }
        HStack(spacing: 8) {
          if allowsCurrent && text.isEmpty {
            Text(L10n.tr("Use Current Time on Run")).font(.system(size: 12, design: .monospaced))
              .foregroundStyle(.tertiary).frame(width: 230, height: 26, alignment: .leading)
              .accessibilityLabel(title)
          } else {
            NativeDateTimePicker(date: date, timeZone: timeZone, title: title)
              .frame(width: 230, height: 26)
          }
          Button { calendarPresented = true } label: { Image(systemName: "calendar") }
            .buttonStyle(.bordered).buttonBorderShape(.capsule).help(L10n.tr("Open the calendar to choose a date")).accessibilityLabel(title + L10n.tr("Choose Date"))
            .popover(isPresented: $calendarPresented) {
              VStack(alignment: .leading, spacing: 12) {
                DatePicker(title, selection: date, in: Dates.supportedRange, displayedComponents: [.date])
                  .datePickerStyle(.graphical).labelsHidden()
                  .environment(\.timeZone, timeZone).environment(\.locale, L10n.locale)
                Button(L10n.tr("Done")) { calendarPresented = false }.buttonStyle(.bordered)
              }.padding(16).frame(width: 290)
            }
          Button { text = Dates.iso(Date()) } label: { Image(systemName: "clock") }
            .buttonStyle(.bordered).buttonBorderShape(.capsule).help(L10n.tr("Use the current date and time")).accessibilityLabel(title + L10n.tr("Set to Now"))
        }
        if !text.isEmpty && Dates.parse(text, timeZone: timeZone) == nil {
          Text(L10n.tr("Invalid date. Choose the date and time again.")).font(.caption).foregroundStyle(.red)
        }
        Text(Dates.display(date.wrappedValue, timeZone: timeZone, milliseconds: true))
          .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
          .accessibilityLabel(L10n.tr("Full date and time (including milliseconds)"))
          .accessibilityValue(Dates.display(date.wrappedValue, timeZone: timeZone, milliseconds: true))
        Text(Dates.zoneLabel(timeZone, at: date.wrappedValue)).font(.caption).foregroundStyle(.secondary)
        Text(L10n.tr("Times skipped by daylight saving changes are not accepted. Repeated times use the first occurrence. Editing the date control resets milliseconds to zero."))
          .font(.caption).foregroundStyle(.tertiary)
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
    picker.locale = L10n.locale
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
    if picker.locale != L10n.locale { picker.locale = L10n.locale }
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
    @objc func changed(_ sender: NSDatePicker) {
      // This control edits whole seconds. Do not preserve invisible fractions.
      parent.date = Date(timeIntervalSince1970: floor(sender.dateValue.timeIntervalSince1970))
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
          TextField(kind == .headers ? "Header" : L10n.tr("Name"), text: $row.name)
            .accessibilityLabel(kind == .headers ? L10n.tr("Header Name") : L10n.tr("Field Name"))
          if kind == .template {
            Picker(L10n.tr("Field Type"), selection: $row.value) {
              ForEach(["index", "name", "email", "boolean", "integer", "uuid"], id: \.self) { type in
                Text(ToolOptionLabels.title(type)).tag(type)
              }
            }.labelsHidden()
          } else {
            TextField(L10n.tr("Value"), text: $row.value).disabled(!row.hasValue)
              .accessibilityLabel(kind == .headers ? L10n.tr("Header Value") : L10n.tr("Parameter Value"))
          }
          if kind == .query { Toggle(L10n.tr("Has a value"), isOn: $row.hasValue).toggleStyle(.checkbox).fixedSize() }
          Button { rows.removeAll { $0.id == row.id } } label: { Image(systemName: "minus.circle") }
            .buttonStyle(.plain).accessibilityLabel(L10n.tr("Delete This Row"))
        }.textFieldStyle(.roundedBorder)
      }
      Button { rows.append(Entry(value: kind == .template ? "name" : "")) } label: {
        Label(kind == .headers ? L10n.tr("Add Header") : L10n.tr("Add Field"), systemImage: "plus")
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
      if let values = object as? [[String: Any]] {
        rows = values.map { Entry(name: $0["name"] as? String ?? "", value: $0["value"] as? String ?? "", hasValue: $0["value"] is String) }
      } else if kind != .query, let values = object as? [String: String] {
        rows = values.keys.sorted().map { Entry(name: $0, value: values[$0]!) }
      } else { throw ToolFailure(L10n.tr("Invalid field format.")) }
      error = nil
    } catch { self.error = L10n.tr("Could not read fields. Clear them and add them again."); rows = [] }
  }
  private func write() {
    let active = rows.filter { !$0.name.isEmpty || !$0.value.isEmpty }
    let names = active.map { kind == .headers ? $0.name.lowercased() : $0.name }
    let validationError: String? = kind == .query ? nil
      : Set(names).count != active.count ? L10n.tr("Names must be unique.")
      : active.contains(where: { $0.name.isEmpty }) ? L10n.tr("Enter a name.") : nil
    // Keep the editable rows even when invalid. The core validates these rows
    // before generating data or sending a request; never serialize error prose.
    let value: Any = active.map { ["name": $0.name, "value": $0.hasValue ? $0.value as Any : NSNull()] }
    if let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
      let string = String(data: data, encoding: .utf8) {
      serialized = string
      if text != string { text = string }
      error = validationError
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
        Text(L10n.tr("Headers")).font(.callout.weight(.medium))
        KeyValueEditor(text: binding(field), kind: .headers)
      }
    } else if field.id == "background" {
      ColorValueControl(title: field.label, text: binding(field), supportsOpacity: false)
    } else if ["timezone", "zone", "sourceZone"].contains(field.id) {
      ToolFormRow(title: field.label) { TimeZoneControl(title: field.label, selection: binding(field)) }
    } else if ["start", "other"].contains(field.id) {
      DateValueControl(title: field.id == "start" ? L10n.tr("Start Time") : L10n.tr("Comparison Date"), text: binding(field), timeZone: timeZone, allowsCurrent: field.id == "start")
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

/// Decode each image revision once off the main actor, at preview resolution.
struct RasterImagePreview: View {
  let data: Data
  var pixelated = false
  @State private var image: CGImage?
  @State private var completed = false
  var body: some View {
    Group {
      if let image { Image(decorative: image, scale: 1).resizable().interpolation(pixelated ? .none : .high).scaledToFit() }
      else if completed { Text(L10n.tr("Preview unavailable. You can still export the original file.")).foregroundStyle(.secondary) }
      else { ProgressView().controlSize(.small) }
    }.task(id: data) {
      completed = false
      let thumbnail = await RasterThumbnailLoader.shared.thumbnail(data)
      guard !Task.isCancelled else { return }
      image = thumbnail
      completed = true
    }.onDisappear {
      image = nil
      Task { await IdleMemoryCleanup.shared.schedule() }
    }
  }
}
