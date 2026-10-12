import Foundation

public struct CommandResult: Sendable {
  public let stdout: Data
  public let stderr: Data
  public let exitCode: Int32
}

public enum DevKitCommandLine {
  public static var help: String { L10n.tr("""
    DevKit CLI — Local developer tools

    devkit list [--format human|json]
    devkit describe <tool-id> [--option key=value ...] [--format human|json]
    devkit run <tool-id> [flags]
    devkit run --request <path|-> [--format human|json|text] [--allow-network]

    Run options:
      --text <text>             UTF-8 text; otherwise read a pipe (empty input in a terminal)
      --input-file <path>       UTF-8 text file
      --file <path>             Binary file, up to 32 MiB
      --secondary <text>        Second text (diff, Schema, HTTP body, etc.)
      --secondary-file <path>   Read the second text from a UTF-8 file
      --option <key=value>      Repeatable; booleans are true/false
      --options-file <path>     JSON options; may be combined with distinct --option values
      --request <path|->        JSON: {"id":"base64","input":{"text":"hello"},"options":{}}
      --format <human|json|text>
                               Formatted by default; json for AI/scripts; text for exact output
      --allow-network           Allow the selected network tool to send requests

    Success goes to stdout; errors go to stderr. --format json applies to both.
    Exit codes: 0 success, 1 execution failure, 2 argument/input error, 124 timeout.
    text is only for run and adds no newline. JSON output.artifacts contains Base64 attachments.
    Use stdin, --request -, or files for content and secrets to keep them out of process arguments.
    --help / help shows this help. Generators default to empty input and never load examples automatically.
    """) }

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
        guard parsed.id == nil else { throw usage(L10n.tr("list does not accept a tool ID.")) }
        if parsed.flags["--format"] != "json" { return plain(CommandPresentation.list()) }
        return try json(["protocolVersion": CommandCatalog.protocolVersion, "tools": CommandCatalog.list()])
      }
      guard ["describe", "run"].contains(command) else { throw usage(L10n.tr("Unknown command. See devkit --help.")) }
      let parsed = try Arguments(Array(arguments.dropFirst()), command: command)
      if command == "describe" {
        guard let id = parsed.id else { throw usage(L10n.tr("A tool ID is required.")) }
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
        else { throw usage(L10n.tr("--request cannot be combined with a tool ID or other input options.")) }
        if source == "-", isInputTerminal { throw usage(L10n.tr("--request - requires JSON from a pipe.")) }
        let data = try source == "-" ? readInput() : readFile(source, limit: requestLimit)
        guard data.count <= requestLimit else { throw usage(L10n.tr("Request exceeds 60 MiB.")) }
        let object = try object(data)
        guard Set(object.keys).isSubset(of: ["id", "input", "options"]), let id = object["id"] as? String else {
          throw usage(L10n.tr("The request requires id and only supports id, input, and options fields."))
        }
        let inputObject = try dictionary(object["input"] ?? [:], name: "input")
        guard Set(inputObject.keys).isSubset(of: ["text", "secondary", "file", "fileName"]) else {
          throw usage(L10n.tr("input contains unknown fields."))
        }
        var filled = inputObject
        if filled["text"] == nil { filled["text"] = "" }
        if filled["secondary"] == nil { filled["secondary"] = "" }
        let input = try JSONDecoder().decode(ToolInput.self, from: JSONSerialization.data(withJSONObject: filled))
        request = try CommandCatalog.request(id, input: input,
          options: dictionary(object["options"] ?? [:], name: "options"))
      } else {
        guard let id = parsed.id else { throw usage(L10n.tr("A tool ID or --request is required.")) }
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
          guard data.count <= Limits.textBytes else { throw usage(L10n.tr("Text exceeds 5 MiB.")) }
          input.text = try text(data)
        }
        if let text = parsed.flags["--secondary"] { input.secondary = text }
        else if let path = parsed.flags["--secondary-file"] { input.secondary = try readText(path) }
        request = try CommandCatalog.request(id, input: input, options: options)
      }
      if ToolRegistry.find(request.id)?.metadata.network == true, parsed.flags["--allow-network"] == nil {
        throw usage(L10n.tr("This tool sends network requests and requires --allow-network."))
      }
      let output: ToolOutput
      do { output = try await execute(request) }
      catch let failure as ToolFailure { throw failure }
      catch { throw ToolFailure(L10n.tr("Tool execution failed: \(error.localizedDescription)"), code: "internal") }
      if parsed.flags["--format"] == "text" { return plain(output.text) }
      if parsed.flags["--format"] != "json" { return plain(CommandPresentation.output(output)) }
      return try json(["protocolVersion": CommandCatalog.protocolVersion, "id": request.id,
        "output": JSONSerialization.jsonObject(with: JSONEncoder().encode(output))])
    } catch let failure as ToolFailure {
      return error(failure, json: jsonErrors)
    } catch is DecodingError {
      return error(usage(L10n.tr("Invalid JSON field type. Input text must be a string; file must be Base64.")), json: jsonErrors)
    } catch {
      return Self.error(usage(L10n.tr("Could not read input or parse JSON: \(error.localizedDescription)")), json: jsonErrors)
    }
  }

  public static let requestLimit = 60 * 1024 * 1024

  /// Bounded reading also covers streams without allocating an unbounded Data first.
  public static func read(_ handle: FileHandle, limit: Int) throws -> Data {
    var data = Data()
    while let part = try handle.read(upToCount: min(65_536, limit - data.count + 1)), !part.isEmpty {
      data.append(part)
      guard data.count <= limit else { throw usage(L10n.tr("Input exceeds the size limit.")) }
    }
    return data
  }

  private static func readFile(_ path: String, limit: Int) throws -> Data {
    let url = URL(fileURLWithPath: path)
    guard try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
      throw usage(L10n.tr("The input path must be a regular file."))
    }
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    return try read(handle, limit: limit)
  }

  private static func readText(_ path: String) throws -> String {
    try text(readFile(path, limit: Limits.textBytes))
  }
  private static func text(_ data: Data) throws -> String {
    guard let value = String(data: data, encoding: .utf8) else { throw usage(L10n.tr("Text input must be valid UTF-8.")) }
    return value
  }
  private static func object(_ data: Data) throws -> [String: Any] {
    try dictionary(JSONSerialization.jsonObject(with: data), name: "JSON")
  }
  private static func dictionary(_ value: Any, name: String) throws -> [String: Any] {
    guard let object = value as? [String: Any] else { throw usage(L10n.tr("\(name) must be a JSON object.")) }
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
      : Data(L10n.tr("Error: \(failure.message)\n").utf8)
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
        guard allowed.contains(flag) else { throw usage(L10n.tr("Unknown option: \(flag)")) }
        if flag == "--allow-network" {
          guard flags[flag] == nil else { throw usage(L10n.tr("Duplicate option: \(flag)")) }
          flags[flag] = "true"; continue
        }
        guard index < arguments.count else { throw usage(L10n.tr("Missing option value: \(flag)")) }
        let value = arguments[index]; index += 1
        if flag == "--option" {
          guard let separator = value.firstIndex(of: "="), separator != value.startIndex else {
            throw usage(L10n.tr("--option requires key=value."))
          }
          let key = String(value[..<separator])
          guard assignments[key] == nil else { throw usage(L10n.tr("Duplicate option: \(key)")) }
          assignments[key] = String(value[value.index(after: separator)...])
        } else {
          guard flags[flag] == nil else { throw usage(L10n.tr("Duplicate option: \(flag)")) }
          flags[flag] = value
        }
      }
      for group in [["--text", "--input-file", "--file"], ["--secondary", "--secondary-file"]] {
        guard group.filter({ flags[$0] != nil }).count <= 1 else { throw usage(L10n.tr("Only one input source can be specified.")) }
      }
      let formats = command == "run" ? ["human", "json", "text"] : ["human", "json"]
      if let format = flags["--format"], !formats.contains(format) {
        throw usage(L10n.tr("format must be \(formats.joined(separator: "、"))."))
      }
    }

    func options(id: String) throws -> [String: Any] {
      var values = try flags["--options-file"].map { try object(readFile($0, limit: Limits.textBytes)) } ?? [:]
      for (key, value) in assignments {
        guard values[key] == nil else { throw usage(L10n.tr("Duplicate option: \(key)")) }
        values[key] = try CommandCatalog.option(value, id: id, key: key)
      }
      return values
    }
  }
}
