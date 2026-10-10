import DevKitCore
import SwiftUI

enum WorkspacePane: String, CaseIterable, Identifiable {
  case input, secondary, output
  var id: String { rawValue }
}

/// Keep small presentation choices when a tool's native views are released.
/// Detached windows own their own presentation state and share only tool data.
@MainActor @Observable final class WorkspaceViewState {
  var focusedPane: WorkspacePane = .input
  var display = "text"
  var selectedArtifact = 0
  var completedRun = -1
  let inputEditor = EditorViewState()
  let secondaryEditor = EditorViewState()
  let outputEditor = EditorViewState()
}

@MainActor @Observable final class EditorViewState {
  var languageOverride: SyntaxLanguage?
  @ObservationIgnored var selection = NSRange(location: 0, length: 0)
  @ObservationIgnored var scrollOrigin = CGPoint.zero
}

@MainActor @Observable final class WorkspaceBridge {
  var actionTitle = "执行"
  var runRequest = 0
  var copyRequest = 0
  var showOptions = false
  var running = false
  var workspaceWidth = 1000.0
  var paneRequest = 0
  var paneIndex = 0
  func selectPane(_ index: Int) {
    paneIndex = index
    paneRequest += 1
  }
  var runAction: (() -> Void)?
  var copyAction: (() -> Void)?
  func execute() { if let runAction { runAction() } else { runRequest += 1 } }
  func copy() { if let copyAction { copyAction() } else { copyRequest += 1 } }
}
