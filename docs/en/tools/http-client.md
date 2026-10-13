# HTTP Client

Send HTTP requests and inspect the body, status, timing, and response headers.

CLI: `http-client`

## Usage

Enter a complete HTTP/HTTPS URL, select a method, add headers as key/value rows, and enter a request body if needed. Select Send Request, then inspect the body and status/headers views.

## Example

Input:

```text
https://example.com
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `method` | Method | `GET` | `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS` |
| `headers` | Headers JSON | `{}` | Text |

## CLI

```sh
devkit describe http-client
```

Read from a file:

```sh
devkit run http-client --input-file ./input.txt --secondary-file ./secondary.txt --allow-network
```

## Notes

Response bodies are limited to 5 MiB. For 4xx / 5xx responses, check the status code together with the body.
