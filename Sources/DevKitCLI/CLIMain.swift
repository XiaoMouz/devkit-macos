import Darwin
import DevKitCore
import Foundation

@main
struct CLIMain {
  static func main() async {
    signal(SIGPIPE, SIG_IGN)
    let result = await DevKitCommandLine.run(arguments: Array(CommandLine.arguments.dropFirst()),
      isInputTerminal: isatty(STDIN_FILENO) != 0,
      readInput: { try DevKitCommandLine.read(.standardInput, limit: DevKitCommandLine.requestLimit) },
      execute: { request in try await Task.detached { try execute(request) }.value })
    do {
      try FileHandle.standardOutput.write(contentsOf: result.stdout)
      try FileHandle.standardError.write(contentsOf: result.stderr)
      exit(result.exitCode)
    } catch { exit(1) }
  }

  private static func execute(_ request: WorkerRequest) throws -> ToolOutput {
    // Resolve the executable itself, including when invoked through ~/.local/bin/devkit.
    guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() else {
      throw ToolFailure("无法定位 CLI。", code: "resource")
    }
    let worker = executable.deletingLastPathComponent().appendingPathComponent("DevKitWorker")
    guard FileManager.default.isExecutableFile(atPath: worker.path) else {
      throw ToolFailure("包内 DevKitWorker 缺失，请从应用设置重新安装 CLI。", code: "resource")
    }
    let process = Process()
    process.executableURL = worker
    let input = Pipe(), output = Pipe()
    process.standardInput = input; process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    let payload = try JSONEncoder().encode(request)
    try process.run()
    // Keep cancellation attached to the one worker owned by this CLI invocation.
    signal(SIGINT, SIG_IGN); signal(SIGTERM, SIG_IGN)
    let sources = [SIGINT, SIGTERM].map { number -> DispatchSourceSignal in
      let source = DispatchSource.makeSignalSource(signal: number, queue: .global())
      source.setEventHandler {
        if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        exit(128 + number)
      }
      source.resume()
      return source
    }
    defer {
      sources.forEach { $0.cancel() }
      try? input.fileHandleForWriting.close()
      try? output.fileHandleForReading.close()
      if process.isRunning { kill(process.processIdentifier, SIGKILL) }
    }
    DispatchQueue.global().async {
      try? input.fileHandleForWriting.write(contentsOf: payload)
      try? input.fileHandleForWriting.close()
    }
    let data = try DevKitCommandLine.read(output.fileHandleForReading, limit: 128 * 1024 * 1024)
    process.waitUntilExit()
    if process.terminationReason == .uncaughtSignal,
      [SIGALRM, SIGXCPU, SIGKILL].contains(process.terminationStatus) {
      throw ToolFailure("处理超时或超过工作进程资源限制。", code: "timeout")
    }
    guard process.terminationStatus == 0, !data.isEmpty else {
      throw ToolFailure("工作进程未正常返回结果。", code: "internal")
    }
    let response = try JSONDecoder().decode(WorkerResponse.self, from: data)
    if let error = response.error { throw error }
    guard let result = response.output else { throw ToolFailure("没有收到处理结果。", code: "internal") }
    return result
  }
}
