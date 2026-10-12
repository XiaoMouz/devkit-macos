import DevKitCore
import SwiftUI

/// Pane-local actions. Core task parameters live above both editor panes.
struct ScenarioInputActions<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  private var form: ToolPresentation { session.presentation }
  var body: some View {
    if form.control != .generator {
      if !form.isImage && session.inputStyle != .file {
        if !T.example(for: session.options).text.isEmpty {
          Button { session.useExample() } label: {
            Label(L10n.tr("Example"), systemImage: "lightbulb").foregroundStyle(.orange)
          }.help(L10n.tr("Load Example"))
        }
        if ![.pairs, .template].contains(form.control) {
          Button { session.paste() } label: {
            Label(L10n.tr("Paste"), systemImage: "doc.on.clipboard").foregroundStyle(.blue)
          }.help(L10n.tr("Paste Text"))
        }
      }
      if form.isImage {
        Button { session.paste() } label: { Label(L10n.tr("Paste Image"), systemImage: "doc.on.clipboard") }.help(L10n.tr("Paste Image"))
      }
      if !form.isForm || [.pairs, .template].contains(form.control) {
        Button { session.chooseFile() } label: {
          Label(form.isImage ? L10n.tr("Choose Image") : session.inputStyle == .file ? L10n.tr("Choose File") : L10n.tr("Import"),
            systemImage: form.isImage ? "photo" : "square.and.arrow.down")
        }.foregroundStyle(.blue).help(L10n.tr("Import from File"))
      }
      Button { session.clearInput() } label: { Label(L10n.tr("Clear Input"), systemImage: "trash") }
        .labelStyle(.iconOnly).help(L10n.tr("Clear Input"))
    } else {
      Button { session.options = T.Options() } label: { Label(L10n.tr("Reset"), systemImage: "arrow.counterclockwise") }
        .help(L10n.tr("Restore Default Parameters"))
    }
  }
}

