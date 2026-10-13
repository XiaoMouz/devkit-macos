# URL Encoder / Decoder

Encode and decode URL components, full URLs, and form data.

CLI: `url-codec`

## Usage

Choose Encode or Decode, then Component, Full URL, or Form mode. Paste the content and run. Form mode handles plus signs and spaces differently from the other modes.

## Example

Input:

```text
hello 世界 + &
```

Result:

```text
hello%20%E4%B8%96%E7%95%8C%20%2B%20%26
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `encode` | `encode`, `decode` |
| `mode` | Mode | `component` | `component`, `url`, `form` |

## CLI

```sh
devkit describe url-codec
```

Read from a file:

```sh
devkit run url-codec --input-file ./input.txt
```

## Notes

Form mode treats `+` as a space. Decoded content must be UTF-8.
