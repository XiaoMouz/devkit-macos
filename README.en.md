# DevKit for macOS

[简体中文](README.md) · **English**

A macOS toolbox for web developers, with tools for encoding, JSON, text, dates, network debugging, and images.

[Download](https://github.com/luolayo/devkit-macos/releases/latest) · [Documentation](https://luolayo.github.io/devkit-macos/en/)

![DevKit JSON workspace](docs/public/images/json-workspace.png)

The screenshot shows the Chinese interface; the app also supports English.

## Installation

Requires macOS 26 or later. A universal package supports Apple Silicon and Intel.

Download the app archive from [Releases](https://github.com/luolayo/devkit-macos/releases/latest), extract it, and move `DevKit.app` to Applications.

## Tools

| Category | Tools |
| --- | --- |
| Encoding & data | Base64, URL encoding and decoding, Data URL, JSON workspace |
| Hashes & tokens | Hashes, HMAC, file checksums, JWT, certificate parsing |
| Generation & text | UUID, ULID, Nano ID, mock data, regex, text comparison and statistics |
| Dates & numbers | Timestamps, time zones, Cron, number bases, number formatting, unit conversion |
| Web & network | URLs, query strings, cookies, HTTP, WebSocket, DNS, cURL conversion |
| Code & graphics | Code formatting and minification, Markdown, SVG, QR codes, images, favicons |
| Frontend styles | Color conversion, contrast, CSS units |

Search and favorite tools, use syntax highlighting, compare input and results, and open separate windows. See the [tool reference](https://luolayo.github.io/devkit-macos/en/tools/) for all 48 tools.

## CLI & AI

Install `devkit` and the Codex / Claude Code skill from **Settings → CLI & AI**.

```sh
devkit list
devkit describe json
printf '%s' '{"hello":"DevKit"}' | devkit run json --format text
```

See [CLI & AI](https://luolayo.github.io/devkit-macos/en/cli-and-ai.html) for more examples.

## Development

Open `DevKit.xcodeproj` in Xcode, choose **DevKit / My Mac**, configure your development team, and press **⌘R**.

Debug launches as **DevKit Debug**, with settings and Spotlight indexing separate from the release app. Release archives retain the **DevKit** name.

```sh
DEVKIT_LANGUAGE=zh-Hans swift test
```

Run tests with `DEVKIT_LANGUAGE=zh-Hans` because the test suite includes assertions against Chinese output.

[Development guide (Chinese)](.codex/docs/development.md) · [Architecture (Chinese)](.codex/docs/architecture.md) · [Repository conventions (Chinese)](AGENTS.md)

## Translation contributions

The app supports English and Simplified Chinese and follows the system language by default. Changing language in Settings updates the interface and menus immediately while retaining current input and results.

Code and source messages use English. To add a language, translate the English JSON catalog; you do not need to understand Chinese or modify business logic. See [Localization and translation contributions](.codex/docs/localization.md).

The documentation also supports [English](https://luolayo.github.io/devkit-macos/en/) and [Simplified Chinese](https://luolayo.github.io/devkit-macos/). Use the language menu to switch the current article. Documentation screenshots currently show the Chinese interface.
