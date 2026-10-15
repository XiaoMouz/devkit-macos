import DevKitCore
import SwiftUI

struct UpdateActionButton: View {
  @ObservedObject private var updater = AppUpdater.shared

  var body: some View {
    Button(updater.actionTitle) { updater.performUpdateAction() }
      .disabled(!updater.canPerformUpdateAction)
  }
}

struct UpdateSettingsView: View {
  @ObservedObject private var updater = AppUpdater.shared

  var body: some View {
    Form {
      Section(L10n.tr("Software Update")) {
        LabeledContent(L10n.tr("Current Version"), value: AppUpdater.version)
        if let version = updater.readyVersion {
          Label(L10n.tr("Version \(version) is ready to install."), systemImage: "arrow.down.circle.fill")
        }
        UpdateActionButton()
        if let error = updater.startupError {
          Text(L10n.tr("The updater could not start: \(error)"))
            .font(.caption).foregroundStyle(.secondary)
        } else if !updater.isAvailable {
          Text(L10n.tr("Updates are available in the installed release of DevKit. Debug builds are updated through Xcode."))
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      Section(L10n.tr("Automatic Updates")) {
        Toggle(L10n.tr("Automatically check for updates"), isOn: Binding(
          get: { updater.automaticallyChecksForUpdates },
          set: { updater.setAutomaticallyChecksForUpdates($0) }))
          .disabled(!updater.isAvailable)
        Toggle(L10n.tr("Automatically download updates"), isOn: Binding(
          get: { updater.automaticallyDownloadsUpdates },
          set: { updater.setAutomaticallyDownloadsUpdates($0) }))
          .disabled(!updater.isAvailable || !updater.automaticallyChecksForUpdates)
        Text(L10n.tr("DevKit checks daily and downloads updates in the background. Install a ready update by restarting, or when you next quit the app."))
          .font(.caption).foregroundStyle(.secondary)
        Text(L10n.tr("Export anything you want to keep before restarting. Current inputs and results will not be restored."))
          .font(.caption).foregroundStyle(.secondary)
      }
      Section {
        Text(L10n.tr("Update checks connect to GitHub. Tool inputs and results are never included, and system profiling is disabled."))
          .font(.caption).foregroundStyle(.secondary)
      }
    }.formStyle(.grouped)
  }
}

struct UpdateReadyBanner: View {
  @ObservedObject private var updater = AppUpdater.shared

  var body: some View {
    if let version = updater.readyVersion {
      HStack {
        Label(L10n.tr("Version \(version) is ready to install."), systemImage: "arrow.down.circle")
        Spacer()
        UpdateActionButton()
      }
      .font(.callout)
      .padding(.horizontal, 16).padding(.vertical, 10)
      .background(.bar)
    }
  }
}
