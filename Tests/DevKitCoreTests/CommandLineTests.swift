import Foundation
import Testing
@testable import DevKitCore

@Suite("CLI and AI integration") struct CommandLineTests {
  private func run(_ args: [String], stdin: String? = nil) async -> CommandResult {
    await DevKitCommandLine.run(arguments: args, isInputTerminal: stdin == nil,
      readInput: { Data((stdin ?? "").utf8) }, execute: { request in
        guard let tool = ToolRegistry.find(request.id) else { throw ToolFailure("missing") }
        return try await tool.executeEncoded(request.input, options: request.options)
      })
  }

  @Test func discoveryCoversRegistryAndDefaults() throws {
    #expect(CommandCatalog.list().count == ToolRegistry.all.count)
    for tool in ToolRegistry.all { try checkDefaults(tool) }
  }

  private func checkDefaults<T: ToolModule>(_ tool: T.Type) throws {
    let description = try CommandCatalog.describe(T.metadata.id)
    let defaults = try #require(description["defaults"] as? [String: Any])
    #expect(Set(defaults.keys) == Set(T.fields.map(\.id)))
    let request = try CommandCatalog.request(T.metadata.id, input: .init(), options: defaults)
    let actual = try JSONSerialization.jsonObject(with: request.options) as? NSDictionary
    #expect(actual == defaults as NSDictionary)
  }

  @Test func pipePreservesWhitespaceAndTextHasNoAddedNewline() async throws {
    let source = "  你好\n\"$HOME\" \\\n"
    let encoded = await run(["run", "base64", "--format", "text"], stdin: source)
    #expect(encoded.exitCode == 0)
    #expect(encoded.stdout == Data(Data(source.utf8).base64EncodedString().utf8))
    let decoded = await run(["run", "base64", "--option", "operation=decode", "--format", "text"],
      stdin: String(decoding: encoded.stdout, as: UTF8.self))
    #expect(decoded.stdout == Data(source.utf8))
  }

