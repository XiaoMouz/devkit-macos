import DevKitCore
import SwiftUI

struct SettingsView: View {
  @AppStorage("appearance") private var appearance = "system"
  @AppStorage("glassMode") private var glassMode = GlassMode.system.rawValue
  @AppStorage("glassTransparency") private var transparency = 0.55
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
          Picker("Liquid Glass", selection: $glassMode) {
            Text("跟随系统").tag(GlassMode.system.rawValue)
            Text("自定义").tag(GlassMode.custom.rawValue)
          }
          if glassMode == GlassMode.custom.rawValue {
            Slider(value: Binding(get: { 1 - transparency }, set: { transparency = 1 - $0 }), in: 0...1, step: 0.01) {
              Text("磨砂强度 \(Int(((1 - transparency) * 100).rounded()))%")
            }.accessibilityLabel("玻璃磨砂强度")
            HStack {
              Text("通透")
              Spacer()
              Text("磨砂")
            }.font(.caption).foregroundStyle(.secondary)
          }
        }
        Section("编辑器") {
          Slider(value: $fontSize, in: 11...22, step: 1) { Text("字号 \(Int(fontSize))") }
          Toggle("自动换行", isOn: $wrap)
        }
      }.formStyle(.grouped).tabItem { Label("通用", systemImage: "gearshape") }
      SpotlightSettingsView().tabItem { Label("Spotlight", systemImage: "magnifyingglass") }
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
