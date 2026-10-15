import Foundation
import Testing
@testable import DevKitCore

struct BackgroundLifetimeTests {
  @Test func backgroundLaunchAndRepeatedNotificationsHaveABoundedLifetime() {
    var policy = BackgroundLifetimePolicy(now: 100)
    #expect(!policy.shouldTerminate(now: 114.9))
    policy.setHasOpenWindows(false, now: 114)
    #expect(policy.shouldTerminate(now: 115))
  }

  @Test func overlappingTasksOnlyQuitAfterTheLastCompletion() {
    var policy = BackgroundLifetimePolicy(now: 0)
    let first = UUID(), second = UUID()
    policy.begin(first)
    policy.begin(second)
    policy.finish(first, now: 10)
    #expect(!policy.shouldTerminate(now: 100))
    policy.finish(second, now: 110)
    #expect(!policy.shouldTerminate(now: 124))
    #expect(policy.shouldTerminate(now: 125))
    policy.finish(second, now: 124) // Duplicate completion cannot keep the app alive.
    #expect(policy.idleDeadline == 125)
  }

  @Test func newTaskAtIdleDeadlineCancelsTermination() {
    var policy = BackgroundLifetimePolicy(now: 0)
    let id = UUID()
    policy.begin(id)
    #expect(!policy.shouldTerminate(now: 15))
    policy.finish(id, now: 20)
    #expect(policy.idleDeadline == 35)
  }

  @Test func openHiddenAndMinimizedWindowsProtectWorkUntilClosed() {
    var policy = BackgroundLifetimePolicy(now: 0)
    policy.setHasOpenWindows(true, now: 14)
    let id = UUID()
    policy.begin(id)
    policy.finish(id, now: 20)
    #expect(!policy.shouldTerminate(now: 1000))
    policy.setHasOpenWindows(false, now: 1000)
    #expect(!policy.shouldTerminate(now: 1014))
    #expect(policy.shouldTerminate(now: 1015))
  }

  @Test func closingLastWindowWaitsForActiveTask() {
    var policy = BackgroundLifetimePolicy(now: 0)
    policy.setHasOpenWindows(true, now: 0)
    let id = UUID()
    policy.begin(id)
    policy.setHasOpenWindows(false, now: 3)
    #expect(!policy.shouldTerminate(now: 100))
    policy.finish(id, now: 105)
    #expect(policy.shouldTerminate(now: 120))
  }

  @Test func cancellationBeforeLaunchDoesNotStartWorker() throws {
    let control = WorkerProcessControl()
    control.stop()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/true")
    #expect(throws: CancellationError.self) { try control.start(process) }
    #expect(!process.isRunning)
  }
}