  @Test func requestUsesPlainOptionsAndPartialInput() async throws {
    let result = await run(["run", "--request", "-", "--format", "json"],
      stdin: #"{"id":"base64","input":{"text":"aGVsbG8="},"options":{"operation":"decode"}}"#)
    let envelope = try #require(JSONSerialization.jsonObject(with: result.stdout) as? [String: Any])
    #expect(result.exitCode == 0)
    #expect((envelope["output"] as? [String: Any])?["text"] as? String == "hello")
    #expect(envelope["protocolVersion"] as? Int == 1)
    #expect(result.stderr.isEmpty)
  }

  @Test func conditionalOptionsKeepExplicitPath() throws {
    let defaults = try CommandCatalog.describe("json", options: ["operation": "query", "syntax": "pointer"])
    #expect((defaults["defaults"] as? [String: Any])?["path"] as? String == "")
    let request = try CommandCatalog.request("json", input: .init(),
      options: ["path": "/users/0", "syntax": "pointer", "operation": "query"])
    #expect(try JSONDecoder().decode(JsonTool.Options.self, from: request.options).path == "/users/0")
  }

  @Test func discoveryDefaultsToReadableGroupsAndSupportsExplicitJSON() async throws {
    let human = await run(["list"])
    let text = String(decoding: human.stdout, as: UTF8.self)
    #expect(human.exitCode == 0)
    #expect(text.contains("编码与转换"))
    #expect(text.contains("base64"))
    #expect(text.contains("[联网]"))
    #expect(!text.contains("\"protocolVersion\""))
    for tool in ToolRegistry.all { #expect(text.contains(tool.metadata.id)) }
    let machine = await run(["list", "--format", "json"])
    let envelope = try #require(JSONSerialization.jsonObject(with: machine.stdout) as? [String: Any])
    #expect((envelope["tools"] as? [[String: Any]])?.count == ToolRegistry.all.count)

    let description = await run(["describe", "json", "--option", "operation=query"])
    let detail = String(decoding: description.stdout, as: UTF8.self)
    #expect(detail.contains("JSON 工作台"))
    #expect(detail.contains("jsonpath"))
    #expect(detail.contains("查询路径"))
    let jsonDescription = await run(["describe", "json", "--format", "json"])
    let jsonEnvelope = try #require(JSONSerialization.jsonObject(with: jsonDescription.stdout) as? [String: Any])
    #expect((jsonEnvelope["tool"] as? [String: Any])?["id"] as? String == "json")
  }

  @Test func humanResultsShowReportsAndAttachmentDetailsWithoutEncodedData() async {
    #expect(await run(["run", "base64", "--text", "hello"]).stdout == Data("aGVsbG8=\n".utf8))
    let bytes = Data("attachment-only-content".utf8)
    let output = ToolOutput("result", rows: [ResultRow("Actual", "123")],
      artifacts: [Artifact("result.bin", "application/octet-stream", bytes)], note: "note",
      report: ResultReport("failure", "Mismatch", "Values differ"))
    let result = await DevKitCommandLine.run(arguments: ["run", "base64", "--text", ""],
      isInputTerminal: true, readInput: { Data() }, execute: { _ in output })
    let text = String(decoding: result.stdout, as: UTF8.self)
    for value in ["result", "未通过", "Values differ", "Actual", "123", "result.bin", "note"] {
      #expect(text.contains(value))
    }
    #expect(!text.contains(bytes.base64EncodedString()))
    #expect(!text.contains("attachment-only-content"))
    #expect(await run(["run", "base64", "--text", ""]).stdout == Data("（空结果）\n".utf8))
    #expect(await run(["run", "base64", "--text", "", "--format", "text"]).stdout.isEmpty)
  }

  @Test func errorsFollowRequestedFormatWithoutInterpretingUserData() async throws {
    let args = ["run", "base64", "--text", "$", "--option", "operation=decode"]
    let human = await run(args)
    #expect(human.exitCode == 1)
    #expect(String(decoding: human.stderr, as: UTF8.self).hasPrefix("错误："))
    for invalid in [args, ["run", "uuid", "--option", "count=oops"], ["run", "unknown"]] {
      let machine = await run(invalid + ["--format", "json"])
      #expect(machine.stdout.isEmpty)
      let envelope = try #require(JSONSerialization.jsonObject(with: machine.stderr) as? [String: Any])
      #expect(envelope["error"] is [String: Any])
    }
    let literal = await run(["run", "base64", "--text", "--format", "json"])
    #expect(String(decoding: literal.stderr, as: UTF8.self).hasPrefix("错误："))
    let secret = await run(["describe", "hmac", "--option", "key=secret-example"])
    #expect(!String(decoding: secret.stdout, as: UTF8.self).contains("secret-example"))
  }

  @Test func invalidArgumentsNeverExecute() async {
    let inputs: [[String]] = [
      ["run", "unknown"], ["run", "base64", "--option", "typo=true"],
      ["run", "base64", "--option", "operation=typo"],
      ["run", "uuid", "--option", "count=0"], ["run", "uuid", "--option", "count=1.5"],
      ["run", "base64", "--option", "padding=yes"],
      ["run", "base64", "--text", "x", "--input-file", "foo"],
      ["run", "base64", "--text", "x", "--text", "y"],
      ["run", "base64", "--option", "padding=true", "--option", "padding=false"],
      ["run", "base64", "--request", "-"], ["run", "base64", "--format", "xml"],
      ["describe", "base64", "--text", "x"], ["list", "garbage"],
      ["run", "http-client", "--text", "https://example.com"],
    ]
    for args in inputs {
      let result = await DevKitCommandLine.run(arguments: args, isInputTerminal: true,
        readInput: { Issue.record("Unexpected stdin read"); return Data() },
        execute: { _ in Issue.record("Unexpected execution"); return ToolOutput() })
      #expect(result.exitCode == 2, "\(args)")
      #expect(result.stdout.isEmpty)
      #expect(!result.stderr.isEmpty)
    }
  }

  @Test func malformedRequestAndJSONTypesAreRejected() async {
    for json in ["[]", "null", "{", #"{"id":"base64","input":{"text":42}}"#,
      #"{"id":"base64","options":{"padding":1}}"#,
      #"{"id":"uuid","options":{"count":true}}"#,
      #"{"id":"base64","input":{"typo":"x"}}"#,
      #"{"id":"base64","options":{"operation":null}}"#] {
      let result = await run(["run", "--request", "-"], stdin: json)
      #expect(result.exitCode == 2)
      #expect(result.stdout.isEmpty)
    }
  }

  @Test func executionErrorsAndTimeoutHaveDistinctExitCodes() async {
    #expect(await run(["run", "base64", "--text", "$", "--option", "operation=decode"]).exitCode == 1)
    let result = await DevKitCommandLine.run(arguments: ["run", "base64", "--text", ""],
      isInputTerminal: true, readInput: { Data() }, execute: { _ in throw ToolFailure("timeout", code: "timeout") })
    #expect(result.exitCode == 124)
    #expect(result.stdout.isEmpty)
  }

  @Test func filesAndInputLimits() async throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let file = folder.appendingPathComponent("sample.txt")
    try Data("a\nb\n".utf8).write(to: file)
    let encoded = await run(["run", "base64", "--input-file", file.path, "--format", "text"])
    #expect(encoded.stdout == Data("YQpiCg==".utf8))
    let checksum = await run(["run", "file-checksum", "--file", file.path, "--format", "text"])
    #expect(String(decoding: checksum.stdout, as: UTF8.self) == Digest.compute(Data("a\nb\n".utf8), algorithm: "SHA-256"))
    let result = await run(["run", "base64"], stdin: String(repeating: "x", count: Limits.textBytes + 1))
    #expect(result.exitCode == 2)
    try Data([255]).write(to: file)
    #expect(await run(["run", "base64", "--input-file", file.path]).exitCode == 2)
  }

  @Test func installationPreservesConflictsAndUpdatesManagedLinks() throws {
    let manager = FileManager.default
    let folder = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try manager.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? manager.removeItem(at: folder) }
    let source = folder.appendingPathComponent("source"), next = folder.appendingPathComponent("next")
    let link = folder.appendingPathComponent("bin/devkit")
    try Data("one".utf8).write(to: source); try Data("two".utf8).write(to: next)
    try AutomationInstallation.installLink(source: source, destination: link)
    try AutomationInstallation.installLink(source: source, destination: link)
    #expect(AutomationInstallation.isInstalled(source: source, destination: link))
    #expect(throws: (any Error).self) { try AutomationInstallation.installLink(source: next, destination: link) }
    try AutomationInstallation.installLink(source: next, destination: link, previousSource: source.path)
    #expect(try Data(contentsOf: link) == Data("two".utf8))
    #expect(throws: (any Error).self) { try AutomationInstallation.installLink(source: source, destination: next) }
    #expect(try Data(contentsOf: next) == Data("two".utf8))
    let skill = try #require(AutomationInstallation.skillURL)
    #expect(manager.fileExists(atPath: skill.appendingPathComponent("SKILL.md").path))
  }

