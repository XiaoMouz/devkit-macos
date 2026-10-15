import Darwin
import DevKitCore
import Foundation

enum WorkerRunner {
  static func run(_ request: WorkerRequest) async throws -> ToolOutput {
    let control = WorkerProcessControl()
    let language = L10n.language
    return try await withTaskCancellationHandler {
      try await Task.detached(priority: .userInitiated) {
        return try autoreleasepool {
        let executable = Bundle.main.bundleURL.appendingPathComponent(
          "Contents/Helpers/DevKitWorker")
        let process = Process()
        process.executableURL = executable
        var environment = ProcessInfo.processInfo.environment
        environment["DEVKIT_LANGUAGE"] = language
        process.environment = environment
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
          throw ToolFailure(L10n.tr("Processing stopped or timed out. Reduce the input and try again."), code: "timeout")
        }
        let result = try JSONDecoder().decode(WorkerResponse.self, from: data)
        if let error = result.error { throw error }
        guard let output = result.output else { throw ToolFailure(L10n.tr("No processing result received."), code: "internal") }
        return output
        }
      }.value
    } onCancel: {
      control.stop()
    }
  }
}
