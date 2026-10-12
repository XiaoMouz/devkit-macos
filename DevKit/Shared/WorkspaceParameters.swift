import DevKitCore
import SwiftUI

@MainActor extension ToolSession {
  var usesWorkspaceParameters: Bool {
    let form = presentation
    return !form.isForm && !form.isImage && form.control != .request
      && inputStyle != .file && input.file == nil
  }
  var workspaceParameterFields: [OptionField<T.Options>] {
    visibleFields.filter { $0.id != primaryToolField(T.self)?.id }
  }
  var workspaceParameterPlan: WorkspaceParameterPlan {
    WorkspaceParameterPlan(toolID: metadata.id, availableFields: workspaceParameterFields.map(\.id))
  }
}

/// One or two rows above both panes. Measure control labels and fixed minimum
/// widths, never entered values, so typing and execution do not move controls.
struct WorkspaceParameterBar<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  let availableWidth: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    let plan = session.workspaceParameterPlan
    let fields = session.workspaceParameterFields
    let widths = Dictionary(uniqueKeysWithValues: fields.map { field in
      (field.id, Double(CompactParameterField(options: $session.options, field: field,
        toolID: session.metadata.id).minimumWidth))
    })
    let layout = plan.layout(availableWidth: max(0, availableWidth - 24), minimumWidths: widths)
    let overflow = layout.overflow.compactMap { id in fields.first { $0.id == id } }
    VStack(spacing: 4) {
      ForEach(layout.rows.indices, id: \.self) { index in
        HStack(spacing: 0) {
          HStack(spacing: 14) {
            ForEach(layout.rows[index], id: \.self) { id in
              if let field = fields.first(where: { $0.id == id }) {
                CompactParameterField(options: $session.options, field: field,
                  toolID: session.metadata.id, error: session.error)
              }
            }
          }.frame(maxWidth: .infinity, alignment: .leading)
          if index == layout.rows.count - 1 && !overflow.isEmpty {
            OverflowParameterButton(session: session, fields: overflow)
              .padding(.leading, layout.rows[index].isEmpty ? 0 : 14)
          }
        }.frame(height: 32)
      }
    }
    .font(.system(size: 12)).controlSize(.small)
    .padding(.horizontal, 12).padding(.vertical, 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain).accessibilityLabel(L10n.tr("Tool Parameters"))
    .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: layout.rows.count)
  }
}

