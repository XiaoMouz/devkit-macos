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
  var page = EditorPage()
  var pageRevision = 0
  var largeUndo: String?
  var largeRedo: String?
  var largeExpected: String?
  func clearLargeUndo() { largeUndo = nil; largeRedo = nil; largeExpected = nil }
  @ObservationIgnored var selection = NSRange(location: 0, length: 0)
  @ObservationIgnored var scrollOrigin = CGPoint.zero
  @ObservationIgnored var contentID = -1
}

@MainActor @Observable final class WorkspaceBridge {
  var actionTitle = L10n.tr("Run")
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
