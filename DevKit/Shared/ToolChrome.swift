import DevKitCore
import SwiftUI

func primaryToolField<T: ToolModule>(_ type: T.Type) -> OptionField<T.Options>? {
  guard T.metadata.inputStyle != .generator else { return nil }
  return T.fields.first { if case .choice = $0.kind { return true }; return false }
}

struct ToolPrimaryControl<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  @ViewBuilder var body: some View {
    if let field = primaryToolField(T.self), case .choice(let choices) = field.kind {
      let binding = Binding(get: { field.read(session.options) }, set: { field.write(&session.options, $0) })
      if choices.count <= 3 {
        WorkspaceSegments(items: choices.map { (ToolOptionLabels.title($0), $0) }, selection: binding)
      } else {
        Picker(field.label, selection: binding) {
          ForEach(choices, id: \.self) { Text(ToolOptionLabels.title($0)).tag($0) }
        }.labelsHidden().fixedSize().frame(maxWidth: 180)
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
      Text(T.metadata.network ? "网络工具" : "UTF-8 · 本地处理")
      if session.bridge.running { ProgressView().controlSize(.mini) }
      if !session.status.isEmpty && session.status != "已完成" { Text(session.status).lineLimit(1) }
      Spacer(minLength: 8)
      if session.elapsed > 0 { Text(String(format: "%.0f ms", session.elapsed * 1000)).monospacedDigit() }
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
          Label(mode == .split ? "并排视图" : "单页视图", systemImage: mode == .split ? "rectangle.split.2x1" : "rectangle")
        }.menuStyle(.borderlessButton).fixedSize().help("短内容并排，长内容使用完整面板")
      }
    }.font(.system(size: 11)).foregroundStyle(.secondary)
  }
  private func title(_ value: WorkspaceLayoutPreference) -> String {
    switch value { case .automatic: "自动适应内容"; case .split: "并排视图"; case .focused: "单页视图" }
  }
}
