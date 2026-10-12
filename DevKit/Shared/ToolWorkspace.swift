import DevKitCore
import SwiftUI

struct ToolWorkspace<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var detachedPane: DetachedWorkspacePane? = nil
  @State private var availableWidth: CGFloat = 1000
  @State private var viewState: WorkspaceViewState
  private var focusedPane: WorkspacePane {
    get { viewState.focusedPane }
    nonmutating set { viewState.focusedPane = newValue }
  }
  private var display: String {
    get { viewState.display }
    nonmutating set { viewState.display = newValue }
  }
  private var selectedArtifact: Int {
    get { viewState.selectedArtifact }
    nonmutating set { viewState.selectedArtifact = newValue }
  }
  init(session: ToolSession<T>, detachedPane: DetachedWorkspacePane? = nil) {
    self.session = session
    self.detachedPane = detachedPane
    _viewState = State(initialValue: detachedPane == nil ? session.viewState : WorkspaceViewState())
  }
  @AppStorage("editorFontSize") private var fontSize = 13.0
  @Environment(\.workspaceActive) private var workspaceActive
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    if session.bridge.running {
      return PaneStatus(title: session.status.hasPrefix(L10n.tr("Read")) ? session.status : L10n.tr("Processing"), symbol: "hourglass", tint: .blue)
    }
    if let error = session.error {
      return PaneStatus(title: L10n.tr("Needs Review"), symbol: "exclamationmark.circle", tint: .red, detail: error)
    }
    if session.status.hasPrefix(L10n.tr("Copied")) || session.status.hasPrefix(L10n.tr("Exported")) {
      return PaneStatus(title: session.status, symbol: "checkmark.circle", tint: .green, detail: session.status)
    }
    if !session.status.isEmpty && ![L10n.tr("Completed"), L10n.tr("Content changed. Run again to update the result."), L10n.tr("Processing…")].contains(session.status) {
      return PaneStatus(title: session.status, symbol: "info.circle", tint: .secondary, detail: session.status)
    }
    guard session.output != nil else { return PaneStatus(title: L10n.tr("Ready to Generate"), symbol: "text.alignleft", tint: .secondary) }
    if session.current, let report = session.output?.report {
      return PaneStatus(title: report.state == "failure" ? L10n.tr("Failed") : report.state == "warning" ? L10n.tr("Please Review") : report.state == "difference" ? L10n.tr("Differences Found") : L10n.tr("Passed"),
        symbol: ["failure", "warning"].contains(report.state) ? "exclamationmark.circle" : report.state == "difference" ? "plusminus.circle" : "checkmark.circle",
        tint: report.state == "failure" ? .red : ["difference", "warning"].contains(report.state) ? .orange : .green, elapsed: elapsedLabel(session.elapsed))
    }
    return session.current
      ? PaneStatus(title: L10n.tr("Completed"), symbol: "checkmark.circle", tint: .green, elapsed: elapsedLabel(session.elapsed))
      : PaneStatus(title: L10n.tr("Needs Update"), symbol: "arrow.trianglehead.clockwise", tint: .orange)
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
            Button(session.bridge.running ? L10n.tr("Cancel") : form.action) { session.run() }.buttonStyle(.borderedProminent)
          }
          workspaceTools
        }
        if session.usesWorkspaceParameters && !session.workspaceParameterPlan.fieldIDs.isEmpty {
          WorkspaceParameterBar(session: session, availableWidth: max(0, bounds.size.width - WorkspaceMetrics.inset * 2)).transition(.opacity)
        }
        WorkspacePaneDeck(roles: roles, visible: visible,
          titles: [.input: form.inputTitle, .secondary: form.secondaryTitle, .output: form.outputTitle], formats: formats, actions: paneActions) { role in
          switch role {
          case .input: ScenarioInput(session: session, editingBegan: { focusedPane = .input }, editorState: viewState.inputEditor)
          case .secondary: secondaryInput
          case .output: resultPane
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(1)
      }.padding(WorkspaceMetrics.inset)
        .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: session.workspaceParameterPlan.fieldIDs)
        .onChange(of: bounds.size.width, initial: true) { _, width in
          let next = max(0, width - WorkspaceMetrics.inset * 2)
          if availableWidth != next { availableWidth = next }
          if detachedPane == nil && session.bridge.workspaceWidth != next { session.bridge.workspaceWidth = next }
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
              // Tool actions use the same title as the selected operation, including detached windows.
              Label {
                Text(verbatim: session.bridge.running ? L10n.tr("Cancel") : form.action)
              } icon: {
                Image(systemName: session.bridge.running ? "stop.fill" : "play.fill")
              }.labelStyle(.titleAndIcon).padding(.horizontal, 6)
            }.buttonStyle(.borderedProminent)
              .help(session.bridge.running ? L10n.tr("Cancel") : "\(form.action) ⌘↩︎")
          }
        }
      }
      .onAppear { synchronizeResultPresentation() }
      .onChange(of: session.operation) { _, _ in focusedPane = .input }
      .onChange(of: session.bridge.paneRequest) { _, _ in
        guard detachedPane == nil else { return }
        session.chooseLayout(.focused)
        focusedPane = session.bridge.paneIndex == 1 ? .output : .input
      }
      .onChange(of: session.completedRun) { _, _ in
        synchronizeResultPresentation()
      }
  }
  private func synchronizeResultPresentation() {
    guard viewState.completedRun != session.completedRun else { return }
    viewState.completedRun = session.completedRun
    display = session.recommendedDisplay
    selectedArtifact = 0
    viewState.outputEditor.page = EditorPage()
    viewState.outputEditor.pageRevision += 1
    if session.output != nil && detachedPane == nil && (paired || mode == .focused) { focusedPane = .output }
  }
  /// Shown inside detached windows, which have no shared window toolbar.
  private var workspaceTools: some View {
    HStack(spacing: 12) {
      Text(detachedPane?.title ?? L10n.tr("Workspace"))
      Spacer(minLength: 4)
      windowMenu.labelStyle(.iconOnly).menuStyle(.button).buttonStyle(.bordered).fixedSize()
    }.font(.system(size: 12)).controlSize(.small).frame(height: 30)
  }
  private var favoriteButton: some View {
    let favorite = FavoriteTools.ids(favorites).contains(session.metadata.id)
    return Button { favorites = FavoriteTools.toggling(session.metadata.id, in: favorites) } label: {
      Label(L10n.tr("Favorites"), systemImage: favorite ? "star.fill" : "star").contentTransition(.symbolEffect(.replace))
    }.help(favorite ? L10n.tr("Remove from Favorites") : L10n.tr("Add Current Tool to Favorites"))
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
      Button(L10n.tr("Open Input in New Window")) { detach(.input) }
      if paired { Button(L10n.tr("Open Second Input in New Window")) { detach(.secondary) } }
      Button(L10n.tr("Open Result in New Window")) { detach(.output) }
      Button(L10n.tr("Open Comparison Window")) { detach(.comparison) }
      Divider()
      Button(L10n.tr("Fit Layout Automatically")) { session.chooseLayout(.automatic) }
    } label: { Label(L10n.tr("Windows and Layout"), systemImage: "rectangle.on.rectangle") }
      .help(L10n.tr("Open in a new window or adjust the layout"))
  }
  private var paneChoices: [(String, String)] {
    var items = [(session.inputStyle == .generator ? L10n.tr("Parameters") : L10n.tr("Input"), "input")]
    if paired { items.append((session.operation == "schema" ? "Schema" : L10n.tr("Comparison Content"), "secondary")) }
    items.append((L10n.tr("Result"), "output"))
    if availableWidth >= WorkspaceLayoutPolicy.minimumSplitWidth { items.append((L10n.tr("Comparison"), "comparison")) }
    return items
  }
  @ViewBuilder private func paneActions(_ role: WorkspacePane) -> some View {
    switch role {
    case .input: ScenarioInputActions(session: session)
    case .secondary: secondaryActions
    case .output:
      if let output = session.output { resultActions(output) }
      else { Button {} label: { Label(L10n.tr("Copy"), systemImage: "doc.on.doc") }.disabled(true) }
    }
    if role != .output && !visible.contains(.output), session.error != nil {
      PaneStatusLabel(status: resultStatus).labelStyle(.iconOnly)
    }
  }
  private var secondaryActions: some View {
    Group {
      Button {
        if let text = NSPasteboard.general.string(forType: .string) { session.input.secondary = text; session.refreshLayout() }
      } label: { Label(L10n.tr("Paste"), systemImage: "doc.on.clipboard") }.help(L10n.tr("Paste Text"))
      Button { session.chooseFile(secondary: true) } label: { Label(L10n.tr("Import…"), systemImage: "square.and.arrow.down") }
        .help(L10n.tr("Import from File"))
      Button { session.input.secondary = "" } label: { Label(L10n.tr("Clear \(form.secondaryTitle)"), systemImage: "trash") }
        .labelStyle(.iconOnly).help(L10n.tr("Clear \(form.secondaryTitle)"))
    }
  }
  private var secondaryInput: some View {
    VStack(spacing: 0) {
      CodeEditor(text: $session.input.secondary, label: form.secondaryTitle, language: inputLanguage, contentSettled: session.refreshLayout,
        editingBegan: { focusedPane = .secondary }, state: viewState.secondaryEditor)
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
        ResultReportView(report: ResultReport("failure", L10n.tr("Could Not Complete Processing"), error))
        WorkspaceEmptyState(title: L10n.tr("Correct the input and run again"), detail: L10n.tr("Your input has been preserved."), symbol: "square.and.pencil", tint: .secondary) { EmptyView() }
      } else if let output = session.output {
        if !session.current {
          Text(L10n.tr("The previous result is shown below. The current input has not finished processing.")).font(.caption).foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        }
        if let report = output.report { ResultReportView(report: report) }
        resultBody(output).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        if let note = output.note {
          Text(note).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        }

      } else {
        WorkspaceEmptyState(title: session.bridge.running ? L10n.tr("Processing Input") : L10n.tr("Results Will Appear Here"),
          detail: session.bridge.running ? L10n.tr("Click Cancel at the top to stop processing.") : L10n.tr("When the input is ready, click “\(form.action)” at the top"),
          symbol: session.error != nil ? "exclamationmark.circle" : form.isImage || session.metadata.id == "qr-code" ? "photo" : "arrow.right",
          tint: session.error == nil ? .purple : .red) {
          EmptyView()
        }
      }
      if !resultUsesEditor {
        HStack(spacing: 8) {
          PaneStatusLabel(status: resultStatus)
          Spacer(minLength: 8)
          if session.error == nil, let output = session.output, !output.text.isEmpty {
            if display == "preview", session.imageArtifact != nil,
              output.artifacts.indices.contains(selectedArtifact) {
              Text(ByteCountFormatter.string(fromByteCount: Int64(output.artifacts[selectedArtifact].data.count), countStyle: .file)).monospacedDigit()
            } else { Text(L10n.tr("Characters: \(output.text.count)")).monospacedDigit() }
          }
        }.font(.system(size: 10)).foregroundStyle(.secondary)
          .padding(.horizontal, 16).frame(height: 28)
          .background(.primary.opacity(0.025))
          .overlay(alignment: .top) { Divider().opacity(0.5) }
      }
    }.id(session.completedRun)
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
    if output.report != nil && session.imageArtifact == nil {
      var views = [(session.metadata.id == "json" ? L10n.tr("Path List") : L10n.tr("Issue Details"), "rows", "list.bullet")]
      if output.html != nil { views.append((L10n.tr("Highlighted Comparison"), "preview", "rectangle.split.2x1")) }
      views.append((L10n.tr("Text"), "text", "text.alignleft"))
      return views
    }
    var views = [(session.metadata.id == "http-client" ? L10n.tr("Body") : L10n.tr("Text"), "text", "text.alignleft")]
    if session.binaryArtifact != nil { views.append((L10n.tr("File"), "files", "doc")) }
    if !output.rows.isEmpty {
      views.append((session.metadata.id == "http-client" ? L10n.tr("Status and Response Headers") : L10n.tr("Items"), "rows", "list.bullet"))
    }
    if output.html != nil || session.imageArtifact != nil { views.append((session.metadata.id == "json" ? L10n.tr("Collapsible View") : L10n.tr("Preview"), "preview", "eye")) }
    return views
  }
  private func resultActions(_ output: ToolOutput) -> some View {
    let views = resultViews(output)
    return Group {
      if output.report != nil, output.html != nil {
        WorkspaceSegments(items: [(session.metadata.id == "json" ? L10n.tr("Path") : L10n.tr("Details"), "rows"),
          (L10n.tr("Highlights"), "preview"), (L10n.tr("Text"), "text")], selection: $viewState.display)
          .accessibilityElement(children: .contain).accessibilityLabel(L10n.tr("Result View")).help(L10n.tr("Switch between issue paths and highlighted comparison"))
      } else if views.count > 1 {
        Menu {
          Picker(L10n.tr("Result View"), selection: $viewState.display) {
            ForEach(views, id: \.1) { view in Label(view.0, systemImage: view.2).tag(view.1) }
          }
        } label: {
          let current = views.first { $0.1 == display } ?? views[0]
          Label(current.0, systemImage: current.2)
        }.menuStyle(.button).fixedSize().help(L10n.tr("Switch Result View"))
      }
      if session.binaryArtifact == nil || display == "text" {
        Button { session.copyResult() } label: {
          Label(session.copied ? L10n.tr("Copied") : session.imageArtifact != nil ? L10n.tr("Copy Image") : L10n.tr("Copy"),
            systemImage: session.copied ? "checkmark" : "doc.on.doc").contentTransition(.symbolEffect(.replace))
        }.buttonStyle(.bordered).tint(.blue)
          .help(session.imageArtifact != nil ? L10n.tr("Copy Image") : L10n.tr("Copy Full Result ⌘⇧C")).disabled(!session.current)
      }
      if output.artifacts.isEmpty {
        Button { session.save(session.textArtifact) } label: { Label(L10n.tr("Export…"), systemImage: "square.and.arrow.up") }
          .help(L10n.tr("Export to File")).disabled(!session.current)
      } else if output.artifacts.count == 1 {
        Button { session.save(output.artifacts[0]) } label: {
          Label(session.imageArtifact != nil ? L10n.tr("Save Image…") : L10n.tr("Save File…"), systemImage: "square.and.arrow.down")
        }.help(session.imageArtifact != nil ? L10n.tr("Save Image") : L10n.tr("Save File")).disabled(!session.current)
      } else {
        Menu {
          Button(L10n.tr("Export All to Folder…")) { session.saveAllArtifacts() }
          Divider()
          ForEach(output.artifacts.indices, id: \.self) { index in
            Button(output.artifacts[index].name) { session.save(output.artifacts[index]) }
          }
        } label: { Label(L10n.tr("Export File"), systemImage: "square.and.arrow.up") }
          .fixedSize().help(L10n.tr("Choose a file to export")).disabled(!session.current)
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
        Button { session.save(artifact) } label: { Label(L10n.tr("Save File…"), systemImage: "square.and.arrow.down") }
          .buttonStyle(.borderedProminent).controlSize(.large).disabled(!session.current)
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if display == "preview", let html = output.html { SafePreview(html: html, toolID: session.metadata.id) }
    else if display == "preview", session.imageArtifact != nil {
      VStack(spacing: 10) {
        if output.artifacts.count > 1 {
          Picker(L10n.tr("Preview File"), selection: $viewState.selectedArtifact) {
            ForEach(output.artifacts.indices, id: \.self) { index in Text(output.artifacts[index].name).tag(index) }
          }.padding(12)
        }
        if output.artifacts.indices.contains(selectedArtifact) {
          if output.report == nil {
            Text(output.text).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
              .padding(.horizontal, 16).padding(.top, 8)
          }
          let artifact = output.artifacts[selectedArtifact]
          Text(artifact.name + " · " + ByteCountFormatter.string(fromByteCount: Int64(artifact.data.count), countStyle: .file))
            .font(.caption).foregroundStyle(.secondary)
          RasterImagePreview(data: artifact.data, pixelated: session.metadata.id == "qr-code")
            .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else { Text(L10n.tr("Save this file using the export menu")).foregroundStyle(.secondary) }
      }
    } else if display == "rows", output.rows.isEmpty, output.report != nil {
      if let html = output.html { SafePreview(html: html, toolID: session.metadata.id) }
      else {
        CodeEditor(text: .constant(output.text), editable: false, label: L10n.tr("Validation Details"), language: outputLanguage, status: resultStatus, state: viewState.outputEditor, contentID: session.completedRun)
      }
    } else if display == "rows", !output.rows.isEmpty {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(Array(output.rows.enumerated()), id: \.offset) { _, row in
            HStack(alignment: .top, spacing: 16) {
              Text(row.label).font(.system(.body, design: .monospaced))
                .foregroundStyle(rowTint(row, report: output.report))
                .frame(minWidth: 70, alignment: .leading)
              HighlightedText(text: row.value.isEmpty ? L10n.tr("(Empty value)") : output.report != nil && row.value.count > 1200
                ? String(row.value.prefix(1200)) + L10n.tr("\n…(Copy or export for the full content)") : row.value,
                language: output.report == nil ? .automatic : .plain, fontSize: fontSize)
                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
              Button { if Clipboard.copy(row.value) { session.status = L10n.tr("Copied") } } label: { Image(systemName: "doc.on.doc") }
                .buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.small)
                .disabled(!session.current).accessibilityLabel(L10n.tr("Copy ") + row.label)
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
      CodeEditor(text: .constant(output.text), editable: false, label: form.outputTitle,
        language: outputLanguage, status: resultStatus, state: viewState.outputEditor, contentID: session.completedRun)
    }
  }
  private func rowTint(_ row: ResultRow, report: ResultReport?) -> Color {
    if session.metadata.id == "contrast" {
      return row.value == L10n.tr("Pass") ? .green : row.value == L10n.tr("Failed") ? .red : .secondary
    }
    if session.metadata.id == "jwt", row.label != L10n.tr("Signature") { return .secondary }
    if report?.state == "failure" { return .red }
    if row.label.hasPrefix("+ ") { return .green }
    if row.label.hasPrefix("− ") { return .red }
    if row.label.hasPrefix("~ ") { return .orange }
    return .secondary
  }
  private func detach(_ pane: DetachedWorkspacePane) { DetachedWorkspaceWindows.shared.open(session, pane: pane) }
}
