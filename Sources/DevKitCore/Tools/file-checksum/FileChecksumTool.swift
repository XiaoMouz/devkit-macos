import Foundation
import CryptoKit

public enum FileChecksumTool: ToolModule {
  public struct Options: ToolOptions {
    public var algorithm: String = "SHA-256"
    public var expected: String = ""
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "file-checksum", "文件校验", .security, "计算文件摘要，并与期望值比较；支持取消。", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("algorithm", "算法", \.algorithm, choices: ["MD5", "SHA-1", "SHA-256", "SHA-512"]),
      .init("expected", "期望摘要（可选）", \.expected),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let data = input.file else { throw ToolFailure("请选择文件。") }
    let hash = Digest.compute(data, algorithm: options.algorithm)
    return output(hash, size: Int64(data.count), name: input.fileName ?? "文件", options: options)
  }

  /// The UI uses this path for selected files, so large files never enter the
  /// worker's JSON envelope or a full-size in-memory Data allocation.
  public static func stream(_ url: URL, options: Options,
    progress: @escaping @Sendable (Int64, Int64) -> Void = { _, _ in }) async throws -> ToolOutput {
    let work = Task.detached(priority: .userInitiated) {
      let access = url.startAccessingSecurityScopedResource()
      defer { if access { url.stopAccessingSecurityScopedResource() } }
      var inspectedURL = url
      inspectedURL.removeAllCachedResourceValues()
      let initial = try inspectedURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
      try require(initial.isRegularFile == true, "请选择普通文件。")
      let total = Int64(initial.fileSize ?? 0)
      let result: (String, Int64)
      switch options.algorithm {
      case "MD5": result = try read(url, hasher: Insecure.MD5(), total: total, progress: progress)
      case "SHA-1": result = try read(url, hasher: Insecure.SHA1(), total: total, progress: progress)
      case "SHA-256": result = try read(url, hasher: SHA256(), total: total, progress: progress)
      case "SHA-512": result = try read(url, hasher: SHA512(), total: total, progress: progress)
      default: throw ToolFailure("摘要算法无效。")
      }
      inspectedURL.removeAllCachedResourceValues()
      let final = try inspectedURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
      try require(result.1 == total && initial.fileSize == final.fileSize
        && initial.contentModificationDate == final.contentModificationDate,
        "读取期间文件发生变化，请重新选择并计算。")
      return output(result.0, size: result.1, name: url.lastPathComponent, options: options)
    }
    return try await withTaskCancellationHandler { try await work.value } onCancel: { work.cancel() }
  }
  private static func read<H: HashFunction>(_ url: URL, hasher: H, total: Int64,
    progress: @Sendable (Int64, Int64) -> Void) throws -> (String, Int64) {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = hasher
    var count: Int64 = 0
    var lastUpdate = Date.distantPast
    while true {
      try Task.checkCancellation()
      let bytes = try autoreleasepool { try handle.read(upToCount: 1024 * 1024) ?? Data() }
      if bytes.isEmpty { break }
      hasher.update(data: bytes)
      count += Int64(bytes.count)
      if Date().timeIntervalSince(lastUpdate) >= 0.1 { progress(count, total); lastUpdate = Date() }
    }
    progress(count, total)
    return (hex(hasher.finalize()), count)
  }
  private static func output(_ hash: String, size: Int64, name: String, options: Options) -> ToolOutput {
    let expected = options.expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let same = hash == expected
    return ToolOutput(
      hash,
      rows: expected.isEmpty ? [] : [ResultRow("期望摘要", expected), ResultRow("实际摘要", hash)],
      html: expected.isEmpty ? nil : ComparisonPreview.documents([
        ("期望摘要", [(text: expected, kind: same ? "" : "remove")]),
        ("实际摘要", [(text: hash, kind: same ? "" : "add")]),
      ]),
      note: expected.isEmpty
        ? "\(name) · \(size) 字节" : (same ? "校验一致" : "校验不一致"),
      report: expected.isEmpty ? nil : ResultReport(same ? "success" : "failure", same ? "文件校验通过" : "文件摘要不一致",
        same ? "计算摘要与期望值完全匹配。" : "实际摘要与期望值不同，请检查文件或期望摘要。",
        metrics: [ResultRow("算法", options.algorithm), ResultRow("文件大小", ByteCountFormatter.string(fromByteCount: size, countStyle: .file))]))
  }
}
