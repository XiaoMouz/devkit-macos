import DevKitCore
import SwiftUI

struct SettingsView: View {
  @AppStorage("appearance") private var appearance = "system"
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @AppStorage("wrapLines") private var wrap = true
  var body: some View {
    TabView {
      Form {
        Section("外观") {
          Picker("主题", selection: $appearance) {
            Text("跟随系统").tag("system")
            Text("浅色").tag("light")
            Text("深色").tag("dark")
          }
          Text("Liquid Glass 的透明度跟随“系统设置 → 外观”和辅助功能中的“减少透明度”。")
            .font(.caption).foregroundStyle(.secondary)
        }
        Section("编辑器") {
          Slider(value: $fontSize, in: 11...22, step: 1) { Text("字号 \(Int(fontSize))") }
          Toggle("自动换行", isOn: $wrap)
        }
      }.formStyle(.grouped).tabItem { Label("通用", systemImage: "gearshape") }
      SpotlightSettingsView().tabItem { Label("Spotlight", systemImage: "magnifyingglass") }
      AutomationSettingsView().tabItem { Label("CLI 与 AI", systemImage: "terminal") }
      VStack(spacing: 12) {
        Image(nsImage: NSApp.applicationIconImage).resizable().scaledToFit().frame(width: 96, height: 96)
          .accessibilityHidden(true)
        Text("DevKit").font(.title.bold())
        Text("原生 macOS Web 开发者工具箱").foregroundStyle(.secondary)
        HStack(spacing: 14) {
          Label("\(ToolRegistry.all.count) 个工具", systemImage: "square.grid.2x2")
          Label("本地处理", systemImage: "lock.shield")
        }.font(.callout).foregroundStyle(.secondary).padding(.top, 4)
        Text("0.1.0 · macOS 26+").font(.caption).foregroundStyle(.tertiary)
      }.frame(maxWidth: .infinity, maxHeight: .infinity).tabItem { Label("关于", systemImage: "info.circle") }
    }.frame(width: 800, height: 610)
      .onChange(of: appearance) { _, value in AppAppearance.apply(value) }
  }
}
