import DevKitCore
import SwiftUI

func primaryToolField<T: ToolModule>(_ type: T.Type) -> OptionField<T.Options>? {
  return T.fields.first {
    guard ["operation", "mode", "language", "format"].contains($0.id) else { return false }
    if case .choice = $0.kind { return true }
    return false
  }
}

struct ToolPrimaryControl<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var inToolbar = true
  @ViewBuilder var body: some View {
    if let field = primaryToolField(T.self), case .choice(let choices) = field.kind {
      let binding = Binding(get: { field.read(session.options) }, set: { field.write(&session.options, $0) })
      if choices.count <= 3 {
        WorkspaceSegments(items: choices.map { (ToolOptionLabels.title($0), $0) }, selection: binding,
          symbols: Dictionary(uniqueKeysWithValues: choices.compactMap { value in
            ToolOptionLabels.symbol(value).map { (value, $0) }
          }), inToolbar: inToolbar)
      } else if inToolbar {
        // A toolbar pull-down: one glass item with a disclosure chevron. A pop-up
        // button here would nest its own bezel and stepper arrows inside the glass.
        Menu {
          Picker(field.label, selection: binding) {
            ForEach(choices, id: \.self) { value in
              Label(ToolOptionLabels.title(value), systemImage: ToolOptionLabels.symbol(value) ?? "circle")
                .tag(value)
            }
          }.pickerStyle(.inline).labelsHidden()
        } label: {
          Label(ToolOptionLabels.title(binding.wrappedValue),
            systemImage: ToolOptionLabels.symbol(binding.wrappedValue) ?? "slider.horizontal.3")
            .labelStyle(.titleAndIcon).padding(.horizontal, 8)
        }.menuIndicator(.visible).fixedSize().help(field.label)
      } else {
        Picker(field.label, selection: binding) {
          ForEach(choices, id: \.self) { Text(ToolOptionLabels.title($0)).tag($0) }
        }.labelsHidden().fixedSize()
      }
    }
  }
}

struct ToolConfiguration<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var body: some View {
    ToolOptionsForm(options: $session.options,
      fields: T.fields.filter { $0.id != primaryToolField(T.self)?.id }, modified: {})
  }
}

struct ToolFooter<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  private var mode: WorkspaceLayoutMode { session.layoutPolicy.mode(width: session.bridge.workspaceWidth) }
  var body: some View {
    HStack(spacing: 10) {
      Text(T.metadata.network ? L10n.tr("Network Tool") : session.inputStyle == .file || T.metadata.id == "data-url" ? L10n.tr("Local Processing") : L10n.tr("UTF-8 · Local Processing"))
      if session.bridge.running { ProgressView().controlSize(.mini) }
      if !session.status.isEmpty && session.status != L10n.tr("Completed") { Text(session.status).lineLimit(1) }
      Spacer(minLength: 8)
      if let elapsed = elapsedLabel(session.elapsed) { Text(elapsed).monospacedDigit() }
      if T.metadata.inputStyle != .generator {
        Menu {
          ForEach(WorkspaceLayoutPreference.allCases, id: \.self) { value in
            Button {
              session.chooseLayout(value)
            } label: {
              if session.layoutPolicy.preference == value { Label(title(value), systemImage: "checkmark") }
              else { Text(title(value)) }
            }.disabled(value == .split && session.bridge.workspaceWidth < WorkspaceLayoutPolicy.minimumSplitWidth)
          }
        } label: {
          Label(mode == .split ? L10n.tr("Side-by-Side View") : L10n.tr("Single-Pane View"), systemImage: mode == .split ? "rectangle.split.2x1" : "rectangle")
        }.menuStyle(.borderlessButton).fixedSize().help(L10n.tr("Show short content side by side; use a full pane for long content"))
      }
    }.font(.system(size: 11)).foregroundStyle(.secondary)
  }
  private func title(_ value: WorkspaceLayoutPreference) -> String {
    switch value { case .automatic: L10n.tr("Fit Content Automatically"); case .split: L10n.tr("Side-by-Side View"); case .focused: L10n.tr("Single-Pane View") }
  }
}