  @Test func installMakesBareCommandAvailableInNewZshSessions() throws {
    let manager = FileManager.default
    let home = manager.temporaryDirectory.appendingPathComponent("devkit shell \(UUID().uuidString)")
    try manager.createDirectory(at: home.appendingPathComponent(".local/bin"), withIntermediateDirectories: true)
    defer { try? manager.removeItem(at: home) }
    let command = home.appendingPathComponent(".local/bin/devkit")
    try manager.createSymbolicLink(at: command, withDestinationURL: URL(fileURLWithPath: "/usr/bin/true"))
    let config = home.appendingPathComponent(".zshrc")
    let original = "# User configuration\nexport DEVKIT_TEST_PRESERVED=yes\n"
    try Data(original.utf8).write(to: config)
    try AutomationInstallation.configureCommandPath(home: home, shell: "/bin/zsh", environment: [:])
    let first = try Data(contentsOf: config)
    try AutomationInstallation.configureCommandPath(home: home, shell: "/bin/zsh", environment: [:])
    #expect(try Data(contentsOf: config) == first)
    #expect(String(decoding: first, as: UTF8.self).hasPrefix(original))
    for mode in ["-ic", "-lc"] {
      let process = Process(), pipe = Pipe()
      process.executableURL = URL(fileURLWithPath: "/bin/zsh")
      process.arguments = ["-d", mode, "command -v devkit"]
      process.environment = ["HOME": home.path, "ZDOTDIR": home.path, "PATH": "/usr/bin:/bin"]
      process.standardOutput = pipe
      process.standardError = FileHandle.nullDevice
      try process.run()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      #expect(process.terminationStatus == 0)
      #expect(String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines) == command.path)
    }
  }

  @Test func pathConfigurationHonorsCustomZdotdirAndBashLoginPrecedence() throws {
    let manager = FileManager.default
    let home = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try manager.createDirectory(at: home, withIntermediateDirectories: true)
    defer { try? manager.removeItem(at: home) }
    let custom = home.appendingPathComponent("dotfiles")
    let zsh = try AutomationInstallation.configureCommandPath(home: home, shell: "/bin/zsh",
      environment: ["ZDOTDIR": custom.path])
    #expect(zsh.allSatisfy { $0.deletingLastPathComponent().path == custom.path })
    let profile = home.appendingPathComponent(".profile")
    try Data("# existing login\n".utf8).write(to: profile)
    let bash = try AutomationInstallation.configureCommandPath(home: home, shell: "/bin/bash", environment: [:])
    #expect(bash.first == profile)
    #expect(!manager.fileExists(atPath: home.appendingPathComponent(".bash_profile").path))
  }
}
