import Foundation

public struct CommandResult: Sendable {
  public let stdout: Data
  public let stderr: Data
  public let exitCode: Int32
}

public enum DevKitCommandLine {
  public static let help = """
    DevKit CLI — 本机开发工具

    devkit list [--format human|json]
    devkit describe <tool-id> [--option key=value ...] [--format human|json]
    devkit run <tool-id> [flags]
    devkit run --request <path|-> [--format human|json|text] [--allow-network]

    执行选项：
      --text <text>             UTF-8 原文；未指定输入时从管道读取（终端为空输入）
      --input-file <path>       UTF-8 文本文件
      --file <path>             二进制文件，最多 32 MiB
      --secondary <text>        第二份文本（对比、Schema、HTTP 正文等）
      --secondary-file <path>   从 UTF-8 文件读取第二份文本
      --option <key=value>      可重复；布尔值为 true/false
      --options-file <path>     JSON 参数对象；可与不重复的 --option 合用
      --request <path|->        JSON: {"id":"base64","input":{"text":"hello"},"options":{}}
      --format <human|json|text>
                               默认排版显示；json 用于 AI / 脚本；text 输出精确原文
      --allow-network           允许所选联网工具发送请求

    成功结果写 stdout，错误写 stderr。--format json 对结果和错误都生效。
    退出码：0 成功，1 执行失败，2 参数/输入错误，124 超时。
    text 仅用于 run，不补换行。附件在 JSON 的 output.artifacts 中以 Base64 返回。
    正文和密钥建议使用 stdin、--request - 或文件，避免进入进程参数。
    --help / help 显示此说明。生成器默认空输入，不会自动填充示例。
    """

