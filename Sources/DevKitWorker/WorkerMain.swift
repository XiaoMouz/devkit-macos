import Darwin
import DevKitCore
import Foundation

@main
struct WorkerMain {
  static func main() async {
    // A hard stop also covers synchronous parsers that do not cooperate with Task cancellation.
    alarm(25)
    var cpu = rlimit(rlim_cur: 15, rlim_max: 15)
    setrlimit(RLIMIT_CPU, &cpu)
    let response: WorkerResponse
    do {
      let data = FileHandle.standardInput.readDataToEndOfFile()
      try require(data.count <= 60 * 1024 * 1024, L10n.tr("Request exceeds the worker process limit."))
      let request = try JSONDecoder().decode(WorkerRequest.self, from: data)
      try Limits.check(request.input)
      guard let tool = ToolRegistry.find(request.id) else { throw ToolFailure(L10n.tr("Tool not found.")) }
      let output = try await tool.executeEncoded(request.input, options: request.options)
      try require(
        output.text.utf8.count + output.artifacts.reduce(0, { $0 + $1.data.count })
          <= Limits.outputBytes, L10n.tr("Result exceeds 32 MiB."))
      response = WorkerResponse(output: output)
    } catch let error as ToolFailure { response = WorkerResponse(error: error) } catch {
      response = WorkerResponse(error: ToolFailure(error.localizedDescription))
    }
    if let data = try? JSONEncoder().encode(response) {
      try? FileHandle.standardOutput.write(contentsOf: data)
    }
  }
}
