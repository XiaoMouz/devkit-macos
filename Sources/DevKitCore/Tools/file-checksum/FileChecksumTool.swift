import Foundation

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
    let expected = options.expected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return ToolOutput(
      hash,
      note: expected.isEmpty
        ? "\(input.fileName ?? "文件") · \(data.count) 字节" : (hash == expected ? "校验一致" : "校验不一致"))
  }
}
