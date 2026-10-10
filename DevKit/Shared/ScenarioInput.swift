import DevKitCore
import SwiftUI

struct ScenarioInput<T: ToolModule>: View {
  @Bindable var session: ToolSession<T>
  var editingBegan: () -> Void = {}
  @State private var timestampSource = "timestamp"
  private var form: ToolPresentation { session.presentation }
  private var fields: [OptionField<T.Options>] {
    session.visibleFields.filter { $0.id != primaryToolField(T.self)?.id }
  }
  var body: some View {
    VStack(spacing: 0) {
      inputActions
      if form.isForm {
        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            formInput
            ToolParameterFields(options: $session.options, fields: fields)
            Button(session.bridge.running ? "取消" : form.action) { session.run() }
              .buttonStyle(.glassProminent)
          }.padding(20).frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
      } else if session.input.file != nil || session.inputStyle == .file {
        fileInput
      } else if form.control == .request {
        requestInput
      } else {
        if !fields.isEmpty {
          ScrollView { ToolParameterFields(options: $session.options, fields: fields).padding(16) }
            .frame(height: min(CGFloat(fields.count) * 64 + 16, 250))
          Divider()
        }
        CodeEditor(text: $session.input.text, label: form.inputTitle,
          contentSettled: session.refreshLayout, editingBegan: editingBegan)
          .overlay(alignment: .topLeading) {
            if session.input.text.isEmpty {
              Text(form.placeholder).font(.system(size: 13)).foregroundStyle(.tertiary)
                .padding(16).allowsHitTesting(false)
            }
          }
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .onDrop(of: [.fileURL], isTargeted: nil) { providers in
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
          if let url { Task { @MainActor in session.loadFile(url) } }
        }
        return true
      }
  }
  private var inputActions: some View {
    HStack(spacing: 10) {
      if form.control != .generator {
        if !form.isImage && session.inputStyle != .file {
          if !T.example(for: session.options).text.isEmpty {
            Button("示例") { session.useExample() }
          }
          if ![.pairs, .template].contains(form.control) { Button("粘贴") { session.paste() } }
        }
        if form.isImage { Button("粘贴图片") { session.paste() } }
        if !form.isForm || [.pairs, .template].contains(form.control) {
          Button(form.isImage ? "选择图片…" : session.inputStyle == .file ? "选择文件…" : "导入…") { session.chooseFile() }
        }
        Spacer()
        Button { session.clearInput() } label: { Image(systemName: "trash") }
          .help("清空输入").accessibilityLabel("清空输入")
      } else {
        Spacer()
        Button("重置") { session.options = T.Options() }
      }
    }.font(.system(size: 12)).buttonStyle(.glass).controlSize(.small).padding(.horizontal, 14).padding(.vertical, 9)
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
          Button("现在") {
            let scale = session.optionValues["unit"] == "milliseconds" ? 1000.0 : 1.0
            session.input.text = String(Int64((Date().timeIntervalSince1970 * scale).rounded()))
          }.buttonStyle(.glass)
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
            Button(String(code)) { session.input.text = String(code); session.run() }.buttonStyle(.glass)
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
          Button(form.isImage ? "更换图片…" : "更换文件…") { session.chooseFile() }.buttonStyle(.glass)
        } else {
          VStack(spacing: 16) {
            Image(systemName: form.isImage ? "photo.badge.plus" : "doc.badge.plus").font(.system(size: 36)).foregroundStyle(.tertiary)
            Text(form.isImage ? "拖入图片，或选择图片" : "拖入文件，或选择文件").foregroundStyle(.secondary)
            Button(form.isImage ? "选择图片…" : "选择文件…") { session.chooseFile() }.buttonStyle(.glass)
          }.frame(maxWidth: .infinity).padding(.vertical, 38)
        }
        ToolParameterFields(options: $session.options, fields: fields)
        Button(session.bridge.running ? "取消" : form.action) { session.run() }
          .buttonStyle(.glassProminent).disabled(session.input.file == nil)
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
