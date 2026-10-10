import DevKitCore
import SwiftUI

struct SpotlightSettingsView: View {
  @State private var store = SpotlightSettingsStore.shared
  @State private var query = ""
  @State private var selectedID = "base64"
  private var matches: [SpotlightTool] {
    SpotlightCatalog.tools.filter { query.isEmpty || "\($0.name) \($0.id) \(store.preferences.aliases(for: $0.id).joined(separator: " "))".localizedStandardContains(query) }
  }
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Toggle("启用 Spotlight 工具", isOn: Binding(get: { store.preferences.enabled }, set: store.setEnabled))
            .toggleStyle(.switch).font(.headline)
          Text("启用工具后，还需在 Spotlight 为动作设置快捷短语。").font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Button("清空索引并关闭") { store.clearAndDisable() }.disabled(store.updating)
      }.padding(20)
      if let issue = SpotlightRuntimeStatus.current.issue {
        Label(issue, systemImage: "exclamationmark.triangle")
          .font(.callout).foregroundStyle(.orange)
          .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 14)
      }
      Divider()
      HStack(spacing: 0) {
        VStack(spacing: 0) {
          TextField("搜索工具或别名", text: $query).textFieldStyle(.roundedBorder).padding(12)
          List(selection: $selectedID) {
            ForEach(matches) { tool in
              HStack {
                Label(tool.name, systemImage: tool.symbol).font(.system(size: 12))
                Spacer()
                Image(systemName: store.preferences.allows(tool.id) ? "checkmark.circle.fill" : "circle")
                  .font(.system(size: 11))
                  .foregroundStyle(store.preferences.allows(tool.id) ? AnyShapeStyle(Color.green) : AnyShapeStyle(HierarchicalShapeStyle.tertiary))
                  .accessibilityLabel(store.preferences.allows(tool.id) ? "已开启" : "已关闭")
              }.tag(tool.id).padding(.vertical, 6)
            }
          }.listStyle(.sidebar)
        }.frame(width: 214)
        Divider()
        if let tool = SpotlightCatalog.tools.first(where: { $0.id == selectedID }) {
          SpotlightToolSettings(tool: tool, store: store).id(tool.id)
        }
      }
      Divider()
      HStack(spacing: 8) {
        if store.updating { ProgressView().controlSize(.mini) }
        Text(store.status.isEmpty ? "仅索引工具名称与别名，不保存输入或结果。" : store.status).lineLimit(2)
        Spacer()
        Button("重新同步") { store.refresh() }.disabled(store.updating)
      }.font(.caption).foregroundStyle(.secondary).padding(14)
    }
  }
}
private struct SpotlightToolSettings: View {
  let tool: SpotlightTool
  @Bindable var store: SpotlightSettingsStore
  @State private var aliases = ""
  @State private var validation: String?
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Toggle(tool.name, isOn: Binding(get: { store.preferences.tools[tool.id]?.enabled == true }, set: { store.setTool(tool.id, enabled: $0) }))
          .font(.title3.weight(.semibold)).toggleStyle(.switch)
        if !store.preferences.enabled { Text("总开关已关闭，此工具暂不接受 Spotlight 执行。").font(.caption).foregroundStyle(.secondary) }
        setupGuide
        Divider()
        VStack(alignment: .leading, spacing: 8) {
          Text("应用内命令别名").font(.headline)
          HStack {
            TextField("例如 b64, base64", text: $aliases).textFieldStyle(.roundedBorder).onSubmit(save)
              .accessibilityLabel("命令别名")
            Button("保存", action: save)
              .disabled(aliases == store.preferences.aliases(for: tool.id).joined(separator: ", "))
          }
          Text("别名用于“DevKit 命令”动作内，以逗号分隔；不会更改 Spotlight 的系统快捷短语。原工具名 \(tool.id) 始终可用。").font(.caption).foregroundStyle(.secondary)
          if let validation { Text(validation).font(.caption).foregroundStyle(.orange) }
        }
        VStack(alignment: .leading, spacing: 8) {
          Text("在 DevKit 命令中输入").font(.headline)
          Text(tool.example(alias: store.preferences.aliases(for: tool.id).first ?? tool.id))
            .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
          if !tool.operations.isEmpty {
            Text("支持操作：\(tool.operations.joined(separator: "、"))").font(.caption).foregroundStyle(.secondary)
          }
          if tool.id == "base64" {
            Text("enc / dec 也可分别用于 encode / decode。").font(.caption).foregroundStyle(.secondary)
          }
        }
        Divider()
        Text("关闭工具会移除它的工具索引并禁止快捷执行。macOS 仍可能显示已注册的动作名称，但执行时会检查开关；可以在系统 Spotlight 设置中控制应用的显示。").font(.caption).foregroundStyle(.secondary)
      }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }
    .onAppear { aliases = store.preferences.aliases(for: tool.id).joined(separator: ", ") }
  }
  private var setupGuide: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text("首次使用：绑定系统快捷短语").font(.headline)
      if tool.id == "base64" {
        Text("1. 按 ⌘ 空格打开 Spotlight，再按 ⌘3 搜索操作。")
        Text("2. 搜索“Base64 命令”，确认来源为 DevKit。")
        Text("3. 点动作旁的“添加快捷短语”，填入 base64。")
        Text("绑定后输入：base64 encode 123 → MTIz")
          .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
        Text("也可先选择“Base64 命令”，在命令栏填 encode 123；需要逐步选择时，搜索“Base64 编码或解码”。")
          .font(.caption).foregroundStyle(.secondary)
      } else {
        Text("按 ⌘ 空格打开 Spotlight，再按 ⌘3 搜索“DevKit 命令”，为它添加快捷短语，例如 \(store.preferences.quickKeyReminder)。")
        Text("绑定后输入：\(store.preferences.quickKeyReminder) \(tool.example(alias: store.preferences.aliases(for: tool.id).first ?? tool.id))")
          .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
        HStack {
          Text("快捷短语备忘").font(.caption).foregroundStyle(.secondary)
          TextField("dk", text: Binding(get: { store.preferences.quickKeyReminder }, set: store.setQuickKeyReminder))
            .textFieldStyle(.roundedBorder).frame(width: 90)
        }
      }
      Text("输入后应显示 DevKit 的动作参数栏。若只有“搜索网页”或“搜索 iCloud 云盘”，说明仍是普通搜索，尚未进入动作。索引同步不会自动完成绑定。")
        .font(.caption).foregroundStyle(.secondary)
      Link("Apple 快捷短语设置说明", destination: URL(string: "https://support.apple.com/zh-cn/guide/mac-help/mchl4953dfeb/26/mac/26")!)
        .font(.caption)
    }.font(.callout)
  }
  private func save() {
    do { try store.setAliases(aliases, for: tool.id); aliases = store.preferences.aliases(for: tool.id).joined(separator: ", "); validation = nil }
    catch { validation = error.localizedDescription }
  }
}
