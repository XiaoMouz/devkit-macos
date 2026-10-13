# Installation & first steps

## Installation

Requires macOS 26 or later.

1. Download the app archive from [Releases](https://github.com/luolayo/devkit-macos/releases/latest).
2. Extract it, move `DevKit.app` to Applications, and open it.
3. To use the command line, install it in **Settings → CLI & AI**. See the [CLI guide](cli-and-ai.md).

To upgrade, quit the app and replace it in the same location with the new version.

DevKit follows the system language by default. To choose English or Simplified Chinese, see [Choose a language](shortcuts.md#choose-a-language).

## Your first conversion

1. Search for `Base64` in the sidebar and select it.
2. Select the input panel's sample action to fill in `hello`.
3. Choose **Encode**, then run with the main toolbar button or `⌘Return`.
4. The result should be `aGVsbG8=`. Select **Copy** in the result panel to copy the full output.
5. To restore the text, choose **Decode**, enter `aGVsbG8=`, and run again.

![Base64 encoding hello as aGVsbG8=; screenshot shown in Chinese](/images/base64.png)

After changing input or options, run again using the main toolbar button.

## Find your everyday tools

Search by name, English tool ID, category, or purpose. The star in the toolbar adds a favorite, pinned near the top of the sidebar. Switching tools preserves the current window's input, options, and results.

| Task | Start here |
| --- | --- |
| Format, compare, or check JSON | [Eight JSON operations](guides/json.md) |
| Debug an API, WebSocket, or DNS | [Network debugging](guides/network.md) |
| Resize images, change formats, or create favicons | [Images & favicons](guides/images.md) |
| Use tools in a terminal or with AI | [CLI & AI skills](cli-and-ai.md) |
| See input and results together | [Workspace & windows](workspace.md) |

## Save results before quitting

[Export](files.md) anything you want to keep before quitting. Input and results are not restored on the next launch.
