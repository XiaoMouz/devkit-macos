# Release notes

## v0.2.2

- Show temporary Spotlight activity in the menu bar and quit after 15 idle seconds with no open windows. Hidden and minimized workspaces remain open.
- End workers promptly when a CLI command is cancelled or its parent process exits.
- Skip update checks and index synchronization for Spotlight-only background launches.
- Add background activity information and the active Spotlight task count to General settings.

Users on v0.2.1 can choose **Check for Updates…**, then restart to install. Requires macOS 26 or later; the [GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.2.2) includes a universal Apple Silicon / Intel package.

## v0.2.1

Supports macOS 26 or later. The [GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.2.1) includes a universal Apple Silicon / Intel package and a SHA-256 checksum file.

- Added in-app updates with automatic checking, background downloads, signature verification, and installation on restart or quit.
- Added **Settings → Updates** and **Check for Updates…** in the app menu, with separate automatic checking and downloading controls.
- Restarting reminds you to export current inputs and results. Preferences are retained, and Debug builds do not use the release update channel.

Install this version manually once when upgrading from v0.2.0 or earlier. Future updates can then be installed from within the app.

## v0.2.0

Supports macOS 26 or later. The [GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.2.0) includes a universal Apple Silicon / Intel package and a SHA-256 checksum file.

- Added Simplified Chinese and English interfaces, with a system-language option and an app language setting. Windows and menus update immediately while preserving current work and existing results.
- Spotlight commands now accept Chinese operation names, and command examples follow the app language. English commands, existing abbreviations, and previously saved custom aliases remain compatible.
- First-use instructions, Quick Keys, and troubleshooting now share one Spotlight help entry. Manage Quick Keys in Spotlight; in-app alias editing and Quick Key reminders have been removed.
- Source builds use a separate DevKit Debug app, preferences, and Spotlight index to avoid conflicts with the release app.
- Added bilingual user guides, tool tutorials, and interactive product demos.

## v0.1.0

Supports macOS 26 or later. The [GitHub Release](https://github.com/luolayo/devkit-macos/releases/tag/v0.1.0) includes a universal Apple Silicon / Intel package and a SHA-256 checksum file.

- 48 tool entries in 9 categories covering encoding, data, hashes, text, time, networking, frontend styles, and graphics.
- Eight JSON operations in one workspace, with structural reports and collapsible previews.
- Tool search and favorites, session retention, separate windows, syntax highlighting, and segmented editing for large text.
- The `devkit` CLI and skills for Codex / Claude Code.
- Performance improvements for the editor, sidebar, and tool switching.
