import AppKit
import DevKitCore
import SwiftUI

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
  var options = T.Options() { didSet { invalidate() } }
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
  var current: Bool { output != nil && resultRevision == revision && !bridge.running }
  var recommendedDisplay: String {
    guard let output else { return "text" }
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
    bridge.runAction = { [weak self] in self?.run() }
    bridge.copyAction = { [weak self] in self?.copyResult() }
  }
  func refreshLayout() {
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
    copied = Clipboard.copy(output.text)
    status = copied ? "已复制完整结果" : "复制失败，请重试"
  }
  func useExample() {
    input = ToolInput(text: metadata.sample, secondary: metadata.secondary)
    refreshLayout()
  }
  func paste() {
    if let value = NSPasteboard.general.string(forType: .string) {
      input = ToolInput(text: value, secondary: input.secondary)
      refreshLayout()
    }
  }
  func clearInput() {
    input = ToolInput()
    refreshLayout()
  }
  func chooseFile() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.begin { [weak self] response in
      if response == .OK, let url = panel.url { self?.loadFile(url) }
    }
  }
  func loadFile(_ url: URL) {
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
        if metadata.inputStyle != .file, let text = String(data: data, encoding: .utf8),
          data.count <= Limits.textBytes
        {
          input = ToolInput(text: text, secondary: input.secondary)
        } else {
          input = ToolInput(file: data, fileName: url.lastPathComponent)
        }
        refreshLayout()
      } catch {
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
