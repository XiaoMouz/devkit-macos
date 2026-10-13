# Frequently asked questions

## Copy or export is unavailable

Check that the tool has completed successfully and that the result does not need an update. Editing input or options makes the old result stale. Run again before copying. Check the status separately for empty output and failed execution.

## Base64 decoding fails

Check whether the input uses standard or URL-safe Base64, and whether it is intact. Base64 returns UTF-8 text only. Use Data URL for images. Non-UTF-8 binary output is explicitly rejected.

## Why did a plus sign in a URL become a space?

Form mode treats `+` as a space. URL components and full URLs use different rules. Choose the mode that matches the source and avoid encoding or decoding the same content twice. See [URL Encoder / Decoder](tools/url-codec.md).

## JSON formats successfully but fails Schema validation

Valid JSON only establishes correct syntax. Schema checks types, required fields, and other rules. Inspect the paths and reasons in the report, and confirm the second input contains the intended Schema.

## Only part of a long text is visible

Large text uses segmented editing or a truncated preview. Navigate between segments to see other content; full-text copying and exporting still use the entire result. The collapsible JSON preview shows up to 10,000 nodes. See [Workspace & windows](workspace.md).

## Where does content go after switching tools or quitting?

Switching tools in the same window retains sessions. Separate windows share their source tool's session. Input and keys are not automatically restored after quitting or closing the last window for a session. Export anything you need to retain.

## The terminal says command not found: devkit

Install the CLI in **Settings → CLI & AI**, then open a new terminal. PATH is configured for zsh / bash; for other shells, add `~/.local/bin` to PATH. Update the link after moving the app. If a file with the same name already exists, check which tool owns it before replacing it. See [CLI installation](cli-and-ai.md#installation).

## My AI tool cannot find the skill

Install the CLI first, then the corresponding AI skill and start a new AI session. If you use a custom skills directory, place the same `SKILL.md` provided by Settings in the directory your AI tool actually uses.

## HTTP, WebSocket, or DNS cannot connect

Check the address, protocol, port, and network connection. An HTTP request may complete with an error status from the server. Custom DNS resolvers require an IP address. WebSocket URLs must start with `ws://` or `wss://`. The CLI also requires `--allow-network`. Use a controlled test service on the same network to distinguish input problems from target-service problems.

## An image turns white or does not meet the target size

JPEG does not support transparency and composites it onto white. Use PNG when transparency matters. Achievable file size depends on source content, dimensions, and quality. If the target cannot be met, the tool reports it; adjust dimensions or quality and retry.

## DevKit actions are missing from Spotlight

Check the main and per-tool switches, open the Spotlight actions list, and search for the action. Quick Keys must be assigned manually. See [Spotlight](spotlight.md).

## macOS cannot open the app

Check that you are using macOS 26 or later and that the download is complete. If macOS reports a damaged package or unverifiable source, download it again from Releases and compare the checksum. Include the full message, OS version, and package name when reporting the issue.

## How do I report a problem?

Open a [GitHub Issue](https://github.com/luolayo/devkit-macos/issues) with the app version, macOS version, chip architecture, tool name, minimal reproduction steps, and expected/actual results. Use public sample data; do not upload real tokens, keys, internal addresses, or business files.
