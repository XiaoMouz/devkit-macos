import AppKit
import Combine
import DevKitCore
import Sparkle

/// One updater for every window. Sparkle owns downloads, validation and replacement.
@MainActor final class AppUpdater: NSObject, ObservableObject, SPUUpdaterDelegate {
  static let shared = AppUpdater()

  @Published private(set) var canCheckForUpdates = false
  @Published private(set) var automaticallyChecksForUpdates = false
  @Published private(set) var automaticallyDownloadsUpdates = false
  @Published private(set) var readyVersion: String?
  @Published private(set) var startupError: String?

  private var controller: SPUStandardUpdaterController?
  private var installUpdate: (() -> Void)?
  private var started = false

  var isAvailable: Bool { controller != nil && startupError == nil }
  var canPerformUpdateAction: Bool { installUpdate != nil || canCheckForUpdates }
  var actionTitle: String {
    readyVersion == nil ? L10n.tr("Check for Updates…") : L10n.tr("Restart to Update…")
  }
  static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
  }
  private static var supportsUpdates: Bool {
    #if DEBUG
    false
    #else
    Bundle.main.bundleIdentifier == "app.devkit.macos"
    #endif
  }

  private override init() {
    super.init()
    // Never let an Xcode Debug build replace itself with the public Release app.
    if Self.supportsUpdates {
      let controller = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: self, userDriverDelegate: nil)
      self.controller = controller
      let updater = controller.updater
      updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
      updater.publisher(for: \.automaticallyChecksForUpdates).assign(to: &$automaticallyChecksForUpdates)
      updater.publisher(for: \.automaticallyDownloadsUpdates).assign(to: &$automaticallyDownloadsUpdates)
    }
  }

  func start() {
    guard !started, let updater = controller?.updater else { return }
    started = true
    do { try updater.start() }
    catch { startupError = error.localizedDescription }
  }

  func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
    controller?.updater.automaticallyChecksForUpdates = enabled
  }

  func setAutomaticallyDownloadsUpdates(_ enabled: Bool) {
    controller?.updater.automaticallyDownloadsUpdates = enabled
  }

  func performUpdateAction() {
    if let installUpdate {
      let alert = NSAlert()
      alert.messageText = L10n.tr("Restart to Update…")
      alert.informativeText = L10n.tr("Export anything you want to keep before restarting. Current inputs and results will not be restored.")
      alert.addButton(withTitle: L10n.tr("Restart and Install"))
      alert.addButton(withTitle: L10n.tr("Later"))
      guard alert.runModal() == .alertFirstButtonReturn else { return }
      // Retain the handler: Sparkle supports retrying when termination is cancelled.
      installUpdate()
    } else if canCheckForUpdates {
      controller?.checkForUpdates(nil)
    }
  }

  func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem,
    immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool {
    // This callback is after validation/preparation, not merely after download.
    // Keep the app running until the user chooses Restart or quits normally.
    installUpdate = immediateInstallHandler
    readyVersion = item.displayVersionString
    return true
  }

  func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
    installUpdate = nil
    readyVersion = nil
  }
}
