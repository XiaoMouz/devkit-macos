import Darwin
import DevKitCore
import Foundation

@main
struct CLIMain {
  static func main() async {
    signal(SIGPIPE, SIG_IGN)
    let control = WorkerProcessControl()
    // Install handlers before reading stdin or launching a worker, closing the launch race.
    let signals = [SIGINT, SIGTERM, SIGHUP].map { number -> DispatchSourceSignal in
      signal(number, SIG_IGN)
      let source = DispatchSource.makeSignalSource(signal: number, queue: .global())
      source.setEventHandler { @Sendable in
        control.stop()
        exit(128 + number)
      }
      source.resume()
      return source
    }
    defer { signals.forEach { $0.cancel() }; control.stop() }
    let result = await DevKitCommandLine.run(arguments: Array(CommandLine.arguments.dropFirst()),
      isInputTerminal: isatty(STDIN_FILENO) != 0,
      readInput: { try DevKitCommandLine.read(.standardInput, limit: DevKitCommandLine.requestLimit) },
      execute: { request in try await Task.detached { try execute(request, control: control) }.value })
    do {
      try FileHandle.standardOutput.write(contentsOf: result.stdout)
      try FileHandle.standardError.write(contentsOf: result.stderr)
      exit(result.exitCode)
    } catch { exit(1) }
  }

  private static func execute(_ request: WorkerRequest, control: WorkerProcessControl) throws -> ToolOutput {
    // Resolve the executable itself, including when invoked through ~/.local/bin/devkit.
    guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() else {
      throw ToolFailure(L10n.tr("Could not locate the CLI."), code: "resource")
    }
    let worker = executable.deletingLastPathComponent().appendingPathComponent("DevKitWorker")
    guard FileManager.default.isExecutableFile(atPath: worker.path) else {
      throw ToolFailure(L10n.tr("The bundled DevKitWorker is missing. Reinstall the CLI from app settings."), code: "resource")
    }
    let process = Process()
    process.executableURL = worker
    var environment = ProcessInfo.processInfo.environment
    environment["DEVKIT_LANGUAGE"] = L10n.language
    process.environment = environment
    let input = Pipe(), output = Pipe()
    process.standardInput = input; process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    let payload = try JSONEncoder().encode(request)
    try control.start(process)
    defer {
      try? input.fileHandleForWriting.close()
      try? output.fileHandleForReading.close()
      control.stop()
    }
    DispatchQueue.global().async {
      try? input.fileHandleForWriting.write(contentsOf: payload)
      try? input.fileHandleForWriting.close()
    }
    let data = try DevKitCommandLine.read(output.fileHandleForReading, limit: 128 * 1024 * 1024)
    process.waitUntilExit()
    if process.terminationReason == .uncaughtSignal,
      [SIGALRM, SIGXCPU, SIGKILL].contains(process.terminationStatus) {
      throw ToolFailure(L10n.tr("Processing timed out or exceeded worker resource limits."), code: "timeout")
    }
    guard process.terminationStatus == 0, !data.isEmpty else {
      throw ToolFailure(L10n.tr("The worker did not return a valid result."), code: "internal")
    }
    let response = try JSONDecoder().decode(WorkerResponse.self, from: data)
    if let error = response.error { throw error }
    guard let result = response.output else { throw ToolFailure(L10n.tr("No processing result received."), code: "internal") }
    return result
  }
}