  public static func run(arguments: [String], isInputTerminal: Bool,
    readInput: @Sendable () throws -> Data,
    execute: @Sendable (WorkerRequest) async throws -> ToolOutput
  ) async -> CommandResult {
    let jsonErrors = requestedJSON(arguments)
    do {
      guard let command = arguments.first else { return plain(help + "\n") }
      if ["--help", "help", "-h"].contains(command), arguments.count == 1 { return plain(help + "\n") }
      if arguments.count == 2, ["list", "describe", "run"].contains(command), arguments[1] == "--help" {
        return plain(help + "\n")
      }
      if command == "list" {
        let parsed = try Arguments(Array(arguments.dropFirst()), command: command)
        guard parsed.id == nil else { throw usage("list 不接受工具 ID。") }
        if parsed.flags["--format"] != "json" { return plain(CommandPresentation.list()) }
        return try json(["protocolVersion": CommandCatalog.protocolVersion, "tools": CommandCatalog.list()])
      }
      guard ["describe", "run"].contains(command) else { throw usage("未知命令；请用 devkit --help 查看。") }
      let parsed = try Arguments(Array(arguments.dropFirst()), command: command)
      if command == "describe" {
        guard let id = parsed.id else { throw usage("需要工具 ID。") }
        let options = try parsed.options(id: id)
        let description = try CommandCatalog.describe(id, options: options)
        if parsed.flags["--format"] != "json" { return plain(CommandPresentation.describe(description)) }
        return try json(["protocolVersion": CommandCatalog.protocolVersion,
          "tool": description])
      }
      let request: WorkerRequest
      if let source = parsed.flags["--request"] {
        guard parsed.id == nil, parsed.assignments.isEmpty,
          Set(parsed.flags.keys).isSubset(of: ["--request", "--format", "--allow-network"])
        else { throw usage("--request 不能与工具 ID 或其他输入参数混用。") }
        if source == "-", isInputTerminal { throw usage("--request - 需要通过管道提供 JSON。") }
        let data = try source == "-" ? readInput() : readFile(source, limit: requestLimit)
        guard data.count <= requestLimit else { throw usage("请求超过 60 MiB。") }
        let object = try object(data)
        guard Set(object.keys).isSubset(of: ["id", "input", "options"]), let id = object["id"] as? String else {
          throw usage("请求需要 id，仅支持 id、input、options 字段。")
        }
        let inputObject = try dictionary(object["input"] ?? [:], name: "input")
        guard Set(inputObject.keys).isSubset(of: ["text", "secondary", "file", "fileName"]) else {
          throw usage("input 包含未知字段。")
        }
        var filled = inputObject
        if filled["text"] == nil { filled["text"] = "" }
        if filled["secondary"] == nil { filled["secondary"] = "" }
        let input = try JSONDecoder().decode(ToolInput.self, from: JSONSerialization.data(withJSONObject: filled))
        request = try CommandCatalog.request(id, input: input,
          options: dictionary(object["options"] ?? [:], name: "options"))
      } else {
        guard let id = parsed.id else { throw usage("需要工具 ID 或 --request。") }
        // Validate options before reading a potentially blocking stdin.
        let options = try parsed.options(id: id)
        _ = try CommandCatalog.describe(id, options: options)
        var input = ToolInput()
        if let text = parsed.flags["--text"] { input.text = text }
        else if let path = parsed.flags["--input-file"] { input.text = try readText(path) }
        else if let path = parsed.flags["--file"] {
          input.file = try readFile(path, limit: Limits.fileBytes)
          input.fileName = URL(fileURLWithPath: path).lastPathComponent
        } else if !isInputTerminal {
          let data = try readInput()
          guard data.count <= Limits.textBytes else { throw usage("文本超过 5 MiB。") }
          input.text = try text(data)
        }
        if let text = parsed.flags["--secondary"] { input.secondary = text }
        else if let path = parsed.flags["--secondary-file"] { input.secondary = try readText(path) }
        request = try CommandCatalog.request(id, input: input, options: options)
      }
      if ToolRegistry.find(request.id)?.metadata.network == true, parsed.flags["--allow-network"] == nil {
        throw usage("此工具会发送网络请求；需要 --allow-network。")
      }
      let output: ToolOutput
      do { output = try await execute(request) }
      catch let failure as ToolFailure { throw failure }
      catch { throw ToolFailure("工具执行失败：\(error.localizedDescription)", code: "internal") }
      if parsed.flags["--format"] == "text" { return plain(output.text) }
      if parsed.flags["--format"] != "json" { return plain(CommandPresentation.output(output)) }
      return try json(["protocolVersion": CommandCatalog.protocolVersion, "id": request.id,
        "output": JSONSerialization.jsonObject(with: JSONEncoder().encode(output))])
    } catch let failure as ToolFailure {
      return error(failure, json: jsonErrors)
    } catch is DecodingError {
      return error(usage("JSON 字段类型无效；input 文本必须是字符串，file 必须是 Base64。"), json: jsonErrors)
    } catch {
      return Self.error(usage("无法读取输入或解析 JSON：\(error.localizedDescription)"), json: jsonErrors)
    }
  }

  public static let requestLimit = 60 * 1024 * 1024

  /// Bounded reading also covers streams without allocating an unbounded Data first.
  public static func read(_ handle: FileHandle, limit: Int) throws -> Data {
    var data = Data()
    while let part = try handle.read(upToCount: min(65_536, limit - data.count + 1)), !part.isEmpty {
      data.append(part)
      guard data.count <= limit else { throw usage("输入超过大小限制。") }
    }
    return data
  }

