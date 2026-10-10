import Foundation

public enum ToolCategory: String, CaseIterable, Codable, Sendable {
  case encoding = "编码与转换"
  case structured = "结构化数据"
  case security = "摘要与令牌"
  case generators = "标识与测试数据"
  case text = "文本与匹配"
  case numbers = "时间与数值"
  case web = "Web 与网络"
  case css = "前端样式"
  case assets = "代码与图形"
  public var symbol: String {
    switch self {
    case .encoding: "arrow.left.arrow.right"
    case .structured: "curlybraces"
    case .security: "number.square"
    case .generators: "sparkles"
    case .text: "text.alignleft"
    case .numbers: "clock"
    case .web: "network"
    case .css: "paintpalette"
    case .assets: "photo.on.rectangle.angled"
    }
  }
}

public enum InputStyle: String, Sendable { case text, pair, generator, file }
public struct ToolMetadata: Sendable, Identifiable {
  public let id: String
  public let name: String
  public let category: ToolCategory
  public let summary: String
  public let symbol: String
  public let sample: String
  public let secondary: String
  public let inputStyle: InputStyle
  public let network: Bool
  public init(
    _ id: String, _ name: String, _ category: ToolCategory, _ summary: String,
    symbol: String? = nil, sample: String = "", secondary: String = "",
    input: InputStyle = .text, network: Bool = false
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.summary = summary
    self.symbol = symbol ?? category.symbol
    self.sample = sample
    self.secondary = secondary
    self.inputStyle = input
    self.network = network
  }
}

public enum FieldKind: Sendable {
  case text, secret
  case choice([String])
  case integer(ClosedRange<Int>)
  case decimal
  case toggle
}
/// Key-path based fields keep each module's options strongly typed through the UI.
public struct OptionField<Options>: @unchecked Sendable, Identifiable {
  public let id: String
  public let label: String
  public let kind: FieldKind
  public let read: (Options) -> String
  public let write: (inout Options, String) -> Void
  public init(
    _ id: String, _ label: String, _ path: WritableKeyPath<Options, String>,
    choices: [String]? = nil, secret: Bool = false
  ) {
    self.id = id
    self.label = label
    kind = choices.map(FieldKind.choice) ?? (secret ? .secret : .text)
    read = { $0[keyPath: path] }
    write = { $0[keyPath: path] = $1 }
  }
  public init(
    _ id: String, _ label: String, _ path: WritableKeyPath<Options, Int>, range: ClosedRange<Int>
  ) {
    self.id = id
    self.label = label
    kind = .integer(range)
    read = { String($0[keyPath: path]) }
    write = { if let n = Int($1) { $0[keyPath: path] = n } }
  }
  public init(_ id: String, _ label: String, _ path: WritableKeyPath<Options, Bool>) {
    self.id = id
    self.label = label
    kind = .toggle
    read = { $0[keyPath: path] ? "true" : "false" }
    write = { $0[keyPath: path] = $1 == "true" }
  }
}
public protocol ToolOptions: Codable, Sendable { init() }
public struct EmptyOptions: ToolOptions { public init() {} }
public struct ToolInput: Codable, Sendable {
  public var text: String
  public var secondary: String
  public var file: Data?
  public var fileName: String?
  public init(text: String = "", secondary: String = "", file: Data? = nil, fileName: String? = nil)
  {
    self.text = text
    self.secondary = secondary
    self.file = file
    self.fileName = fileName
  }
  public var bytes: Data { file ?? Data(text.utf8) }
}
public struct ResultRow: Codable, Sendable, Identifiable {
  public var id: String { label + "\u{0}" + value }
  public let label: String
  public let value: String
  public init(_ label: String, _ value: String) {
    self.label = label
    self.value = value
  }
}
public struct Artifact: Codable, Sendable {
  public let name: String
  public let mime: String
  public let data: Data
  public init(_ name: String, _ mime: String, _ data: Data) {
    self.name = name
    self.mime = mime
    self.data = data
  }
}
public struct ToolOutput: Codable, Sendable {
  public var text: String
  public var rows: [ResultRow]
  public var artifacts: [Artifact]
  public var html: String?
  public var note: String?
  public init(
    _ text: String = "", rows: [ResultRow] = [], artifacts: [Artifact] = [], html: String? = nil,
    note: String? = nil
  ) {
    self.text = text
    self.rows = rows
    self.artifacts = artifacts
    self.html = html
    self.note = note
  }
}
public struct ToolFailure: Error, LocalizedError, Codable, Sendable {
  public let code: String
  public let message: String
  public var errorDescription: String? { message }
  public init(_ message: String, code: String = "invalid-input") {
    self.message = message
    self.code = code
  }
}
public protocol ToolModule: Sendable {
  associatedtype Options: ToolOptions
  static var metadata: ToolMetadata { get }
  static var fields: [OptionField<Options>] { get }
  static func inputStyle(for options: Options) -> InputStyle
  static func visibleFields(for options: Options) -> [OptionField<Options>]
  static func example(for options: Options) -> ToolInput
  static func execute(_ input: ToolInput, options: Options) async throws -> ToolOutput
}
extension ToolModule {
  public static var fields: [OptionField<Options>] { [] }
  public static func inputStyle(for options: Options) -> InputStyle { metadata.inputStyle }
  public static func visibleFields(for options: Options) -> [OptionField<Options>] { fields }
  public static func example(for options: Options) -> ToolInput {
    ToolInput(text: metadata.sample, secondary: metadata.secondary)
  }
  public static func executeEncoded(_ input: ToolInput, options: Data) async throws -> ToolOutput {
    try await execute(input, options: JSONDecoder().decode(Options.self, from: options))
  }
}
public struct WorkerRequest: Codable, Sendable {
  public let id: String
  public let input: ToolInput
  public let options: Data
  public init(id: String, input: ToolInput, options: Data) {
    self.id = id
    self.input = input
    self.options = options
  }
}
public struct WorkerResponse: Codable, Sendable {
  public let output: ToolOutput?
  public let error: ToolFailure?
  public init(output: ToolOutput? = nil, error: ToolFailure? = nil) {
    self.output = output
    self.error = error
  }
}

public enum Limits {
  public static let textBytes = 5 * 1024 * 1024
  public static let fileBytes = 32 * 1024 * 1024
  public static let outputBytes = 32 * 1024 * 1024
  public static func check(_ input: ToolInput) throws {
    guard input.text.utf8.count + input.secondary.utf8.count <= textBytes else {
      throw ToolFailure("文本超过 5 MiB，请缩小输入。", code: "limit")
    }
    guard (input.file?.count ?? 0) <= fileBytes else {
      throw ToolFailure("文件超过 32 MiB。", code: "limit")
    }
  }
}
