# Release notes

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
