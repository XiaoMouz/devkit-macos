# WebSocket Client

Connect to WebSocket services, send messages, and inspect message history.

CLI: `websocket`

## Usage

Enter a ws:// or wss:// URL and connect. Edit a message and send it manually. Review individual sent and received messages on the right; click an entry to copy it. Disconnect when finished.

Connection state and message history belong to the current WebSocket session. Closing the session disconnects it.

## Example

Input:

```text
wss://echo.websocket.org
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `message` | Message to send | `hello DevKit` | Text |
| `count` | Messages to receive | `1` | 1–100 |

## CLI

```sh
devkit describe websocket
```

Read from a file:

```sh
devkit run websocket --input-file ./input.txt --allow-network
```

The CLI makes a one-shot call and does not share the window connection. Use `message` and `count` to set the outgoing text and the number of messages to receive.

## Notes

Sessions are limited to 1,000 messages / 5 MiB, with a 1 MiB limit per message. History is discarded when the session closes.
