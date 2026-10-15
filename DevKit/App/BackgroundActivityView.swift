import DevKitCore
import SwiftUI

struct BackgroundActivityMenu: View {
  @ObservedObject private var lifetime = ApplicationLifetime.shared
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    if lifetime.activeTaskCount > 0 {
      Text(L10n.tr("Spotlight tasks running: \(lifetime.activeTaskCount)"))
    } else {
      Text(L10n.tr("Finished. DevKit will quit after 15 seconds of inactivity."))
    }
    Divider()
    Button(L10n.tr("Open DevKit")) {
      openWindow(id: "main")
      NSApp.setActivationPolicy(.regular)
      NSApp.activate()
    }
    Button(L10n.tr("Quit DevKit")) { NSApp.terminate(nil) }
  }
}

struct BackgroundActivitySettings: View {
  @ObservedObject private var lifetime = ApplicationLifetime.shared

  var body: some View {
    Section(L10n.tr("Background Activity")) {
      LabeledContent(L10n.tr("Active Spotlight Tasks"), value: String(lifetime.activeTaskCount))
      Text(L10n.tr("With no open windows, DevKit quits 15 seconds after its last Spotlight task. Hidden and minimized windows stay open. The menu bar shows activity while no windows are open."))
        .font(.caption).foregroundStyle(.secondary)
      Text(L10n.tr("CLI commands exit when finished. Workers stop within 25 seconds and exit if their parent app or command exits."))
        .font(.caption).foregroundStyle(.secondary)
      Text(L10n.tr("DevKit does not install a persistent background service. Temporary Spotlight and CLI tasks do not appear in System Settings → Login Items & Extensions → Allow in the Background."))
        .font(.caption).foregroundStyle(.secondary)
    }
  }
}
