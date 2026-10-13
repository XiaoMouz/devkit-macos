# Cookie

Parse Cookie and Set-Cookie headers.

CLI: `cookie`

## Usage

Choose Cookie Request Header or Set-Cookie Response Header, paste the header text, and parse. Multiple Set-Cookie lines retain their attributes; commas in Expires are not treated as entry separators.

## Example

Input:

```text
session=example; Path=/; HttpOnly; Secure; SameSite=Lax
```

Result:

```text
[
  {
    "name" : "session",
    "value" : "example"
  },
  {
    "name" : "Path",
    "value" : "/"
  },
  {
    "name" : "HttpOnly",
    "value" : "true"
  },
  {
    "name" : "Secure",
    "value" : "true"
  },
  {
    "name" : "SameSite",
    "value" : "Lax"
  }
]
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `mode` | Type | `set-cookie` | `set-cookie`, `cookie` |

## CLI

```sh
devkit describe cookie
```

Read from a file:

```sh
devkit run cookie --input-file ./input.txt
```

## Notes

Separate multiple Set-Cookie values with newlines. Commas in Expires attributes are preserved.
