import AppKit
import DevKitCore
import SwiftUI
import UniformTypeIdentifiers

/// All presentations of a tool share this in-memory session, never copies of its text.
@MainActor @Observable final class ToolSession<T: ToolModule> {
  let id: UUID
  let bridge: WorkspaceBridge
  var input = ToolInput() {
    didSet {
      guard
        input.text != oldValue.text || input.secondary != oldValue.secondary
          || input.file != oldValue.file || input.fileName != oldValue.fileName
      else { return }
      invalidate()
    }
  }
  var options = T.Options() {
    didSet {
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
  var status = ""
  var copied = false
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
    if presentation.isForm || presentation.isImage || metadata.id == "qr-code" {
      layoutPolicy.evaluate(texts: [])
      return
    }
    layoutPolicy.evaluate(
      texts: [input.text, input.secondary, current ? output?.text ?? "" : ""],
      fileBytes: input.file?.count ?? 0)
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
    do {
      try Limits.check(input)
      let request = WorkerRequest(
        id: metadata.id, input: input, options: try JSONEncoder().encode(options))
      let version = revision
      bridge.running = true
      error = nil
      copied = false
      status = "处理中…"
      task = Task { @MainActor in
        let start = Date()
        do {
          let result = try await execute(request)
          guard !Task.isCancelled && version == revision else { return }
          output = result
          resultRevision = version
          elapsed = Date().timeIntervalSince(start)
          bridge.running = false
          status = "已完成"
          completedRun += 1
          refreshLayout()
        } catch {
          guard !Task.isCancelled && version == revision else { return }
          self.error = error.localizedDescription
          resultRevision = -1
          bridge.running = false
          status = "需要检查输入"
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
      input = ToolInput(text: value, secondary: input.secondary)
      refreshLayout()
    }
  }
  func clearInput() {
    switch presentation.control {
    case .date: input = ToolInput(text: Dates.iso(Date()))
    case .color: input = T.example(for: options)
    case .pairs: input = ToolInput(text: "[]")
    case .template: input = ToolInput(text: "{}")
    default: input = ToolInput()
    }
    output = nil
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
    panel.begin { [weak self] response in
      if response == .OK, let url = panel.url { self?.loadFile(url, secondary: secondary) }
    }
  }
  func loadFile(_ url: URL, secondary: Bool = false) {
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
        self.error = error.localizedDescription
        status = "读取失败"
      }
    }
  }
  func save(_ artifact: Artifact) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = artifact.name
    panel.canCreateDirectories = true
    panel.begin { [weak self] response in
      guard response == .OK, let url = panel.url else { return }
      do {
        try artifact.data.write(to: url, options: .atomic)
        self?.status = "已导出 \(url.lastPathComponent)"
      } catch { self?.error = error.localizedDescription }
    }
  }
}