struct ScenarioInput<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var editingBegan: () -> Void = {}
  var editorState: EditorViewState? = nil
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var form: ToolPresentation { session.presentation }
  private var fields: [OptionField<T.Options>] {
    session.visibleFields.filter { $0.id != primaryToolField(T.self)?.id }
  }
  var body: some View {
    VStack(spacing: 0) {
      if let failure = session.importFailure {
        VStack(alignment: .leading, spacing: 8) {
          Label(failure, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
          Button(L10n.tr("Continue with Current Input")) { session.importFailure = nil; session.error = nil; session.status = "" }
        }.font(.callout).padding(12).frame(maxWidth: .infinity, alignment: .leading)
      }
      if form.isForm {
        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            formInput
            ToolParameterFields(options: $session.options, fields: fields)
          }.padding(20).frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
      } else if session.input.file != nil || session.inputStyle == .file {
        fileInput
      } else if form.control == .request {
        requestInput
      } else {
        CodeEditor(text: $session.input.text, label: form.inputTitle,
          language: .forTool(session.metadata.id, values: session.optionValues),
          contentSettled: session.refreshLayout, editingBegan: editingBegan, state: editorState)
          .overlay {
            if session.input.text.isEmpty {
              WorkspaceEmptyState(title: L10n.tr("Start with some content"), detail: form.placeholder,
                symbol: "text.cursor", tint: .blue) {
                HStack(spacing: 8) {
                  if !T.example(for: session.options).text.isEmpty {
                    Button { session.useExample() } label: { Label(L10n.tr("Load Example"), systemImage: "lightbulb") }
                  }
                  Button { session.chooseFile() } label: { Label(L10n.tr("Import File"), systemImage: "square.and.arrow.down") }
                }
              }.padding(.bottom, 28)
            }
          }
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: session.operation)
      .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: session.input.file != nil)
      .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: session.timestampSource)
      .onDrop(of: [.fileURL], isTargeted: nil) { providers in
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
          if let url { Task { @MainActor in session.loadFile(url) } }
        }
        return true
      }
  }
  @ViewBuilder private var formInput: some View {
    switch form.control {
    case .color:
      ColorValueControl(title: form.inputTitle, text: $session.input.text, supportsOpacity: session.metadata.id != "contrast")
      if session.metadata.id == "contrast", let foreground = try? ColorValue.parse(session.input.text),
        let background = try? ColorValue.parse(session.optionValues["background"] ?? "") {
        Text(L10n.tr("Aa Text Contrast Preview")).font(.title2.weight(.medium)).padding(20).frame(maxWidth: .infinity)
          .foregroundStyle(Color(.sRGB, red: foreground.r, green: foreground.g, blue: foreground.b))
          .background(Color(.sRGB, red: background.r, green: background.g, blue: background.b), in: RoundedRectangle(cornerRadius: 10))
      }
    case .date:
      DateValueControl(title: L10n.tr("Date and Time"), text: $session.input.text, timeZone: session.inputTimeZone)
    case .timestamp:
      ToolFormRow(title: L10n.tr("Conversion Direction")) {
        WorkspaceSegments(items: [(L10n.tr("Timestamp → Date"), "timestamp"), (L10n.tr("Date → Timestamp"), "date")],
          selection: Binding(get: { session.timestampSource }, set: { session.changeTimestampSource($0) }))
          .accessibilityElement(children: .contain).accessibilityLabel(L10n.tr("Input Mode"))
      }
      if session.timestampSource == "date" {
        DateValueControl(title: L10n.tr("Date and Time"), text: $session.input.text, timeZone: session.inputTimeZone)
      }
      else {
        ToolFormRow(title: L10n.tr("Unix Timestamp")) {
          HStack {
            TextField(L10n.tr("Leave empty to use the current time"), text: $session.input.text).textFieldStyle(.roundedBorder)
            Button {
              session.input.text = Dates.timestamp(Date(), milliseconds: session.optionValues["unit"] == "milliseconds")
            } label: { Image(systemName: "clock") }
              .buttonStyle(.bordered).buttonBorderShape(.capsule).help(L10n.tr("Use Current Timestamp")).accessibilityLabel(L10n.tr("Use Current Timestamp"))
          }
        }
      }
    case .pairs: KeyValueEditor(text: $session.input.text)
    case .template: KeyValueEditor(text: $session.input.text, kind: .template)
    case .generator: EmptyView()
    default:
      VStack(alignment: .leading, spacing: 8) {
        ToolFormRow(title: form.inputTitle) {
          TextField(form.placeholder, text: $session.input.text).textFieldStyle(.roundedBorder)
            .font(.system(size: 14, design: .monospaced)).onSubmit { session.run() }
            .accessibilityLabel(form.inputTitle)
        }
        if session.metadata.id == "http-status" {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], alignment: .leading) { ForEach([200, 201, 301, 400, 401, 404, 500], id: \.self) { code in
            Button(String(code)) { session.input.text = String(code); session.run() }.buttonStyle(.bordered).buttonBorderShape(.capsule)
          } }
        }
      }
    }
  }
  private var fileInput: some View {
    GeometryReader { bounds in
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          if let data = session.input.file {
            if form.isImage {
              RasterImagePreview(data: data, pixelated: session.metadata.id == "qr-code")
                .frame(maxWidth: .infinity).frame(height: 230)
            } else { Image(systemName: "doc.fill").font(.system(size: 44)).foregroundStyle(.secondary) }
            Text(session.input.fileName ?? L10n.tr("File")).font(.headline).textSelection(.enabled)
              .id(session.input.fileName)
            Text(ByteCountFormatter.string(fromByteCount: session.checksumURL != nil ? session.checksumFileSize : Int64(data.count), countStyle: .file))
              .font(.caption).foregroundStyle(.secondary)
            Button { session.chooseFile() } label: {
              Label(form.isImage ? L10n.tr("Replace Image…") : L10n.tr("Replace File…"), systemImage: form.isImage ? "photo" : "folder")
            }.buttonStyle(.bordered).buttonBorderShape(.capsule)
          } else {
            VStack(spacing: 16) {
              Image(systemName: form.isImage ? "photo.badge.plus" : "doc.badge.plus").font(.system(size: 36)).foregroundStyle(.tertiary)
              Text(form.isImage ? L10n.tr("Drop an image or choose one") : L10n.tr("Drop a file or choose one")).foregroundStyle(.secondary)
              Button { session.chooseFile() } label: {
                Label(form.isImage ? L10n.tr("Choose Image…") : L10n.tr("Choose File…"), systemImage: form.isImage ? "photo" : "folder")
              }.buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.large)
            }.frame(maxWidth: .infinity).padding(.vertical, 38)
          }
          ToolParameterFields(options: $session.options, fields: fields)
        }.padding(20).frame(maxWidth: .infinity)
          .frame(minHeight: session.metadata.id == "data-url" ? bounds.size.height : 0,
            alignment: session.metadata.id == "data-url" ? .center : .topLeading)
      }
    }
  }
  private var requestInput: some View {
    VStack(alignment: .leading, spacing: 0) {
      TextField("https://example.com/api", text: $session.input.text).textFieldStyle(.roundedBorder)
        .accessibilityLabel(L10n.tr("Request URL")).padding(16)
      ScrollView { ToolParameterFields(options: $session.options, fields: fields).padding(.horizontal, 16).padding(.bottom, 12) }
        .frame(height: 155)
      Divider()
      Text(L10n.tr("Request Body")).font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 10)
      CodeEditor(text: $session.input.secondary, label: L10n.tr("Request Body"), contentSettled: session.refreshLayout, editingBegan: editingBegan, state: editorState)
    }
  }
}