  private static func readFile(_ path: String, limit: Int) throws -> Data {
    let url = URL(fileURLWithPath: path)
    guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
      throw usage("输入路径必须是普通文件。")
    }
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    return try read(handle, limit: limit)
  }

  private static func readText(_ path: String) throws -> String {
    try text(readFile(path, limit: Limits.textBytes))
  }
  private static func text(_ data: Data) throws -> String {
    guard let value = String(data: data, encoding: .utf8) else { throw usage("文本输入必须是有效的 UTF-8。") }
    return value
  }
  private static func object(_ data: Data) throws -> [String: Any] {
    try dictionary(JSONSerialization.jsonObject(with: data), name: "JSON")
  }
  private static func dictionary(_ value: Any, name: String) throws -> [String: Any] {
    guard let object = value as? [String: Any] else { throw usage("\(name) 必须是 JSON 对象。") }
    return object
  }
  private static func json(_ object: [String: Any]) throws -> CommandResult {
    var bytes = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
    bytes.append(10)
    return CommandResult(stdout: bytes, stderr: Data(), exitCode: 0)
  }
  private static func plain(_ text: String) -> CommandResult {
    CommandResult(stdout: Data(text.utf8), stderr: Data(), exitCode: 0)
  }
  private static func usage(_ message: String) -> ToolFailure { ToolFailure(message, code: "usage") }
  private static func error(_ failure: ToolFailure, json: Bool) -> CommandResult {
    let data = json
      ? (try? Self.json(["protocolVersion": CommandCatalog.protocolVersion,
        "error": ["code": failure.code, "message": failure.message]]).stdout) ?? Data()
      : Data("错误：\(failure.message)\n".utf8)
    return CommandResult(stdout: Data(), stderr: data,
      exitCode: failure.code == "timeout" ? 124 : (["usage", "limit"].contains(failure.code) ? 2 : 1))
  }

  /// Recognize the requested error format even when validation fails. Skip flag values
  /// so user text containing `--format` never changes how errors are presented.
  private static func requestedJSON(_ arguments: [String]) -> Bool {
    var index = 1
    var result = false
    while index < arguments.count {
      let flag = arguments[index]
      if flag.hasPrefix("--"), flag != "--allow-network", index + 1 < arguments.count {
        if flag == "--format" { result = arguments[index + 1] == "json" }
        index += 2
      } else { index += 1 }
    }
    return result
  }

  private struct Arguments {
    var id: String?
    var flags = [String: String]()
    var assignments = [String: String]()

    init(_ arguments: [String], command: String) throws {
      var index = 0
      if let first = arguments.first, !first.hasPrefix("--") { id = first; index = 1 }
      let allowed: Set<String>
      switch command {
      case "list": allowed = ["--format"]
      case "describe": allowed = ["--option", "--format"]
      default: allowed = ["--text", "--input-file", "--file", "--secondary", "--secondary-file",
        "--option", "--options-file", "--request", "--format", "--allow-network"]
      }
      while index < arguments.count {
        let flag = arguments[index]; index += 1
        guard allowed.contains(flag) else { throw usage("未知参数：\(flag)") }
        if flag == "--allow-network" {
          guard flags[flag] == nil else { throw usage("参数重复：\(flag)") }
          flags[flag] = "true"; continue
        }
        guard index < arguments.count else { throw usage("参数缺少值：\(flag)") }
        let value = arguments[index]; index += 1
        if flag == "--option" {
          guard let separator = value.firstIndex(of: "="), separator != value.startIndex else {
            throw usage("--option 需要 key=value。")
          }
          let key = String(value[..<separator])
          guard assignments[key] == nil else { throw usage("参数重复：\(key)") }
          assignments[key] = String(value[value.index(after: separator)...])
        } else {
          guard flags[flag] == nil else { throw usage("参数重复：\(flag)") }
          flags[flag] = value
        }
      }
      for group in [["--text", "--input-file", "--file"], ["--secondary", "--secondary-file"]] {
        guard group.filter({ flags[$0] != nil }).count <= 1 else { throw usage("不能同时指定多种输入来源。") }
      }
      let formats = command == "run" ? ["human", "json", "text"] : ["human", "json"]
      if let format = flags["--format"], !formats.contains(format) {
        throw usage("format 必须是 \(formats.joined(separator: "、"))。")
      }
    }

    func options(id: String) throws -> [String: Any] {
      var values = try flags["--options-file"].map { try object(readFile($0, limit: Limits.textBytes)) } ?? [:]
      for (key, value) in assignments {
        guard values[key] == nil else { throw usage("参数重复：\(key)") }
        values[key] = try CommandCatalog.option(value, id: id, key: key)
      }
      return values
    }
  }
}
