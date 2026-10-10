import DevKitCore
import SwiftUI

/// Lives in the pane header. Editor options open without taking height from text.
struct ScenarioInputActions<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  @State private var optionsPresented = false
  private var form: ToolPresentation { session.presentation }
  private var fields: [OptionField<T.Options>] {
    session.visibleFields.filter { $0.id != primaryToolField(T.self)?.id }
  }
  private var hasEditorOptions: Bool {
    !form.isForm && !form.isImage && form.control != .request && session.inputStyle != .file
      && session.input.file == nil && !fields.isEmpty
  }
  private var optionsHeight: CGFloat {
    let controls = fields.reduce(CGFloat.zero) { height, field in
      switch field.kind {
      case .toggle: return height + 24
      case .choice, .integer: return height + 30
      default: return height + 64
      }
    }
    return min(controls + CGFloat(max(0, fields.count - 1)) * 16 + 4, 320)
  }
  var body: some View {
    if form.control != .generator {
      if !form.isImage && session.inputStyle != .file {
        if !T.example(for: session.options).text.isEmpty {
          Button { session.useExample() } label: {
            Label("示例", systemImage: "lightbulb").foregroundStyle(.orange)
          }.help("填入示例")
        }
        if ![.pairs, .template].contains(form.control) {
          Button { session.paste() } label: {
            Label("粘贴", systemImage: "doc.on.clipboard").foregroundStyle(.blue)
          }.help("粘贴文本")
        }
      }
      if form.isImage {
        Button { session.paste() } label: { Label("粘贴图片", systemImage: "doc.on.clipboard") }.help("粘贴图片")
      }
      if !form.isForm || [.pairs, .template].contains(form.control) {
        Button { session.chooseFile() } label: {
          Label(form.isImage ? "选择图片" : session.inputStyle == .file ? "选择文件" : "导入",
            systemImage: form.isImage ? "photo" : "square.and.arrow.down")
        }.foregroundStyle(.blue).help("从文件导入")
      }
      if hasEditorOptions {
        Button { optionsPresented.toggle() } label: {
          Label("选项", systemImage: "slider.horizontal.3")
        }.help("配置工具参数")
          .popover(isPresented: $optionsPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 14) {
              HStack {
                Text("工具参数").font(.headline)
                Spacer()
                Button("完成") { optionsPresented = false }.buttonStyle(.borderless)
              }
              ScrollView {
                ToolParameterFields(options: $session.options, fields: fields).padding(.vertical, 2)
              }.frame(height: optionsHeight)
            }.padding(18).frame(width: 320)
          }
      }
      Button { session.clearInput() } label: { Label("清空输入", systemImage: "trash") }
        .labelStyle(.iconOnly).help("清空输入")
    } else {
      Button { session.options = T.Options() } label: { Label("重置", systemImage: "arrow.counterclockwise") }
        .help("恢复默认参数")
    }
  }
}

