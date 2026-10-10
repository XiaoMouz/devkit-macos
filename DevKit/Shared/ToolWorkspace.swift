import DevKitCore
import SwiftUI
import UniformTypeIdentifiers

struct ToolWorkspace<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var detachedPane: DetachedWorkspacePane? = nil
  @State private var availableWidth: CGFloat = 1000
  @State private var focusedPane: WorkspacePane = .input
  @State private var display = "text"
  @State private var optionsPopover = false
  @AppStorage("editorFontSize") private var fontSize = 13.0
  private var metadata: ToolMetadata { T.metadata }
  private var pairedInput: Bool { metadata.inputStyle == .pair && !metadata.network }
  private var mode: WorkspaceLayoutMode { session.layoutPolicy.mode(width: availableWidth) }
  private var roles: [WorkspacePane] {
    metadata.inputStyle == .generator
      ? [.output] : pairedInput ? [.input, .secondary, .output] : [.input, .output]
  }
  private var visiblePanes: [WorkspacePane] {
    if let detachedPane {
      switch detachedPane {
      case .input: return [.input]
      case .secondary: return [.secondary]
      case .output: return [.output]
      case .comparison: return pairedInput ? [.input, .secondary] : [.input, .output]
      }
    }
    if metadata.inputStyle == .generator { return [.output] }
    if mode == .split {
      if pairedInput { return focusedPane == .output ? [.output] : [.input, .secondary] }
      return [.input, .output]
    }
    return [focusedPane]
  }
  private var primaryField: OptionField<T.Options>? {
    guard metadata.inputStyle != .generator else { return nil }
    return T.fields.first {
      if case .choice = $0.kind { return true }
      return false
    }
  }
  private var extraFields: [OptionField<T.Options>] {
    T.fields.filter { $0.id != primaryField?.id }
  }
  private var needsPageSwitch: Bool {
    detachedPane == nil && metadata.inputStyle != .generator && (mode == .focused || pairedInput)
  }

  var body: some View {
    GeometryReader { bounds in
      HStack(spacing: 0) {
      VStack(spacing: 0) {
        if detachedPane != nil { controls.padding(.bottom, 10) }
        workspaceTools.padding(.bottom, 6)
        WorkspacePaneDeck(roles: roles, visible: visiblePanes,
          titles: [.input: inputTitle, .secondary: metadata.id == "json-schema" ? "Schema" : "对比内容", .output: "结果"]) { role in
          switch role {
          case .input: inputPane
          case .secondary: secondaryPane
          case .output: resultPane
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(1)
        if let error = session.error {
          HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
            Text(error).textSelection(.enabled).lineLimit(4).frame(
              maxWidth: .infinity, alignment: .leading)
            Button {
              session.error = nil
            } label: {
              Image(systemName: "xmark")
            }.buttonStyle(.plain).help("关闭错误提示")
          }.font(.callout).padding(12).background(
            .orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
      }.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        if detachedPane != nil && optionsPopover {
          Divider()
          ToolOptionsForm(options: $session.options, fields: extraFields, modified: {})
            .frame(width: 240)
        }
      }.frame(width: bounds.size.width, height: bounds.size.height)
        .onChange(of: bounds.size.width, initial: true) { _, width in
          availableWidth = max(0, width - 32)
          if detachedPane == nil { session.bridge.workspaceWidth = availableWidth }
        }
    }
    .background(Color(nsColor: .textBackgroundColor))
    .onChange(of: session.bridge.paneRequest) { _, _ in
      guard detachedPane == nil else { return }
      session.chooseLayout(.focused)
      focusedPane = session.bridge.paneIndex == 1 ? .output : .input
    }
    .onAppear { display = session.recommendedDisplay }
    .onChange(of: session.completedRun) { _, _ in
      display = session.recommendedDisplay
      if detachedPane == nil && (pairedInput || mode == .focused) { focusedPane = .output }
    }
  }
  private var workspaceTools: some View {
    HStack(spacing: 12) {
      if detachedPane == nil && metadata.inputStyle != .generator {
        WorkspaceSegments(items: workspaceChoices, selection: workspaceSelection)
      } else { Text(detachedPane?.title ?? "结果").font(.system(size: 12, weight: .medium)) }
      if availableWidth > 850 {
        if metadata.inputStyle != .generator { countLabel(session.input.file?.count ?? session.input.text.utf8.count) }
        if let output = session.output { Text("→").foregroundStyle(.tertiary); countLabel(output.text.utf8.count) }
      }
      Spacer(minLength: 6)
      if session.bridge.running { ProgressView().controlSize(.mini) }
      if !session.current && session.output != nil { Text("待更新").font(.caption).foregroundStyle(.secondary) }
      if metadata.inputStyle != .generator {
        Button { session.clearInput() } label: { Image(systemName: "trash") }
          .help("清空输入").accessibilityLabel("清空输入")
      }
      Button { session.copyResult() } label: { Image(systemName: session.copied ? "checkmark" : "doc.on.doc") }
        .disabled(!session.current).help("复制完整结果 ⌘⇧C").accessibilityLabel("复制结果")
      windowMenu
      Menu {
        if metadata.inputStyle != .generator {
          if !metadata.sample.isEmpty { Button("填入示例") { session.useExample() } }
          Button("粘贴文本") { session.paste() }
          Button("选择文件…") { session.chooseFile() }
          if pairedInput {
            Button("粘贴第二输入") {
              if let value = NSPasteboard.general.string(forType: .string) { session.input.secondary = value; session.refreshLayout() }
            }
            Button("清空第二输入") { session.input.secondary = ""; session.refreshLayout() }
          }
          Divider()
          Button("自动适应布局") { session.chooseLayout(.automatic) }
        }
        if let output = session.output {
          Divider()
          Button("显示文本") { display = "text" }
          if !output.rows.isEmpty { Button("显示条目") { display = "rows" } }
          if output.html != nil || output.artifacts.contains(where: { RasterPreview.mimeTypes.contains($0.mime) }) {
            Button("显示预览") { display = "preview" }
          }
          Divider()
          Button("导出文本…") { session.save(Artifact("\(metadata.id).txt", "text/plain", Data(output.text.utf8))) }
            .disabled(!session.current)
          ForEach(output.artifacts.indices, id: \.self) { index in
            Button("导出 \(output.artifacts[index].name)…") { session.save(output.artifacts[index]) }.disabled(!session.current)
          }
        }
      } label: { Image(systemName: "ellipsis") }
        .menuStyle(.button).buttonStyle(.glass).fixedSize().accessibilityLabel("更多工具操作")
    }.font(.system(size: 12)).foregroundStyle(.secondary).buttonStyle(.glass).controlSize(.small).frame(height: 30)
  }
  private var workspaceChoices: [(String, String)] {
    var values = [("输入", "input")]
    if pairedInput { values.append((metadata.id == "json-schema" ? "Schema" : "第二输入", "secondary")) }
    values.append(("结果", "output"))
    if availableWidth >= WorkspaceLayoutPolicy.minimumSplitWidth { values.append(("对照", "comparison")) }
    return values
  }
  private var workspaceSelection: Binding<String> {
    Binding(get: {
      mode == .split && (!pairedInput || focusedPane != .output) ? "comparison" : focusedPane.rawValue
    }, set: { value in
      if value == "comparison" { session.chooseLayout(.split); focusedPane = .input }
      else { session.chooseLayout(.focused); focusedPane = WorkspacePane(rawValue: value) ?? .input }
    })
  }
  private var showsStatusLine: Bool {
    !session.status.isEmpty || session.bridge.running || session.elapsed > 0
      || detachedPane != nil || (mode == .focused && metadata.inputStyle != .generator)
  }
  private var statusLine: some View {
    HStack(spacing: 7) {
      if session.bridge.running {
        ProgressView().controlSize(.mini)
      } else if !session.status.isEmpty {
        Circle().fill(session.current ? Color.green : Color.secondary.opacity(0.45)).frame(
          width: 5, height: 5)
      }
      if !session.status.isEmpty { Text(session.status).lineLimit(1) }
      Spacer(minLength: 8)
      if detachedPane != nil {
        Label(session.sourceIsOpen ? "内容同步" : "独立会话", systemImage: "link").help(
          "此窗口与同一工具会话共享输入、参数和结果")
      } else if mode == .focused && metadata.inputStyle != .generator {
        Text("⌘⌥1 输入 · ⌘⌥2 结果")
      }
      if session.elapsed > 0 {
        Text(String(format: "%.0f ms", session.elapsed * 1000)).monospacedDigit()
      }
    }.font(.system(size: 11)).foregroundStyle(.secondary)
  }
  private var controls: some View {
    VStack(spacing: 10) {
      HStack(spacing: 12) {
        primaryControl
        Spacer(minLength: 8)
        if needsPageSwitch && availableWidth >= 780 { pageSwitch }
        if detachedPane == nil && metadata.inputStyle != .generator { layoutMenu }
        if !extraFields.isEmpty {
          Button {
            optionsPopover.toggle()
          } label: {
            Image(systemName: "slider.horizontal.3")
          }
          .buttonStyle(.glass).frame(width: 28, height: 32).help("参数设置").accessibilityLabel("参数设置")
        }
        if detachedPane != nil {
          Button {
            session.run()
          } label: {
            Label(
              session.bridge.running ? "取消" : "执行",
              systemImage: session.bridge.running ? "stop.fill" : "play.fill")
          }.buttonStyle(.glassProminent)
        }
      }.frame(minHeight: 36)
      if needsPageSwitch && availableWidth < 780 {
        HStack {
          pageSwitch
          Spacer()
        }
      }
    }.controlSize(.regular)
  }
  @ViewBuilder private var primaryControl: some View {
    if let field = primaryField, case .choice(let choices) = field.kind {
      if choices.count <= 4 && availableWidth >= 780 {
        WorkspaceSegments(
          items: choices.map { (ToolOptionLabels.title($0), $0) }, selection: binding(field))
      } else {
        Menu {
          ForEach(choices, id: \.self) { value in
            Button {
              field.write(&session.options, value)
            } label: {
              if field.read(session.options) == value {
                Label(ToolOptionLabels.title(value), systemImage: "checkmark")
              } else {
                Text(ToolOptionLabels.title(value))
              }
            }
          }
        } label: {
          Text(ToolOptionLabels.title(field.read(session.options))).font(.callout.weight(.semibold))
        }
        .menuStyle(.button).buttonStyle(.glass).fixedSize().help(field.label)
      }
    } else if metadata.inputStyle == .generator {
      HStack(spacing: 9) {
        Image(systemName: "sparkles").foregroundStyle(.tint)
        Text("生成配置").font(.callout.weight(.semibold))
        Text(generatorSummary).font(.caption).foregroundStyle(.secondary).lineLimit(1)
      }
    } else {
      Text(detachedPane?.title ?? "编辑工作区").font(.callout.weight(.semibold))
    }
  }
  private var generatorSummary: String {
    T.fields.compactMap { field -> String? in
      switch field.kind {
      case .choice: return ToolOptionLabels.title(field.read(session.options))
      case .integer: return field.label + " " + field.read(session.options)
      default: return nil
      }
    }.prefix(3).joined(separator: " · ")
  }
  private var pageSwitch: some View {
    WorkspaceSegments(items: paneChoices, selection: $focusedPane)
  }
  private var paneChoices: [(String, WorkspacePane)] {
    if pairedInput && mode == .split { return [("两份输入", .input), ("结果", .output)] }
    if pairedInput {
      return [
        ("输入", .input), (metadata.id == "json-schema" ? "Schema" : "对比内容", .secondary),
        ("结果", .output),
      ]
    }
    return [("输入", .input), ("结果", .output)]
  }
  private var layoutMenu: some View {
    Menu {
      ForEach(WorkspaceLayoutPreference.allCases, id: \.self) { preference in
        Button {
          session.chooseLayout(preference)
        } label: {
          if session.layoutPolicy.preference == preference {
            Label(layoutTitle(preference), systemImage: "checkmark")
          } else {
            Text(layoutTitle(preference))
          }
        }.disabled(preference == .split && availableWidth < WorkspaceLayoutPolicy.minimumSplitWidth)
      }
    } label: {
      Label(
        session.layoutPolicy.preference == .automatic
          ? "自动 · \(mode == .split ? "并排" : "专注")" : mode == .split ? "并排" : "专注",
        systemImage: mode == .split ? "rectangle.split.2x1" : "rectangle"
      )
      .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
    }.menuStyle(.button).buttonStyle(.glass).fixedSize().help("短内容并排；长内容或窄窗口使用完整面板。可手动选择并保留布局。")
  }
  private func layoutTitle(_ value: WorkspaceLayoutPreference) -> String {
    switch value {
    case .automatic: "自动适应内容"
    case .split: "并排对照"
    case .focused: "专注阅读"
    }
  }
  private var windowMenu: some View {
    Menu {
      if metadata.inputStyle != .generator {
        Button("在新窗口打开输入") { detach(.input) }
        if pairedInput { Button("在新窗口打开第二输入") { detach(.secondary) } }
      }
      Button("在新窗口打开结果") { detach(.output) }
      if metadata.inputStyle != .generator {
        Divider()
        Button(pairedInput ? "打开两份输入对照窗口" : "打开输入与结果对照窗口") { detach(.comparison) }
      }
    } label: {
      Image(systemName: "rectangle.on.rectangle")
    }
    .menuStyle(.button).buttonStyle(.glass).fixedSize().help("独立窗口 · 内容实时同步").accessibilityLabel("独立窗口")
  }
  private func detach(_ pane: DetachedWorkspacePane) {
    DetachedWorkspaceWindows.shared.open(session, pane: pane)
  }
  private func binding(_ field: OptionField<T.Options>) -> Binding<String> {
    Binding(get: { field.read(session.options) }, set: { field.write(&session.options, $0) })
  }
  private func countLabel(_ bytes: Int) -> some View {
    Text(
      bytes < 1024
        ? "\(bytes) B"
        : bytes < 1_048_576
          ? String(format: "%.1f KiB", Double(bytes) / 1024)
          : String(format: "%.1f MiB", Double(bytes) / 1_048_576)
    )
    .font(.system(size: 10)).monospacedDigit().foregroundStyle(.tertiary)
  }
  private var inputTitle: String {
    pairedInput
      ? (metadata.id == "json-schema" ? "JSON 数据" : "原始内容")
      : metadata.id == "http-client" ? "请求" : "输入"
  }
  private var inputPane: some View {
    VStack(spacing: 0) {

      if let data = session.input.file {
        VStack(spacing: 16) {
          if let image = RasterPreview.image(data) {
            Image(nsImage: image).resizable().scaledToFit().frame(
              maxWidth: .infinity, maxHeight: .infinity
            ).layoutPriority(1)
          } else {
            Image(systemName: "doc.fill").font(.system(size: 40)).foregroundStyle(.tertiary)
            Spacer()
          }
        }.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if metadata.inputStyle == .file {
        emptyPane("选择一个文件", "拖入文件或从本机选择，原文件保持不变。", symbol: "doc.badge.plus") {
          EmptyView()
        }
      } else if metadata.id == "http-client" {
        HStack {
          Text("URL").font(.caption).foregroundStyle(.secondary)
          TextField("https://example.com", text: $session.input.text).textFieldStyle(.roundedBorder)
        }.padding(.horizontal, 16).padding(.bottom, 10)
        CodeEditor(
          text: $session.input.secondary, label: "请求体", contentSettled: session.refreshLayout,
          editingBegan: { focusedPane = .input })
      } else {
        CodeEditor(
          text: $session.input.text, label: "输入文本", contentSettled: session.refreshLayout,
          editingBegan: { focusedPane = .input })
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .overlay(alignment: .topLeading) {
        if session.input.file == nil && session.input.text.isEmpty
          && metadata.inputStyle != .file && !metadata.network {
          Text("在此输入或粘贴内容…")
            .font(.system(size: fontSize)).foregroundStyle(.tertiary)
            .padding(16).allowsHitTesting(false).accessibilityHidden(true)
        }
      }
      .onDrop(of: [.fileURL], isTargeted: nil) { providers in
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
          if let url { Task { @MainActor in session.loadFile(url) } }
        }
        return true
      }
  }
  private var secondaryPane: some View {
    VStack(spacing: 0) {

      CodeEditor(
        text: $session.input.secondary, label: metadata.id == "json-schema" ? "Schema 输入" : "对比内容",
        contentSettled: session.refreshLayout, editingBegan: { focusedPane = .secondary })
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  private var resultPane: some View {
    VStack(spacing: 0) {

      if let output = session.output {
        resultBody(output).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .layoutPriority(1)
        if output.note != nil || output.text.hasSuffix("\n") || output.text.count > 500_000 {
          HStack(alignment: .top, spacing: 10) {
            if let note = output.note { Text(note).lineLimit(2).help(note) }
            Spacer(minLength: 0)
            if output.text.hasSuffix("\n") { Text("含末尾 LF").fixedSize() }
            if output.text.count > 500_000 { Text("预览已截断；复制包含全部内容") }
          }.font(.system(size: 11)).foregroundStyle(.tertiary).padding(.horizontal, 16).padding(
            .vertical, 10)
        }
      } else {
        emptyPane(
          metadata.inputStyle == .generator ? "尚未生成" : "等待结果",
          metadata.inputStyle == .generator ? "设置参数，按 ⌘↩︎ 生成。" : "输入内容，按 ⌘↩︎ 开始处理。",
          symbol: "arrow.right"
        ) { EmptyView() }
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  @ViewBuilder private func resultBody(_ output: ToolOutput) -> some View {
    if display == "preview", let html = output.html {
      SafePreview(html: html)
    } else if display == "preview",
      let data = output.artifacts.first(where: { RasterPreview.mimeTypes.contains($0.mime) })?.data,
      let image = RasterPreview.image(data)
    {
      Image(nsImage: image).resizable().scaledToFit().padding(24).frame(
        maxWidth: .infinity, maxHeight: .infinity)
    } else if display == "rows", !output.rows.isEmpty {
      ScrollView {
        LazyVStack(spacing: 6) {
          ForEach(Array(output.rows.enumerated()), id: \.offset) { _, row in
            Button {
              if session.current && Clipboard.copy(row.value) {
                session.status = "已复制 \(row.label)"
              }
            } label: {
              HStack(alignment: .top, spacing: 14) {
                Text(row.label).font(.caption).foregroundStyle(.tertiary).frame(
                  minWidth: 25, alignment: .leading)
                Text(row.value.isEmpty ? "（空值）" : row.value).font(
                  .system(size: fontSize, design: .monospaced)
                ).lineLimit(8).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "doc.on.doc").font(.caption).foregroundStyle(.tertiary)
              }.padding(13).background(
                .quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 9)
              ).contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(!session.current).help("点击复制完整值")
          }
        }.padding(.horizontal, 12).padding(.bottom, 12)
      }
    } else if output.text.count <= 2000
      && (metadata.category == .encoding || metadata.category == .security)
      && output.artifacts.allSatisfy({ String(data: $0.data, encoding: .utf8) != nil })
    {
      ScrollView {
        Button {
          session.copyResult()
        } label: {
          VStack(alignment: .leading, spacing: 18) {
            Text(output.text.isEmpty ? "（空文本）" : output.text).font(
              .system(size: fontSize, design: .monospaced)
            ).fixedSize(horizontal: false, vertical: true).frame(
              maxWidth: .infinity, alignment: .leading)
          }.padding(18).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!session.current).frame(
          maxWidth: .infinity, alignment: .topLeading)
      }
    } else {
      CodeEditor(
        text: .constant(String(output.text.prefix(500_000))), editable: false, label: "结果文本")
    }
  }
  private func emptyPane<Actions: View>(
    _ title: String, _ message: String, symbol: String, @ViewBuilder actions: () -> Actions
  ) -> some View {
    VStack(spacing: 14) {
      Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.secondary)
      Text(message).font(.system(size: 12)).foregroundStyle(.tertiary).multilineTextAlignment(
        .center)
      actions()
    }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
