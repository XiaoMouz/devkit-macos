import Foundation

public enum FaviconTool: ToolModule {
  public typealias Options = EmptyOptions
  public static let metadata = ToolMetadata(
    "favicon", "Favicon", .assets, "Generate common PNG sizes and ICO files from an image without overwriting the original.", sample: "", secondary: "",
    input: .file, network: false)
  public static var fields: [OptionField<Options>] {
    [

    ]
  }
  public static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput {
    let image = try ImageCodec.decode(input)
    var files = try [16, 32, 48, 180, 192, 512].map { size in
      try ImageCodec.encode(
        ImageCodec.resize(image, width: size, height: size), name: "icon-\(size)")
    }
    var ico = Data([0, 0, 1, 0, 3, 0])
    var offset = 6 + 16 * 3
    for (index, size) in [16, 32, 48].enumerated() {
      ico.append(contentsOf: [UInt8(size), UInt8(size), 0, 0, 1, 0, 32, 0])
      for value in [files[index].data.count, offset] {
        ico.append(contentsOf: (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) })
      }
      offset += files[index].data.count
    }
    for file in files.prefix(3) { ico.append(file.data) }
    files.append(Artifact("favicon.ico", "image/x-icon", ico))
    let html =
      "<link rel=\"icon\" href=\"/favicon.ico\">\n<link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/icon-180.png\">\n<link rel=\"icon\" type=\"image/png\" sizes=\"192x192\" href=\"/icon-192.png\">"
    return ToolOutput(html, artifacts: files, note: L10n.tr("The ICO contains 16, 32, and 48 px PNG images. Save each file using the export menu."))
  }
}
