# Data & sessions

## Tool sessions

Switching tools retains the current window's input, options, and results. Separate windows share content with the source tool. Closing the last related window or quitting the app ends the session.

[Export](files.md) results you need to keep. Favorites, appearance, and tool switches are saved automatically.

## Files

After importing a file, save processed output using **Export…**. You choose the filename and location.

For the CLI, use `--format text` and redirect output to a file:

```sh
devkit run json --input-file input.json --format text > output.json
```

## Network requests

HTTP and DNS send requests when you run the tool. WebSocket exchanges messages after connecting. CLI network tools require `--allow-network`; see [Network debugging](guides/network.md).

Releases with the built-in updater check GitHub daily and download updates from GitHub Releases in the background. Requests contain normal HTTP connection information, such as your IP address and User-Agent, but never tool inputs or results. System profiling is disabled. Turn off automatic checking and downloading in **Settings → Updates**. Choosing **Check for Updates…** manually still connects to GitHub.

## Tokens and keys

Pass tokens and keys through stdin or a request file to keep them out of shell history. Replace real credentials with sample data when reporting an issue.
