import Foundation

/// Deterministic idle policy; the app supplies a monotonic clock and window state.
public struct BackgroundLifetimePolicy: Sendable {
  public static let idleDelay: TimeInterval = 15
  public private(set) var activities: Set<UUID> = []
  public private(set) var hasOpenWindows = false
  public private(set) var idleDeadline: TimeInterval?

  public init(now: TimeInterval) { idleDeadline = now + Self.idleDelay }

  public mutating func setHasOpenWindows(_ value: Bool, now: TimeInterval) {
    guard value != hasOpenWindows else { return }
    hasOpenWindows = value
    updateDeadline(now: now)
  }

  public mutating func begin(_ id: UUID) {
    activities.insert(id)
    idleDeadline = nil
  }

  public mutating func finish(_ id: UUID, now: TimeInterval) {
    guard activities.remove(id) != nil else { return }
    updateDeadline(now: now)
  }

  public func shouldTerminate(now: TimeInterval) -> Bool {
    !hasOpenWindows && activities.isEmpty && idleDeadline.map { now >= $0 } == true
  }

  private mutating func updateDeadline(now: TimeInterval) {
    idleDeadline = !hasOpenWindows && activities.isEmpty ? now + Self.idleDelay : nil
  }
}
