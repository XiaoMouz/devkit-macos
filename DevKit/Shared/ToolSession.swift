import AppKit
import DevKitCore
import SwiftUI
import UniformTypeIdentifiers
import OSLog

/// All presentations of a tool share this in-memory session, never copies of its text.
@MainActor @Observable final class ToolSession<T: ToolModule> {
  let id: UUID
  let bridge: WorkspaceBridge
  let viewState = WorkspaceViewState()
  var input = ToolInput() {
    didSet {
      guard
        input.text != oldValue.text || input.secondary != oldValue.secondary
          || input.file != oldValue.file || input.fileName != oldValue.fileName
      else { return }
      importFailure = nil
      invalidate()
    }
  }
  var options = T.Options() {
    didSet {
      guard T.fields.contains(where: { $0.read(options) != $0.read(oldValue) }) else { return }
      let oldOperation = T.fields.first { $0.id == "operation" }?.read(oldValue) ?? ""
      if metadata.id == "query-string", oldOperation != operation {
        var conversion = QueryStringTool.Options()
        conversion.form = optionValues["form"] == "true"
        if operation == "build" {
          conversion.operation = "parse"
          if let result = try? QueryStringTool.convert(input, options: conversion) { input.text = result.text }
        } else if oldOperation == "build" {
          conversion.operation = "build"
          if let result = try? QueryStringTool.convert(input, options: conversion) { input.text = result.text }
        }
        output = nil
      } else if metadata.id == "json", oldOperation != operation {
        secondaryDrafts[oldOperation] = input.secondary
        input.secondary = secondaryDrafts[operation] ?? ""
        output = nil
      } else if T.inputStyle(for: oldValue) != inputStyle,
        [T.inputStyle(for: oldValue), inputStyle].contains(.file)
          || [T.inputStyle(for: oldValue), inputStyle].contains(.generator) {
        input = ToolInput()
        output = nil
      }
      if input.file != nil && inputStyle != .file && !presentation.acceptsBinary {
        input = ToolInput(text: current ? output?.text ?? "" : "", secondary: input.secondary)
        output = nil
      }
      if output == nil { elapsed = 0 }
      bridge.actionTitle = presentation.action
      invalidate()
      refreshLayout()
    }
  }
  private var secondaryDrafts: [String: String] = [:]
  private(set) var output: ToolOutput?
  private(set) var revision = 0
  private var resultRevision = -1
  private var task: Task<Void, Never>?
  private let execute: @Sendable (WorkerRequest) async throws -> ToolOutput
  var error: String?
  var importFailure: String?
  private(set) var checksumURL: URL?
  private(set) var checksumFileSize: Int64 = 0
  var status = ""
  var copied = false
  private(set) var timestampSource = "timestamp"
  var inputTimeZone: TimeZone {
    let identifier = metadata.id == "date-time"
      ? optionValues[operation == "zones" ? "sourceZone" : "zone"] : optionValues["timezone"]
    return identifier.flatMap(TimeZone.init(identifier:)) ?? .current
  }
  func changeTimestampSource(_ source: String) {
    guard metadata.id == "timestamp", source != timestampSource,
      let options = options as? TimestampTool.Options else { return }
    do {
      let date = try TimestampTool.date(from: input.text, options: options)
      timestampSource = source
      input.text = source == "date" ? Dates.iso(date) : Dates.timestamp(date, milliseconds: options.unit == "milliseconds")
    } catch { self.error = error.localizedDescription }
  }
  var elapsed = 0.0
  private(set) var completedRun = 0
  var layoutPolicy = WorkspaceLayoutPolicy()
  private(set) var sourceIsOpen = true
  private(set) var detachedCount = 0
  var metadata: ToolMetadata { T.metadata }
  var inputStyle: InputStyle { T.inputStyle(for: options) }
  var operation: String { T.fields.first { $0.id == "operation" }?.read(options) ?? "" }
  var optionValues: [String: String] { Dictionary(uniqueKeysWithValues: T.fields.map { ($0.id, $0.read(options)) }) }
  var presentation: ToolPresentation { ToolPresentation(id: metadata.id, style: inputStyle, values: optionValues) }
  var visibleFields: [OptionField<T.Options>] { T.visibleFields(for: options) }
  var imageArtifact: Artifact? { output?.artifacts.first { RasterPreview.mimeTypes.contains($0.mime) } }
  var binaryArtifact: Artifact? {
    output?.artifacts.first {
      !RasterPreview.mimeTypes.contains($0.mime) && UTType(mimeType: $0.mime)?.conforms(to: .text) != true
    }
  }
  var textArtifact: Artifact { Artifact(presentation.exportName, presentation.exportMIME, Data((output?.text ?? "").utf8)) }
  var current: Bool { output != nil && resultRevision == revision && !bridge.running }
  var recommendedDisplay: String {
    guard let output else { return "text" }
    if presentation.isImage && metadata.id != "image-metadata" && imageArtifact != nil { return "preview" }
    if output.report != nil { return "rows" }
    if ["color", "contrast"].contains(metadata.id) { return "rows" }
    if metadata.id == "image-metadata" { return "rows" }
    if metadata.id == "http-client" { return imageArtifact != nil ? "preview" : binaryArtifact != nil ? "files" : output.text.isEmpty ? "rows" : "text" }
    if binaryArtifact != nil && imageArtifact == nil { return "files" }
    return output.html != nil
      || output.artifacts.contains { RasterPreview.mimeTypes.contains($0.mime) }
      ? "preview" : output.rows.isEmpty ? "text" : "rows"
  }
  init(
    id: UUID, bridge: WorkspaceBridge,
    execute: @escaping @Sendable (WorkerRequest) async throws -> ToolOutput = WorkerRunner.run
  ) {
    self.execute = execute
    self.id = id
    self.bridge = bridge
    bridge.actionTitle = presentation.action
    bridge.runAction = { [weak self] in self?.run() }
    bridge.copyAction = { [weak self] in self?.copyResult() }
    if presentation.control == .date { input.text = Dates.iso(Date()) }
    else if presentation.control == .color || presentation.control == .template { input = T.example(for: options) }

  }
  func refreshLayout() {
    var next = layoutPolicy
    if presentation.isForm || presentation.isImage || metadata.id == "qr-code" {
      next.evaluate(texts: [])
    } else {
      next.evaluate(
        texts: [input.text, input.secondary, current ? output?.text ?? "" : ""],
        fileBytes: input.file?.count ?? 0)
    }
    if next != layoutPolicy { layoutPolicy = next }
  }
  func chooseLayout(_ preference: WorkspaceLayoutPreference) {
    layoutPolicy.preference = preference
    refreshLayout()
  }
  func sourceClosed() {
    sourceIsOpen = false
    if detachedCount == 0 { cancel() }
  }
  func detachedOpened() { detachedCount += 1 }
  func detachedClosed() {
    detachedCount = max(0, detachedCount - 1)
    if !sourceIsOpen && detachedCount == 0 { cancel() }
  }
  func invalidate() {
    revision += 1
    copied = false
    error = nil
    if bridge.running {
      task?.cancel()
      bridge.running = false
    }
    status = output == nil ? "" : "内容已修改，重新执行以更新结果"
  }
  func cancel() {
    task?.cancel()
    task = nil
    if bridge.running {
      revision += 1
      bridge.running = false
      status = "已取消"
    }
  }
  func run() {
    if bridge.running {
      cancel()
      return
    }
    refreshLayout()
    // Commit the active number/date field before taking the execution snapshot.
    NSApp?.keyWindow?.makeFirstResponder(nil)
    do {
      if let importFailure { throw ToolFailure(importFailure) }
      for field in visibleFields {
        if case .integer(let range) = field.kind {
          guard let value = Int(field.read(options)), range.contains(value) else {
            throw ToolFailure("\(field.label)范围为 \(range.lowerBound)–\(range.upperBound)。")
          }
        }
      }
      try Limits.check(input)
      let request = WorkerRequest(
        id: metadata.id, input: input, options: try JSONEncoder().encode(options))
      let version = revision
      bridge.running = true
      error = nil
      copied = false
      status = "处理中…"
      let fileURL = checksumURL
      let checksumOptions = options as? FileChecksumTool.Options
      let progress: @Sendable (Int64, Int64) -> Void = { [weak self] read, total in
        Task { @MainActor [weak self] in
          guard let self, self.revision == version, self.bridge.running else { return }
          self.status = "已读取 \(ByteCountFormatter.string(fromByteCount: read, countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))"
        }
      }
      task = Task { @MainActor in
        let start = Date()
        do {
          let result: ToolOutput
          if let fileURL, let checksumOptions {
            result = try await FileChecksumTool.stream(fileURL, options: checksumOptions, progress: progress)
          } else { result = try await execute(request) }
          guard !Task.isCancelled && version == revision else { return }
          output = result
          resultRevision = version
          elapsed = Date().timeIntervalSince(start)
          bridge.running = false
          status = "已完成"
          task = nil
          completedRun += 1
          refreshLayout()
        } catch {
          guard !Task.isCancelled && version == revision else { return }
          self.error = metadata.network ? NetworkSupport.message(for: error) : error.localizedDescription
          output = nil
          resultRevision = -1
          bridge.running = false
          status = "需要检查输入"
          task = nil
        }
      }
    } catch { self.error = error.localizedDescription }
  }
  func copyResult() {
    guard current, let output else { return }
    if metadata.id != "image-metadata", let artifact = imageArtifact {
      copied = Clipboard.copyImage(artifact)
      status = copied ? "已复制图片" : "复制失败，请重试"
    } else {
      copied = Clipboard.copy(output.text)
      status = copied ? "已复制完整结果" : "复制失败，请重试"
    }
  }
  func useExample() {
    input = T.example(for: options)
    if metadata.id == "timestamp", timestampSource == "date", let settings = options as? TimestampTool.Options,
      let date = try? TimestampTool.date(from: input.text, options: settings) { input.text = Dates.iso(date) }
    if presentation.control == .date, let date = Dates.parse(input.text, timeZone: inputTimeZone) { input.text = Dates.iso(date) }
    refreshLayout()
  }
  func paste() {
    if presentation.isImage {
      if let data = NSPasteboard.general.data(forType: .png) ?? NSPasteboard.general.data(forType: .tiff) {
        input = ToolInput(file: data, fileName: "剪贴板图片")
        refreshLayout()
      } else { error = "剪贴板中没有图片。" }
      return
    }
    if let value = NSPasteboard.general.string(forType: .string) {
      if metadata.id == "timestamp", let settings = options as? TimestampTool.Options {
        do {
          let date = try TimestampTool.date(from: value, options: settings)
          if timestampSource == "date" || Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
            timestampSource = "date"
            input = ToolInput(text: Dates.iso(date))
          } else { input = ToolInput(text: value) }
        } catch { self.error = error.localizedDescription; return }
      } else if presentation.control == .date {
        guard let date = Dates.parse(value, timeZone: inputTimeZone), Dates.supportedRange.contains(date) else {
          error = "剪贴板中的日期无效，请使用 2026-10-12 09:00:00 这样的格式。"; return
        }
        input = ToolInput(text: Dates.iso(date))
      } else { input = ToolInput(text: value, secondary: input.secondary) }
      refreshLayout()
    }
  }
  func clearInput() {
    let large = input.text.utf8.count + input.secondary.utf8.count + (input.file?.count ?? 0)
      + (output?.text.utf8.count ?? 0) > 256 * 1024
    if large { Task { await IdleMemoryCleanup.shared.schedule() } }
    viewState.inputEditor.clearLargeUndo(); viewState.secondaryEditor.clearLargeUndo(); viewState.outputEditor.clearLargeUndo()
    viewState.inputEditor.page = EditorPage(); viewState.secondaryEditor.page = EditorPage(); viewState.outputEditor.page = EditorPage()
    checksumURL = nil
    checksumFileSize = 0
    switch presentation.control {
    case .date: input = ToolInput(text: Dates.iso(Date()))
    case .timestamp: input = ToolInput(text: timestampSource == "date" ? Dates.iso(Date()) : "")
    case .color: input = T.example(for: options)
    case .pairs: input = ToolInput(text: "[]")
    case .template: input = ToolInput(text: "{}")
    default: input = ToolInput()
    }
    output = nil
    secondaryDrafts.removeAll()
    importFailure = nil
    error = nil
    status = ""
    elapsed = 0
    refreshLayout()
  }
  func chooseFile(secondary: Bool = false) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    if presentation.isImage { panel.allowedContentTypes = [.image] }
    else if inputStyle != .file && !presentation.acceptsBinary { panel.allowedContentTypes = [.text, .json, .xml, .sourceCode] }
    present(panel) { [weak self] response in
      if response == .OK, let url = panel.url { self?.loadFile(url, secondary: secondary) }
    }
  }
  func loadFile(_ url: URL, secondary: Bool = false) {
    if metadata.id == "file-checksum" && !secondary {
      invalidate()
      let version = revision
      Task { @MainActor in
        do {
          let size = try await Task.detached {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let info = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            try require(info.isRegularFile == true, "请选择普通文件。")
            return Int64(info.fileSize ?? 0)
          }.value
          guard version == revision else { return }
          checksumURL = url
          checksumFileSize = size
          input = ToolInput(file: Data(), fileName: url.lastPathComponent)
          refreshLayout()
        } catch {
          guard version == revision else { return }
          importFailure = "文件未替换：" + error.localizedDescription
          self.error = importFailure
        }
      }
      return
    }
    invalidate()
    status = "读取文件…"
    let version = revision
    Task { @MainActor in
      do {
        let data = try await Task.detached {
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
          try require(size <= Limits.fileBytes, "文件超过 32 MiB。")
          let handle = try FileHandle(forReadingFrom: url)
          defer { try? handle.close() }
          let data = try handle.read(upToCount: Limits.fileBytes + 1) ?? Data()
          try require(data.count <= Limits.fileBytes, "文件超过 32 MiB。")
          return data
        }.value
        guard version == revision else { return }
        if inputStyle == .file && !secondary {
          if presentation.isImage { _ = try ImageCodec.source(ToolInput(file: data)) }
          input = ToolInput(file: data, fileName: url.lastPathComponent)
        } else if let text = String(data: data, encoding: .utf8), data.count <= Limits.textBytes {
          if secondary { input.secondary = text }
          else { input = ToolInput(text: text, secondary: input.secondary) }
        } else if presentation.acceptsBinary && !secondary {
          input = ToolInput(file: data, fileName: url.lastPathComponent)
        } else { throw ToolFailure("请选择 UTF-8 文本文件，最大 5 MiB。") }
        refreshLayout()
      } catch {
        guard version == revision else { return }
        let message = "未导入“\(url.lastPathComponent)”：\(error.localizedDescription) 当前输入未替换；请重新导入或确认继续使用当前输入。"
        importFailure = message
        self.error = message
        status = "读取失败"
      }
    }
  }
  private func present(_ panel: NSSavePanel, completion: @escaping @MainActor (NSApplication.ModalResponse) -> Void) {
    let log = Logger(subsystem: "app.devkit.macos", category: "FilePanels")
    let tool = metadata.id
    log.debug("present tool=\(tool, privacy: .public)")
    let finished: (NSApplication.ModalResponse) -> Void = { response in
      log.debug("dismiss tool=\(tool, privacy: .public) accepted=\(response == .OK)")
      completion(response)
    }
    if let window = NSApp?.keyWindow { panel.beginSheetModal(for: window, completionHandler: finished) }
    else { panel.begin(completionHandler: finished) }
  }
  func save(_ artifact: Artifact) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = artifact.name
    panel.canCreateDirectories = true
    present(panel) { [weak self] response in
      guard response == .OK, let url = panel.url else { return }
      self?.status = "正在导出…"
      Task { @MainActor in
        do {
          try await Task.detached(priority: .utility) {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            try autoreleasepool { try artifact.data.write(to: url, options: .atomic) }
          }.value
          self?.status = "已导出 \(url.lastPathComponent)"
        } catch { self?.error = error.localizedDescription }
      }
    }
  }
  func saveAllArtifacts() {
    guard current, let artifacts = output?.artifacts, !artifacts.isEmpty else { return }
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    panel.prompt = "导出全部"
    let folderName = "DevKit-\(metadata.id)-\(UUID().uuidString.prefix(8))"
    present(panel) { [weak self] response in
      guard response == .OK, let destination = panel.url else { return }
      self?.status = "正在导出…"
      Task { @MainActor in
        do {
          try await Task.detached(priority: .utility) {
            let access = destination.startAccessingSecurityScopedResource()
            defer { if access { destination.stopAccessingSecurityScopedResource() } }
            let folder = destination.appendingPathComponent(folderName, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            for artifact in artifacts {
              let name = URL(fileURLWithPath: artifact.name).lastPathComponent
              try artifact.data.write(to: folder.appendingPathComponent(name), options: .atomic)
            }
          }.value
          self?.status = "已导出 \(artifacts.count) 个文件到 \(folderName)"
        } catch { self?.error = error.localizedDescription }
      }
    }
  }
}
