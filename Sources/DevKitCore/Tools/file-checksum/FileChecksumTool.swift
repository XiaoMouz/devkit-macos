import Foundation
import CryptoKit

public enum FileChecksumTool: ToolModule {
  public struct Options: ToolOptions {
    public var algorithm: String = "SHA-256"
    public var expected: String = ""
    public init() {}
  }
  public static let metadata = ToolMetadata(
    "file-checksum", "File Checksum", .security, "Calculate a file digest and compare it with an expected value. Supports cancellation.", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [
      .init("algorithm", L10n.tr("Algorithm"), \.algorithm, choices: ["MD5", "SHA-1", "SHA-256", "SHA-512"]),
      .init("expected", L10n.tr("Expected Digest (Optional)"), \.expected),
    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    guard let data = input.file else { throw ToolFailure(L10n.tr("Choose a file.")) }
    let hash = Digest.compute(data, algorithm: options.algorithm)
    return output(hash, size: Int64(data.count), name: input.fileName ?? L10n.tr("File"), options: options)
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
      try require(initial.isRegularFile == true, L10n.tr("Choose a regular file."))
      let total = Int64(initial.fileSize ?? 0)
      let result: (String, Int64)
      switch options.algorithm {
      case "MD5": result = try read(url, hasher: Insecure.MD5(), total: total, progress: progress)
      case "SHA-1": result = try read(url, hasher: Insecure.SHA1(), total: total, progress: progress)
      case "SHA-256": result = try read(url, hasher: SHA256(), total: total, progress: progress)
      case "SHA-512": result = try read(url, hasher: SHA512(), total: total, progress: progress)
      default: throw ToolFailure(L10n.tr("Invalid digest algorithm."))
      }
      inspectedURL.removeAllCachedResourceValues()
      let final = try inspectedURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
      try require(result.1 == total && initial.fileSize == final.fileSize
        && initial.contentModificationDate == final.contentModificationDate,
        L10n.tr("The file changed while being read. Select it again and recalculate."))
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
      rows: expected.isEmpty ? [] : [ResultRow(L10n.tr("Expected Digest"), expected), ResultRow(L10n.tr("Actual Digest"), hash)],
      html: expected.isEmpty ? nil : ComparisonPreview.documents([
        (L10n.tr("Expected Digest"), [(text: expected, kind: same ? "" : "remove")]),
        (L10n.tr("Actual Digest"), [(text: hash, kind: same ? "" : "add")]),
      ]),
      note: expected.isEmpty
        ? L10n.tr("\(name) · \(size) bytes") : (same ? L10n.tr("Checksum Matches") : L10n.tr("Checksum Does Not Match")),
      report: expected.isEmpty ? nil : ResultReport(same ? "success" : "failure", same ? L10n.tr("File Checksum Passed") : L10n.tr("File Digest Does Not Match"),
        same ? L10n.tr("The calculated digest exactly matches the expected value.") : L10n.tr("The actual digest differs from the expected value. Check the file or expected digest."),
        metrics: [ResultRow(L10n.tr("Algorithm"), options.algorithm), ResultRow(L10n.tr("File Size"), ByteCountFormatter.string(fromByteCount: size, countStyle: .file))]))
  }
}
