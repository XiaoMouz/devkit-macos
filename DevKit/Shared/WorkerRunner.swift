import Darwin
import DevKitCore
import Foundation

final class WorkerControl: @unchecked Sendable {
  private let lock = NSLock()
  private var process: Process?
  private var stopped = false
  func start(_ process: Process) throws {
    try lock.withLock {
      if stopped { throw CancellationError() }
      self.process = process
      try process.run()
    }
  }
  func stop() {
    lock.withLock {
      stopped = true
      if let process, process.isRunning { kill(process.processIdentifier, SIGKILL) }
      process = nil
    }
  }
}
enum WorkerRunner {
  static func run(_ request: WorkerRequest) async throws -> ToolOutput {
    let control = WorkerControl()
    return try await withTaskCancellationHandler {
      try await Task.detached(priority: .userInitiated) {
        return try autoreleasepool {
        let executable = Bundle.main.bundleURL.appendingPathComponent(
          "Contents/Helpers/DevKitWorker")
        let process = Process()
        process.executableURL = executable
        let stdin = Pipe()
        let stdout = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = FileHandle.nullDevice
        let payload = try JSONEncoder().encode(request)
        try control.start(process)
        let timeout = DispatchWorkItem { control.stop() }
        DispatchQueue.global().asyncAfter(deadline: .now() + 24, execute: timeout)
        defer {
          timeout.cancel()
          control.stop()
        }
        DispatchQueue.global(qos: .userInitiated).async {
          try? stdin.fileHandleForWriting.write(contentsOf: payload)
          try? stdin.fileHandleForWriting.close()
        }
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0, !data.isEmpty else {
          throw ToolFailure("处理已停止或超时。请减小输入后重试。", code: "timeout")
        }
        let result = try JSONDecoder().decode(WorkerResponse.self, from: data)
        if let error = result.error { throw error }
        guard let output = result.output else { throw ToolFailure("没有收到处理结果。", code: "internal") }
        return output
        }
      }.value
    } onCancel: {
      control.stop()
    }
  }
}
