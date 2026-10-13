# Network debugging

Send HTTP requests, exchange WebSocket messages, or look up DNS records.

## Send an HTTP request

1. Open HTTP Client and enter a complete `http://` or `https://` URL.
2. Choose a method such as GET or POST.
3. Add headers as key/value rows. For JSON bodies, set `Content-Type: application/json`.
4. Enter the request body and send the request.
5. Read the response body, then switch to the status/headers view to check the status code and content type.

Responses are limited to 5 MiB. Depending on the response type, save JSON, an image, or another file. A completed request returning 4xx/5xx should be investigated using the server response; this differs from a connection timeout or name-resolution failure.

CLI headers are passed as a JSON object. Save complex requests in a file:

```json
{
  "id": "http-client",
  "input": {"text": "https://example.com", "secondary": ""},
  "options": {"method": "GET", "headers": "{\"Accept\":\"text/html\"}"}
}
```

```sh
devkit run --request request.json --allow-network --format json
```

## Exchange WebSocket messages

Enter a `ws://` or `wss://` URL and connect. Edit messages on the left and send them manually. Sent and received messages appear individually on the right; click a message to copy its full content. Disconnect when finished. Closing the owning session also closes the connection.

A session is limited to 1,000 messages / 5 MiB, with a 1 MiB limit per message. History is not saved across launches. The CLI connects, sends, receives, and closes once; it does not join the app window's persistent connection.

## Look up DNS records

Enter a domain and choose a record type such as A, AAAA, or MX. Leave the resolver empty for system defaults, or specify a resolver IP and port. Run to inspect the server, answers, and elapsed time. Each query has a 3-second timeout.

```sh
devkit run dns --text example.com --option record=A --allow-network
```

## Start from cURL

Paste a command into cURL Converter and choose fetch or JSON output. The tool statically parses common URL, method, header, and body arguments without executing the command. Shell operations and `@file` input are rejected. Check credentials and the target address before running generated code in your environment.

## Related tools

[HTTP Client](../tools/http-client.md) · [WebSocket](../tools/websocket.md) · [DNS](../tools/dns.md) · [URL Parser](../tools/url-parser.md) · [Query String](../tools/query-string.md) · [Cookie](../tools/cookie.md) · [HTTP Status Codes](../tools/http-status.md)
