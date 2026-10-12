import Foundation
import UniformTypeIdentifiers

public enum MimeTypesTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "mime-types", "MIME Types", .web, "Look up file extensions and MIME types using the system Uniform Type database.", sample: "json",
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
    guard let type else { throw ToolFailure(L10n.tr("The extension or MIME type was not found in the system type database.")) }
    let rows = [
      ResultRow("MIME", type.preferredMIMEType ?? L10n.tr("Unknown")),
      ResultRow(L10n.tr("Extension"), type.preferredFilenameExtension ?? L10n.tr("Unknown")),
      ResultRow("UTType", type.identifier), ResultRow(L10n.tr("Description"), type.localizedDescription ?? ""),
    ]
    return ToolOutput(rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n"), rows: rows)
  }
}
