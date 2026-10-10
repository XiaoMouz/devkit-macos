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
            Slider(value: $transparency, in: 0...1, step: 0.01) {
              Text("透明度 \(Int((transparency * 100).rounded()))%")
            }.accessibilityLabel("背景透明度")
            HStack {
              Text("不透明")
              Spacer()
              Text("更透明")
            }.font(.caption).foregroundStyle(.secondary)
          }
          Text(glassMode == GlassMode.custom.rawValue
            ? "调整顶部和左侧栏的背景通透程度。系统开启“减少透明度”时优先使用不透明背景。"
            : "跟随“系统设置 → 外观 → Liquid Glass”的变化，同时遵循“减少透明度”设置。")
            .font(.caption).foregroundStyle(.secondary)
        }
        Section("编辑器") {
          Slider(value: $fontSize, in: 11...22, step: 1) { Text("字号 \(Int(fontSize))") }
          Toggle("自动换行", isOn: $wrap)
        }
        Section("数据") {
          Text("保存外观、收藏和 Spotlight 配置。输入、结果、令牌与请求正文只保留在内存会话中，退出后不恢复。")
            .foregroundStyle(.secondary)
        }
      }.formStyle(.grouped).tabItem { Label("通用", systemImage: "gearshape") }
      SpotlightSettingsView().tabItem { Label("Spotlight", systemImage: "magnifyingglass") }
      VStack(spacing: 14) {
        Image(systemName: "curlybraces.square.fill").font(.system(size: 52)).foregroundStyle(.secondary)
        Text("DevKit").font(.title.bold())
        Text("原生 macOS Web 开发者工具箱").foregroundStyle(.secondary)
        Text("0.1.0 · macOS 26+").font(.caption).foregroundStyle(.secondary)
      }.frame(maxWidth: .infinity, maxHeight: .infinity).tabItem { Label("关于", systemImage: "info.circle") }
    }.frame(width: 800, height: 610)
      .onChange(of: appearance) { _, value in AppAppearance.apply(value) }
  }
}
