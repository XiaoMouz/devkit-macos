import SwiftUI

@MainActor @Observable final class WorkspaceBridge {
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
