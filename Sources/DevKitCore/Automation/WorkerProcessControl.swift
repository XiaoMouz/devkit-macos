import Darwin
import Foundation

/// Cancellation and launching share a lock, so cancelling before launch cannot orphan a worker.
public final class WorkerProcessControl: @unchecked Sendable {
  private let lock = NSLock()
  private var process: Process?
  private var stopped = false

  public init() {}

  public func start(_ process: Process) throws {
    try lock.withLock {
      if stopped { throw CancellationError() }
      self.process = process
      try process.run()
    }
  }

  public func stop() {
    lock.withLock {
      stopped = true
      if let process, process.isRunning { kill(process.processIdentifier, SIGKILL) }
      process = nil
    }
  }
}
