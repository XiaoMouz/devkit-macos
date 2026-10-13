# Base64

Encode and decode UTF-8 text with standard or URL-safe Base64.

CLI: `base64`

## Usage

Choose Encode or Decode and the appropriate URL-safe setting. When encoding, choose whether to keep padding, enter your text, and run the tool.

![Base64 encoding result](/images/base64.png)

## Example

Input:

```text
hello
```

Result:

```text
aGVsbG8=
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `encode` | `encode`, `decode` |
| `urlSafe` | URL-safe | `false` | `true` / `false` |
| `padding` | Keep padding | `true` | `true` / `false` |

## CLI

```sh
devkit describe base64
```

Read from a file:

```sh
devkit run base64 --input-file ./input.txt
```

## Notes

Decoded content must be UTF-8 text. For images, use [Data URL](data-url.md).
