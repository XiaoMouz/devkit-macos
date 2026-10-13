# CLI & AI skills

Use the `devkit` command to discover tools, process files, and integrate with AI skills.

## Installation

![CLI and AI skill installation settings; screenshot shown in Chinese](/images/cli-settings.png)

1. Open **Settings → CLI & AI** in DevKit and install the CLI.
2. Open a new terminal to use `devkit`. Existing terminals need to be reopened to load the new configuration.
3. Install the Codex or Claude Code skill if needed, then start a new AI session to use the `devkit` skill.

The command is installed at `~/.local/bin/devkit`. PATH configuration is supported for zsh and bash. After moving the app, update the link from Settings.

Codex skills are installed at `~/.codex/skills/devkit`; Claude Code uses `~/.claude/skills/devkit`. For other AI tools, use the settings action to view `SKILL.md` and put it in the appropriate directory.

::: details Custom directories and removal
If `CODEX_HOME` is set to an absolute path, the Codex skill uses its `skills` directory. The zsh configuration location respects `ZDOTDIR` in the app's environment.

To uninstall, remove the CLI / skill links shown in Settings, then remove the DevKit-marked PATH block from your shell configuration.
:::

## Discover tools

```sh
devkit list
devkit describe base64
devkit describe json --option operation=query
devkit --help
```

`list` lists the tools; `describe` shows input formats, parameters, and examples. Use `--option` to inspect parameters for a specific operation.

Explicitly select JSON when an AI tool or script needs to parse the response:

```sh
devkit list --format json
devkit describe base64 --format json
```

JSON responses include `protocolVersion: 1`.

## Run a tool

```sh
printf '%s' 'hello' | devkit run base64 --format text
# Outputs aGVsbG8= without adding a newline

devkit run json --input-file ./input.json --option operation=minify
devkit run uuid --text '' --option count=1
devkit run file-checksum --file ./image.png --format text
```

The default input is UTF-8 text from a pipe. `--text`, `--input-file`, and `--file` are mutually exclusive. Use `--secondary` or `--secondary-file` for a second text input. Leading/trailing spaces and newlines are preserved.

Repeat `--option key=value` for multiple parameters, or use `--options-file options.json` with a plain JSON object. Booleans must be `true` / `false`; integers must be within range. Unknown parameters, invalid enum values, and duplicate parameters produce errors.

## Structured AI requests

For complex input, use `devkit run --request request.json --format json`, or send a request through stdin to `devkit run --request - --format json`:

```json
{
  "id": "json",
  "input": {"text": "{\"users\":[{\"name\":\"Ada\"}]}"},
  "options": {"operation": "query", "path": "$.users[0].name"}
}
```

`input.text` and `input.secondary` default to empty strings. `input.file` is Base64 and `input.fileName` is the filename. `options` is a plain JSON object; omitted parameters use the tool's defaults. A complete request cannot be combined with a tool ID or other input flags. It can be combined with `--format` and `--allow-network`.

Network tools require `--allow-network`:

```sh
devkit run http-client --text 'https://example.com' --allow-network
```

Pass tokens and keys through stdin or request files to keep them out of shell history.

## Results and errors

Results go to stdout; errors go to stderr.

`--format human` explicitly selects the default human-readable layout. `--format text` is available only for `run`: it outputs exactly `output.text`, with no added trailing newline, for piping or redirection.

`--format json` is intended for AI tools and scripts. Success JSON goes to stdout:

```json
{"protocolVersion":1,"id":"base64","output":{"text":"aGVsbG8=","rows":[],"artifacts":[]}}
```

`output` may also contain `note`, `report`, and `html`. Attachments include `name`, `mime`, and Base64 `data`; the CLI does not automatically write them to files.

In JSON mode, failures go to stderr and stdout is empty:

```json
{"protocolVersion":1,"error":{"code":"usage","message":"…"}}
```

| Exit code | Meaning |
| --- | --- |
| 0 | The tool returned a result |
| 1 | Tool execution failed |
| 2 | Invalid arguments, request structure, or input size |
| 124 | Worker timeout or resource limit |
| 130 / 143 | Cancelled by SIGINT / SIGTERM |

Validation conclusions, including Schema and checksum comparisons, are in `output.report.state`. HTTP status is in the response details.

Combined text input is limited to 5 MiB, binary input to 32 MiB, and the main result to 32 MiB. Workers have limits of 25 seconds wall time and 15 seconds CPU time. Some tools impose lower limits. CLI file checksums also have a 32 MiB input limit; use the app's streaming checksum for larger files. WebSocket CLI calls connect, send, receive, and close once; they do not join the app's interactive session.
