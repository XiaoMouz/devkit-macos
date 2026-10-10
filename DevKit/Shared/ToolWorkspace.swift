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
  private var inputLanguage: SyntaxLanguage { .forTool(session.metadata.id, values: session.optionValues) }
  private var outputLanguage: SyntaxLanguage {
    if session.metadata.id == "http-client", let mime = session.output?.artifacts.first?.mime {
      return .forMIME(mime)
    }
    return .forTool(session.metadata.id, values: session.optionValues, output: true)
  }
  private var formats: [WorkspacePane: String] {
    var labels: [WorkspacePane: String] = [:]
    if inputLanguage != .automatic && inputLanguage != .plain {
      labels[.input] = inputLanguage.title
      if paired { labels[.secondary] = inputLanguage.title }
    }
    return labels
  }
  private var resultStatus: PaneStatus {
    if session.bridge.running { return PaneStatus(title: "处理中", symbol: "hourglass", tint: .blue) }
    if let error = session.error {
      return PaneStatus(title: "需要检查", symbol: "exclamationmark.circle", tint: .red, detail: error)
    }
    if session.status.hasPrefix("已复制") || session.status.hasPrefix("已导出") {
      return PaneStatus(title: session.status, symbol: "checkmark.circle", tint: .green, detail: session.status)
    }
    if !session.status.isEmpty && !["已完成", "内容已修改，重新执行以更新结果", "处理中…"].contains(session.status) {
      return PaneStatus(title: session.status, symbol: "info.circle", tint: .secondary, detail: session.status)
    }
    guard session.output != nil else { return PaneStatus(title: "待生成", symbol: "text.alignleft", tint: .secondary) }
    if session.current, let report = session.output?.report {
      return PaneStatus(title: report.state == "failure" ? "未通过" : report.state == "difference" ? "存在差异" : "已通过",
        symbol: report.state == "failure" ? "exclamationmark.circle" : report.state == "difference" ? "plusminus.circle" : "checkmark.circle",
        tint: report.state == "failure" ? .red : report.state == "difference" ? .orange : .green, elapsed: elapsedLabel(session.elapsed))
    }
    return session.current
      ? PaneStatus(title: "已完成", symbol: "checkmark.circle", tint: .green, elapsed: elapsedLabel(session.elapsed))
      : PaneStatus(title: "待更新", symbol: "arrow.trianglehead.clockwise", tint: .orange)
  }
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
          titles: [.input: form.inputTitle, .secondary: form.secondaryTitle, .output: form.outputTitle], formats: formats, actions: paneActions) { role in
          switch role {
          case .input: ScenarioInput(session: session, editingBegan: { focusedPane = .input })
          case .secondary: secondaryInput
          case .output: resultPane
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(1)
      }.padding(WorkspaceMetrics.inset)
        .onChange(of: bounds.size.width, initial: true) { _, width in
          availableWidth = max(0, width - WorkspaceMetrics.inset * 2)
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
              // Verbatim: "执行" is also an en.lproj menu key, which turned this into "Run".
              Label {
                Text(verbatim: session.bridge.running ? "取消" : "执行")
              } icon: {
                Image(systemName: session.bridge.running ? "stop.fill" : "play.fill")
              }.labelStyle(.titleAndIcon).padding(.horizontal, 6)
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
  @ViewBuilder private func paneActions(_ role: WorkspacePane) -> some View {
    switch role {
    case .input: ScenarioInputActions(session: session)
    case .secondary: secondaryActions
    case .output:
      if let output = session.output { resultActions(output) }
      else { Button {} label: { Label("复制", systemImage: "doc.on.doc") }.disabled(true) }
    }
    if role != .output && !visible.contains(.output), session.error != nil {
      PaneStatusLabel(status: resultStatus).labelStyle(.iconOnly)
    }
  }
  private var secondaryActions: some View {
    Group {
      Button {
        if let text = NSPasteboard.general.string(forType: .string) { session.input.secondary = text; session.refreshLayout() }
      } label: { Label("粘贴", systemImage: "doc.on.clipboard") }.help("粘贴文本")
      Button { session.chooseFile(secondary: true) } label: { Label("导入…", systemImage: "square.and.arrow.down") }
        .help("从文件导入")
      Button { session.input.secondary = "" } label: { Label("清空\(form.secondaryTitle)", systemImage: "trash") }
        .labelStyle(.iconOnly).help("清空\(form.secondaryTitle)")
    }
  }
  private var secondaryInput: some View {
    VStack(spacing: 0) {
      CodeEditor(text: $session.input.secondary, label: form.secondaryTitle, language: inputLanguage, contentSettled: session.refreshLayout,
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
      if let error = session.error {
        ResultReportView(report: ResultReport("failure", "未能完成处理", error))
        WorkspaceEmptyState(title: "请检查输入后重新执行", detail: error, symbol: "exclamationmark.circle", tint: .red) { EmptyView() }
      } else if let output = session.output {
        if let report = output.report { ResultReportView(report: report) }
        resultBody(output).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        if let note = output.note {
          Text(note).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        }
        if output.text.count > 500_000 {
          Text("显示前 500,000 字符；复制或导出可获取完整结果").font(.caption).foregroundStyle(.secondary).padding(8)
        }
      } else {
        WorkspaceEmptyState(title: session.error == nil ? "结果会显示在这里" : "输入需要检查",
          detail: session.error ?? "准备好输入后，点击顶部“执行”",
          symbol: session.error != nil ? "exclamationmark.circle" : form.isImage || session.metadata.id == "qr-code" ? "photo" : "arrow.right",
          tint: session.error == nil ? .purple : .red) {
          EmptyView()
        }
      }
      if !resultUsesEditor {
        HStack(spacing: 8) {
          PaneStatusLabel(status: resultStatus)
          Spacer(minLength: 8)
          if let output = session.output, !output.text.isEmpty {
            Text("\(output.text.count) 字符").monospacedDigit()
          }
        }.font(.system(size: 10)).foregroundStyle(.secondary)
          .padding(.horizontal, 16).frame(height: 28)
          .background(.primary.opacity(0.025))
          .overlay(alignment: .top) { Divider().opacity(0.5) }
      }
    }
  }
  private var resultUsesEditor: Bool {
    if session.error != nil { return false }
    guard let output = session.output else { return false }
    if output.report != nil { return display == "text" && session.metadata.id != "text-diff" }
    if display == "files" && session.binaryArtifact != nil { return false }
    if display == "preview" && (output.html != nil || session.imageArtifact != nil) { return false }
    if display == "rows" && !output.rows.isEmpty { return false }
    return session.metadata.id != "text-diff"
  }
  private func resultViews(_ output: ToolOutput) -> [(String, String, String)] {
    if output.report != nil {
      var views = [(session.metadata.id == "json" ? "路径列表" : "问题明细", "rows", "list.bullet")]
      if output.html != nil { views.append(("高亮对照", "preview", "rectangle.split.2x1")) }
      views.append(("文本", "text", "text.alignleft"))
      return views
    }
    var views = [(session.metadata.id == "http-client" ? "正文" : "文本", "text", "text.alignleft")]
    if session.binaryArtifact != nil { views.append(("文件", "files", "doc")) }
    if !output.rows.isEmpty {
      views.append((session.metadata.id == "http-client" ? "状态与响应头" : "条目", "rows", "list.bullet"))
    }
    if output.html != nil || session.imageArtifact != nil { views.append((session.metadata.id == "json" ? "折叠视图" : "预览", "preview", "eye")) }
    return views
  }
  private func resultActions(_ output: ToolOutput) -> some View {
    let views = resultViews(output)
    return Group {
      if output.report != nil, output.html != nil {
        Picker("结果视图", selection: $display) {
          Text(session.metadata.id == "json" ? "路径" : "明细").tag("rows")
          Text("高亮").tag("preview")
          Text("文本").tag("text")
        }.pickerStyle(.segmented).labelsHidden().frame(width: 176).help("切换问题路径与高亮对照")
      } else if views.count > 1 {
        Menu {
          Picker("结果视图", selection: $display) {
            ForEach(views, id: \.1) { view in Label(view.0, systemImage: view.2).tag(view.1) }
          }
        } label: {
          let current = views.first { $0.1 == display } ?? views[0]
          Label(current.0, systemImage: current.2)
        }.menuStyle(.borderlessButton).fixedSize().help("切换结果视图")
      }
      if session.binaryArtifact == nil || display == "text" {
        Button { session.copyResult() } label: {
          Label(session.copied ? "已复制" : session.imageArtifact != nil ? "复制图片" : "复制",
            systemImage: session.copied ? "checkmark" : "doc.on.doc").contentTransition(.symbolEffect(.replace))
        }.buttonStyle(.bordered).tint(.blue)
          .help(session.imageArtifact != nil ? "复制图片" : "复制完整结果 ⌘⇧C").disabled(!session.current)
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
    } else if display == "rows", output.rows.isEmpty, output.report != nil {
      if let html = output.html { SafePreview(html: html) }
      else {
        CodeEditor(text: .constant(output.text), editable: false, label: "校验详情", language: outputLanguage, status: resultStatus)
      }
    } else if display == "rows", !output.rows.isEmpty {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(Array(output.rows.enumerated()), id: \.offset) { _, row in
            HStack(alignment: .top, spacing: 16) {
              Text(row.label).font(.system(.body, design: .monospaced))
                .foregroundStyle(rowTint(row, report: output.report))
                .frame(minWidth: 70, alignment: .leading)
              HighlightedText(text: row.value.isEmpty ? "（空值）" : output.report != nil && row.value.count > 1200
                ? String(row.value.prefix(1200)) + "\n…（完整内容可复制或导出）" : row.value,
                language: output.report == nil ? .automatic : .plain, fontSize: fontSize)
                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
              Button { if Clipboard.copy(row.value) { session.status = "已复制" } } label: { Image(systemName: "doc.on.doc") }
                .buttonStyle(.plain).disabled(!session.current).accessibilityLabel("复制 " + row.label)
            }.padding(14)
              .background(output.report == nil ? Color.clear : rowTint(row, report: output.report).opacity(0.045))
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
      CodeEditor(text: .constant(String(output.text.prefix(500_000))), editable: false, label: form.outputTitle,
        language: outputLanguage, status: resultStatus)
    }
  }
  private func rowTint(_ row: ResultRow, report: ResultReport?) -> Color {
    if session.metadata.id == "contrast" {
      return row.value == "通过" ? .green : row.value == "未通过" ? .red : .secondary
    }
    if session.metadata.id == "jwt", row.label != "签名" { return .secondary }
    if report?.state == "failure" { return .red }
    if row.label.hasPrefix("+ ") { return .green }
    if row.label.hasPrefix("− ") { return .red }
    if row.label.hasPrefix("~ ") { return .orange }
    return .secondary
  }
  private func detach(_ pane: DetachedWorkspacePane) { DetachedWorkspaceWindows.shared.open(session, pane: pane) }
}
