import Foundation
import UniformTypeIdentifiers

public enum MimeTypesTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "mime-types", "MIME 类型", .web, "通过系统 Uniform Type 数据库查询扩展名或 MIME。", sample: "json",
    secondary: "", input: .text, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let text = input.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let type =
      text.contains("/")
      ? UTType(mimeType: text)
      : UTType(filenameExtension: text.hasPrefix(".") ? String(text.dropFirst()) : text)
    guard let type else { throw ToolFailure("系统类型库中未找到此扩展名或 MIME。") }
    let rows = [
      ResultRow("MIME", type.preferredMIMEType ?? "未知"),
      ResultRow("扩展名", type.preferredFilenameExtension ?? "未知"),
      ResultRow("UTType", type.identifier), ResultRow("说明", type.localizedDescription ?? ""),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