struct ScenarioInput<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var editingBegan: () -> Void = {}
  @State private var timestampSource = "timestamp"
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var form: ToolPresentation { session.presentation }
  private var fields: [OptionField<T.Options>] {
    session.visibleFields.filter { $0.id != primaryToolField(T.self)?.id }
  }
  var body: some View {
    VStack(spacing: 0) {
      if form.isForm {
        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            formInput
            ToolParameterFields(options: $session.options, fields: fields)
            Button { session.run() } label: {
              Label(session.bridge.running ? "取消" : form.action,
                systemImage: session.bridge.running ? "stop.fill" : "play.fill")
            }.buttonStyle(.borderedProminent).controlSize(.large)
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
          contentSettled: session.refreshLayout, editingBegan: editingBegan)
          .overlay {
            if session.input.text.isEmpty {
              WorkspaceEmptyState(title: "从一段内容开始", detail: form.placeholder,
                symbol: "text.cursor", tint: .blue) {
                HStack(spacing: 8) {
                  if !T.example(for: session.options).text.isEmpty {
                    Button { session.useExample() } label: { Label("填入示例", systemImage: "lightbulb") }
                  }
                  Button { session.chooseFile() } label: { Label("导入文件", systemImage: "square.and.arrow.down") }
                }
              }.padding(.bottom, 28)
            }
          }
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: session.operation)
      .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: session.input.file != nil)
      .animation(WorkspaceMotion.layout(reduceMotion: reduceMotion), value: timestampSource)
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
        Text("Aa 文字对比预览").font(.title2.weight(.medium)).padding(20).frame(maxWidth: .infinity)
          .foregroundStyle(Color(.sRGB, red: foreground.r, green: foreground.g, blue: foreground.b))
          .background(Color(.sRGB, red: background.r, green: background.g, blue: background.b), in: RoundedRectangle(cornerRadius: 10))
      }
    case .date:
      DateValueControl(title: "日期", text: $session.input.text)
    case .timestamp:
      Picker("输入方式", selection: $timestampSource) {
        Text("时间戳 → 日期").tag("timestamp")
        Text("日期 → 时间戳").tag("date")
      }.pickerStyle(.segmented)
        .onChange(of: timestampSource) { _, value in
          if value == "date" {
            let scale = session.optionValues["unit"] == "milliseconds" ? 1000.0 : 1.0
            let interval = Double(session.input.text).map { $0 / scale }
            session.input.text = Dates.iso(interval.map(Date.init(timeIntervalSince1970:)) ?? Date())
          } else if let date = Dates.parse(session.input.text) {
            let scale = session.optionValues["unit"] == "milliseconds" ? 1000.0 : 1.0
            session.input.text = String(Int64((date.timeIntervalSince1970 * scale).rounded()))
          }
        }
      if timestampSource == "date" { DateValueControl(title: "日期", text: $session.input.text) }
      else {
        HStack {
          TextField("Unix 时间戳", text: $session.input.text).textFieldStyle(.roundedBorder)
          Button {
            let scale = session.optionValues["unit"] == "milliseconds" ? 1000.0 : 1.0
            session.input.text = String(Int64((Date().timeIntervalSince1970 * scale).rounded()))
          } label: { Label("现在", systemImage: "clock") }.buttonStyle(.bordered)
        }
      }
    case .pairs: KeyValueEditor(text: $session.input.text)
    case .template: KeyValueEditor(text: $session.input.text, kind: .template)
    case .generator: EmptyView()
    default:
      VStack(alignment: .leading, spacing: 8) {
        TextField(form.placeholder, text: $session.input.text).textFieldStyle(.roundedBorder)
          .font(.system(size: 16, design: .monospaced)).onSubmit { session.run() }
          .accessibilityLabel(form.inputTitle)
        if session.metadata.id == "http-status" {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], alignment: .leading) { ForEach([200, 201, 301, 400, 401, 404, 500], id: \.self) { code in
            Button(String(code)) { session.input.text = String(code); session.run() }.buttonStyle(.bordered)
          } }
        }
      }
    }
  }
  private var fileInput: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        if let data = session.input.file {
          if let image = RasterPreview.image(data), form.isImage {
            Image(nsImage: image).resizable().interpolation(session.metadata.id == "qr-code" ? .none : .high)
              .scaledToFit().frame(maxWidth: .infinity).frame(height: 230)
          } else { Image(systemName: "doc.fill").font(.system(size: 44)).foregroundStyle(.secondary) }
          Text(session.input.fileName ?? "文件").font(.headline).textSelection(.enabled)
          Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
            .font(.caption).foregroundStyle(.secondary)
          Button { session.chooseFile() } label: {
            Label(form.isImage ? "更换图片…" : "更换文件…", systemImage: form.isImage ? "photo" : "folder")
          }.buttonStyle(.bordered)
        } else {
          VStack(spacing: 16) {
            Image(systemName: form.isImage ? "photo.badge.plus" : "doc.badge.plus").font(.system(size: 36)).foregroundStyle(.tertiary)
            Text(form.isImage ? "拖入图片，或选择图片" : "拖入文件，或选择文件").foregroundStyle(.secondary)
            Button { session.chooseFile() } label: {
              Label(form.isImage ? "选择图片…" : "选择文件…", systemImage: form.isImage ? "photo" : "folder")
            }.buttonStyle(.bordered).controlSize(.large)
          }.frame(maxWidth: .infinity).padding(.vertical, 38)
        }
        ToolParameterFields(options: $session.options, fields: fields)
        Button { session.run() } label: {
          Label(session.bridge.running ? "取消" : form.action,
            systemImage: session.bridge.running ? "stop.fill" : "play.fill")
        }.buttonStyle(.borderedProminent).controlSize(.large).disabled(session.input.file == nil)
      }.padding(20)
    }
  }
  private var requestInput: some View {
    VStack(alignment: .leading, spacing: 0) {
      TextField("https://example.com/api", text: $session.input.text).textFieldStyle(.roundedBorder)
        .accessibilityLabel("请求 URL").padding(16)
      ScrollView { ToolParameterFields(options: $session.options, fields: fields).padding(.horizontal, 16).padding(.bottom, 12) }
        .frame(height: 155)
      Divider()
      Text("请求体").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 10)
      CodeEditor(text: $session.input.secondary, label: "请求体", contentSettled: session.refreshLayout, editingBegan: editingBegan)
    }
  }
}
