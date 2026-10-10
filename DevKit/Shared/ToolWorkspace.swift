import DevKitCore
import SwiftUI

struct ToolWorkspace<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var detachedPane: DetachedWorkspacePane? = nil
  @State private var availableWidth: CGFloat = 1000
  @State private var focusedPane: WorkspacePane = .input
  @State private var display = "text"
  @State private var selectedArtifact = 0
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @Environment(\.workspaceActive) private var workspaceActive
  @AppStorage(FavoriteTools.key) private var favorites = FavoriteTools.defaults
  private var form: ToolPresentation { session.presentation }
  private var paired: Bool { session.inputStyle == .pair && !session.metadata.network }
  private var mode: WorkspaceLayoutMode { session.layoutPolicy.mode(width: availableWidth) }
  private var roles: [WorkspacePane] { paired ? [.input, .secondary, .output] : [.input, .output] }
  private var visible: [WorkspacePane] {
    if let detachedPane {
      switch detachedPane {
      case .input: return [.input]
      case .secondary: return paired ? [.secondary] : [.input]
      case .output: return [.output]
      case .comparison: return paired ? [.input, .secondary] : [.input, .output]
      }
    }
    if mode == .split { return paired ? (focusedPane == .output ? [.output] : [.input, .secondary]) : [.input, .output] }
    return [focusedPane]
  }
  var body: some View {
    GeometryReader { bounds in
      VStack(spacing: 10) {
        if detachedPane != nil {
          HStack {
            ToolPrimaryControl(session: session, inToolbar: false)
            Spacer()
            Button(session.bridge.running ? "取消" : form.action) { session.run() }.buttonStyle(.glassProminent)
          }
          workspaceTools
        }
        WorkspacePaneDeck(roles: roles, visible: visible,
          titles: [.input: form.inputTitle, .secondary: form.secondaryTitle, .output: form.outputTitle]) { role in
          switch role {
          case .input: ScenarioInput(session: session, editingBegan: { focusedPane = .input })
          case .secondary: secondaryInput
          case .output: resultPane
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(1)
        if let error = session.error {
          HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
            Text(error).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            Button { session.error = nil } label: { Image(systemName: "xmark") }
              .buttonStyle(.plain).accessibilityLabel("关闭错误提示")
          }.font(.callout).padding(12)
            .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.orange.opacity(0.25), lineWidth: 1)
            }
        }
        HStack(spacing: 8) {
          if session.bridge.running { ProgressView().controlSize(.mini) }
          Text(session.status).lineLimit(1)
          if session.output != nil && !session.current { Text("· 待更新") }
          Spacer()
          if let elapsed = elapsedLabel(session.elapsed) { Text(elapsed).monospacedDigit() }
        }.font(.caption).foregroundStyle(.secondary).frame(height: 16)
      }.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
        .onChange(of: bounds.size.width, initial: true) { _, width in
          availableWidth = max(0, width - 32)
          if detachedPane == nil { session.bridge.workspaceWidth = availableWidth }
        }
    }.background(Color(nsColor: .workspaceBase))
      .toolbar {
        // In the main window, view switching joins the window toolbar instead of
        // stacking a second control row above the editors.
        if workspaceActive && detachedPane == nil {
          // Separate items in declaration order: view controls, then the favourite,
          // then the primary action as its own prominent glass item at the far end.
          ToolbarItem(placement: .primaryAction) { paneSwitch }
          ToolbarItem(placement: .primaryAction) { windowMenu }
          ToolbarSpacer(.fixed, placement: .primaryAction)
          ToolbarItem(placement: .primaryAction) { favoriteButton }
          ToolbarSpacer(.fixed, placement: .primaryAction)
          ToolbarItem(placement: .primaryAction) {
            Button { session.run() } label: {
              Label(session.bridge.running ? "取消" : "执行",
                systemImage: session.bridge.running ? "stop.fill" : "play.fill")
                .labelStyle(.titleAndIcon).padding(.horizontal, 6)
            }.buttonStyle(.glassProminent)
              .help(session.bridge.running ? "取消" : "\(form.action) ⌘↩︎")
          }
        }
      }
      .onAppear { display = session.recommendedDisplay }
      .onChange(of: session.operation) { _, _ in focusedPane = .input }
      .onChange(of: session.bridge.paneRequest) { _, _ in
        guard detachedPane == nil else { return }
        session.chooseLayout(.focused)
        focusedPane = session.bridge.paneIndex == 1 ? .output : .input
      }
      .onChange(of: session.completedRun) { _, _ in
        display = session.recommendedDisplay
        selectedArtifact = 0
        if detachedPane == nil && (paired || mode == .focused) { focusedPane = .output }
      }
  }
  /// Shown inside detached windows, which have no shared window toolbar.
  private var workspaceTools: some View {
    HStack(spacing: 12) {
      Text(detachedPane?.title ?? "工作区")
      Spacer(minLength: 4)
      windowMenu.labelStyle(.iconOnly).menuStyle(.button).buttonStyle(.glass).fixedSize()
    }.font(.system(size: 12)).controlSize(.small).frame(height: 30)
  }
  private var favoriteButton: some View {
    let favorite = FavoriteTools.ids(favorites).contains(session.metadata.id)
    return Button { favorites = FavoriteTools.toggling(session.metadata.id, in: favorites) } label: {
      Label("收藏", systemImage: favorite ? "star.fill" : "star").contentTransition(.symbolEffect(.replace))
    }.help(favorite ? "取消收藏" : "收藏当前工具")
  }
  private var paneSwitch: some View {
    WorkspaceSegments(items: paneChoices, selection: Binding(get: {
      mode == .split && (!paired || focusedPane != .output) ? "comparison" : focusedPane.rawValue
    }, set: { value in
      if value == "comparison" { session.chooseLayout(.split); focusedPane = .input }
      else { session.chooseLayout(.focused); focusedPane = WorkspacePane(rawValue: value) ?? .input }
    }), symbols: ["input": session.inputStyle == .generator ? "slider.horizontal.3" : "square.and.pencil",
      "secondary": "doc.on.doc", "output": "doc.text", "comparison": "rectangle.split.2x1"],
      inToolbar: true, iconOnly: true)
  }
  private var windowMenu: some View {
    Menu {
      Button("在新窗口打开输入") { detach(.input) }
      if paired { Button("在新窗口打开第二输入") { detach(.secondary) } }
      Button("在新窗口打开结果") { detach(.output) }
      Button("打开对照窗口") { detach(.comparison) }
      Divider()
      Button("自动适应布局") { session.chooseLayout(.automatic) }
    } label: { Label("窗口与布局", systemImage: "rectangle.on.rectangle") }
      .help("在新窗口打开或调整布局")
  }
  private var paneChoices: [(String, String)] {
    var items = [(session.inputStyle == .generator ? "参数" : "输入", "input")]
    if paired { items.append((session.operation == "schema" ? "Schema" : "对比内容", "secondary")) }
    items.append(("结果", "output"))
    if availableWidth >= WorkspaceLayoutPolicy.minimumSplitWidth { items.append(("对照", "comparison")) }
    return items
  }
  private var secondaryInput: some View {
    VStack(spacing: 0) {
      PaneActions {
        Button {
          if let text = NSPasteboard.general.string(forType: .string) { session.input.secondary = text; session.refreshLayout() }
        } label: { Label("粘贴", systemImage: "doc.on.clipboard") }.help("粘贴文本")
        Button { session.chooseFile(secondary: true) } label: { Label("导入…", systemImage: "square.and.arrow.down") }
          .help("从文件导入")
        Spacer(minLength: 8)
        Button { session.input.secondary = "" } label: { Label("清空\(form.secondaryTitle)", systemImage: "trash") }
          .labelStyle(.iconOnly).help("清空\(form.secondaryTitle)")
      }
      CodeEditor(text: $session.input.secondary, label: form.secondaryTitle, contentSettled: session.refreshLayout,
        editingBegan: { focusedPane = .secondary })
    }.onDrop(of: [.fileURL], isTargeted: nil) { providers in
      guard let provider = providers.first else { return false }
      _ = provider.loadObject(ofClass: URL.self) { url, _ in
        if let url { Task { @MainActor in session.loadFile(url, secondary: true) } }
      }
      return true
    }
  }
  private var resultPane: some View {
    VStack(spacing: 0) {
      if let output = session.output {
        resultActions(output)
        resultBody(output).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        if let note = output.note {
          Text(note).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        }
        if output.text.count > 500_000 {
          Text("显示前 500,000 字符；复制或导出可获取完整结果").font(.caption).foregroundStyle(.secondary).padding(8)
        }
      } else {
        VStack(spacing: 10) {
          ToolIconTile(symbol: form.isImage || session.metadata.id == "qr-code" ? "photo" : "arrow.right.circle",
            tint: session.metadata.category.tint, size: 44).padding(.bottom, 4)
          Text(form.outputTitle).font(.headline).foregroundStyle(.secondary)
          Text("点击“\(form.action)”查看结果").font(.caption).foregroundStyle(.tertiary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
  private func resultViews(_ output: ToolOutput) -> [(String, String, String)] {
    var views = [(session.metadata.id == "http-client" ? "正文" : "文本", "text", "text.alignleft")]
    if session.binaryArtifact != nil { views.append(("文件", "files", "doc")) }
    if !output.rows.isEmpty {
      views.append((session.metadata.id == "http-client" ? "状态与响应头" : "条目", "rows", "list.bullet"))
    }
    if output.html != nil || session.imageArtifact != nil { views.append(("预览", "preview", "eye")) }
    return views
  }
  private func resultActions(_ output: ToolOutput) -> some View {
    let views = resultViews(output)
    return PaneActions {
      // A single view needs no switch; several read better as segments than a pop-up.
      if views.count > 1 {
        Picker("结果视图", selection: $display) {
          ForEach(views, id: \.1) { view in Label(view.0, systemImage: view.2).tag(view.1) }
        }.pickerStyle(.segmented).labelsHidden().fixedSize()
      }
      Spacer(minLength: 8)
      if session.binaryArtifact == nil || display == "text" {
        Button { session.copyResult() } label: {
          Label(session.copied ? "已复制" : session.imageArtifact != nil ? "复制图片" : "复制",
            systemImage: session.copied ? "checkmark" : "doc.on.doc").contentTransition(.symbolEffect(.replace))
        }.help(session.imageArtifact != nil ? "复制图片" : "复制完整结果 ⌘⇧C").disabled(!session.current)
      }
      if output.artifacts.isEmpty {
        Button { session.save(session.textArtifact) } label: { Label("导出…", systemImage: "square.and.arrow.up") }
          .help("导出为文件").disabled(!session.current)
      } else if output.artifacts.count == 1 {
        Button { session.save(output.artifacts[0]) } label: {
          Label(session.imageArtifact != nil ? "保存图片…" : "保存文件…", systemImage: "square.and.arrow.down")
        }.help(session.imageArtifact != nil ? "保存图片" : "保存文件").disabled(!session.current)
      } else {
        Menu {
          ForEach(output.artifacts.indices, id: \.self) { index in
            Button(output.artifacts[index].name) { session.save(output.artifacts[index]) }
          }
        } label: { Label("导出文件", systemImage: "square.and.arrow.up") }
          .fixedSize().help("选择要导出的文件").disabled(!session.current)
      }
    }
  }

  @ViewBuilder private func resultBody(_ output: ToolOutput) -> some View {
    if display == "files", let artifact = session.binaryArtifact {
      VStack(spacing: 16) {
        Image(systemName: "doc.fill").font(.system(size: 46)).foregroundStyle(.secondary)
        Text(artifact.name).font(.headline)
        Text(artifact.mime).font(.caption).foregroundStyle(.secondary)
        Text(ByteCountFormatter.string(fromByteCount: Int64(artifact.data.count), countStyle: .file)).foregroundStyle(.secondary)
        Button { session.save(artifact) } label: { Label("保存文件…", systemImage: "square.and.arrow.down") }
          .buttonStyle(.borderedProminent).controlSize(.large).disabled(!session.current)
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if display == "preview", let html = output.html { SafePreview(html: html) }
    else if display == "preview", session.imageArtifact != nil {
      VStack(spacing: 10) {
        if output.artifacts.count > 1 {
          Picker("预览文件", selection: $selectedArtifact) {
            ForEach(output.artifacts.indices, id: \.self) { index in Text(output.artifacts[index].name).tag(index) }
          }.padding(12)
        }
        if output.artifacts.indices.contains(selectedArtifact), let image = RasterPreview.image(output.artifacts[selectedArtifact].data) {
          Image(nsImage: image).resizable().interpolation(session.metadata.id == "qr-code" ? .none : .high)
            .scaledToFit().padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else { Text("此文件可通过导出菜单保存").foregroundStyle(.secondary) }
      }
    } else if display == "rows", !output.rows.isEmpty {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(Array(output.rows.enumerated()), id: \.offset) { _, row in
            HStack(alignment: .top, spacing: 16) {
              Text(row.label).foregroundStyle(.secondary).frame(minWidth: 70, alignment: .leading)
              Text(row.value.isEmpty ? "（空值）" : row.value).font(.system(size: fontSize, design: .monospaced))
                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
              Button { if Clipboard.copy(row.value) { session.status = "已复制" } } label: { Image(systemName: "doc.on.doc") }
                .buttonStyle(.plain).disabled(!session.current).accessibilityLabel("复制 " + row.label)
            }.padding(14)
            Divider()
          }
        }
      }
    } else if session.metadata.id == "text-diff" {
      ScrollView([.vertical, .horizontal]) {
        LazyVStack(alignment: .leading, spacing: 2) {
          ForEach(Array(output.text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
            Text(line).font(.system(size: fontSize, design: .monospaced)).textSelection(.enabled)
              .foregroundStyle(line.hasPrefix("+ ") ? Color.green : line.hasPrefix("− ") ? Color.red : Color.primary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }.padding(14)
      }
    } else {
      CodeEditor(text: .constant(String(output.text.prefix(500_000))), editable: false, label: form.outputTitle)
    }
  }
  private func detach(_ pane: DetachedWorkspacePane) { DetachedWorkspaceWindows.shared.open(session, pane: pane) }
}