private struct CompactParameterField<Options: ToolOptions>: View {
  @Binding var options: Options
  let field: OptionField<Options>
  let toolID: String
  var error: String?
  private var binding: Binding<String> {
    Binding(get: { field.read(options) }, set: { field.write(&options, $0) })
  }
  private var label: String {
    switch field.id {
    case "syntax": L10n.tr("Syntax")
    case "path": L10n.tr("Query Path")
    case "name" where toolID == "json": L10n.tr("Type Name")
    case "pattern": L10n.tr("Expression")
    case "replacement": L10n.tr("Replace With")
    default: field.label
    }
  }
  private var placeholder: String {
    if field.id == "path" {
      return (options as? JsonTool.Options)?.syntax == "pointer" ? "/users/0/name" : "$.users[0].name"
    }
    if field.id == "flags" { return "g / i / m" }
    if field.id == "replacement" { return L10n.tr("Leave empty to delete matches") }
    if field.id == "key" { return L10n.tr("Enter a secret key") }
    return label
  }
  private var hint: String {
    if field.id == "path" {
      return (options as? JsonTool.Options)?.syntax == "pointer"
        ? L10n.tr("For example: /users/0/name. Leave empty for the entire document.") : L10n.tr("For example: $.users[0].name. $ selects the entire document.")
    }
    if field.id == "flags" { return L10n.tr("Regex flags such as g (global), i (case insensitive), and m (multiline).") }
    return field.label
  }
  var minimumWidth: CGFloat {
    let labelWidth = (label as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 12)]).width
    switch field.kind {
    case .toggle: return ceil(labelWidth) + 26
    case .choice: return ceil(labelWidth) + 6 + pickerWidth
    case .integer: return ceil(labelWidth) + 80
    default: return field.id == "flags" ? 92 : 180
    }
  }
  @ViewBuilder var body: some View {
    switch field.kind {
    case .toggle:
      Toggle(label, isOn: Binding(get: { field.read(options) == "true" },
        set: { field.write(&options, String($0)) }))
        .toggleStyle(.checkbox).fixedSize().help(hint)
    case .choice(let choices):
      HStack(spacing: 6) {
        Text(label).foregroundStyle(.secondary).fixedSize()
        Picker(label, selection: binding) {
          ForEach(choices, id: \.self) { Text(ToolOptionLabels.title($0)).tag($0) }
        }.labelsHidden().frame(width: pickerWidth).accessibilityLabel(field.label)
      }.fixedSize().help(hint)
    case .integer(let range):
      HStack(spacing: 6) {
        Text(label).foregroundStyle(.secondary).fixedSize()
        TextField(label, value: Binding(get: { Int(field.read(options)) ?? range.lowerBound },
          set: { field.write(&options, String($0)) }),
          format: .number.grouping(.never))
          .textFieldStyle(.roundedBorder).frame(width: 46).accessibilityLabel(field.label)
        Stepper(label, value: Binding(get: { Int(field.read(options)) ?? range.lowerBound },
          set: { field.write(&options, String($0)) }), in: range).labelsHidden().fixedSize()
      }.fixedSize()
    case .secret:
      HStack(spacing: 6) {
        Text(label).foregroundStyle(.secondary).fixedSize()
        SecureField(placeholder, text: binding).textFieldStyle(.roundedBorder)
          .accessibilityLabel(field.label)
          .overlay {
            if error != nil && field.read(options).isEmpty {
              RoundedRectangle(cornerRadius: 5).strokeBorder(.red.opacity(0.65)).allowsHitTesting(false)
            }
          }
      }.frame(minWidth: 180, maxWidth: .infinity).layoutPriority(1)
    default:
      HStack(spacing: 6) {
        Text(label).foregroundStyle(.secondary).fixedSize()
        TextField(placeholder, text: binding).textFieldStyle(.roundedBorder)
          .font(.system(size: 12, design: .monospaced)).accessibilityLabel(field.label)
      }.frame(minWidth: field.id == "flags" ? 92 : 180,
        maxWidth: field.id == "flags" ? 92 : .infinity)
        .layoutPriority(field.id == "flags" ? 0 : 1).help(hint)
    }
  }
  private var pickerWidth: CGFloat {
    switch field.id {
    case "dialect": 128
    case "keyFormat", "output": 92
    default: 110
    }
  }
}

/// Overflow remains editable without losing values. The badge reports changed
/// settings without exposing their content (especially secrets).
struct OverflowParameterButton<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  @State private var presented = false
  let fields: [OptionField<T.Options>]
  private var popoverHeight: CGFloat {
    min(fields.reduce(CGFloat.zero) { height, field in
      switch field.kind {
      case .toggle: return height + 24
      case .integer, .choice: return height + 32
      default: return height + 64
      }
    } + CGFloat(max(0, fields.count - 1)) * 16 + 4, 320)
  }
  private var changedCount: Int {
    let defaults = T.Options()
    return fields.filter { $0.read(session.options) != $0.read(defaults) }.count
  }
  private var title: String { changedCount == 0 ? L10n.tr("More Parameters") : L10n.tr("More Parameters · Changed: \(changedCount)") }
  var body: some View {
    Button { presented.toggle() } label: {
      HStack(spacing: 5) {
        Label(L10n.tr("More"), systemImage: "slider.horizontal.3")
        if changedCount > 0 {
          Text("\(changedCount)").font(.system(size: 10, weight: .medium)).monospacedDigit()
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(.blue.opacity(0.12), in: Capsule()).foregroundStyle(.blue)
        }
      }
    }.buttonStyle(.bordered).buttonBorderShape(.capsule).fixedSize().help(title).accessibilityLabel(title)
      .popover(isPresented: $presented, arrowEdge: .bottom) {
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            Text(L10n.tr("More Parameters")).font(.headline)
            Spacer()
            Button(L10n.tr("Restore Defaults")) {
              var value = session.options
              let defaults = T.Options()
              for field in fields { field.write(&value, field.read(defaults)) }
              session.options = value
            }.disabled(changedCount == 0)
          }
          ScrollView {
            ToolParameterFields(options: $session.options, fields: fields).padding(.vertical, 2)
          }.frame(height: popoverHeight)
        }.buttonStyle(.bordered).buttonBorderShape(.capsule).padding(18).frame(width: 300)
      }
  }
}
