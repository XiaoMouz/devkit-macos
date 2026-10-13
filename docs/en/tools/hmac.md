# HMAC

Calculate SHA-256 or SHA-512 message authentication codes with a key.

CLI: `hmac`

## Usage

Enter the message, select an algorithm, and enter the key. Confirm whether the key is UTF-8, hexadecimal, or Base64, then choose the output encoding and run.

## Example

Input:

```text
hello
```

Enter `example-key` as the key and keep the default UTF-8 encoding and SHA-256 algorithm.

Result with this example key and the default algorithm:

```text
a866e07b5eafdf688740211b767b111eb9ce3c0da0b1ec77f1e9205ee440dbf6
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `algorithm` | Algorithm | `SHA-256` | `SHA-256`, `SHA-512` |
| `key` | Key | Empty | Text |
| `keyFormat` | Key format | `utf8` | `utf8`, `hex`, `base64` |
| `output` | Output | `hex` | `hex`, `base64` |

## CLI

```sh
devkit describe hmac
```

For commands containing keys, use a request file you control to keep them out of shell history:

Save this example request as `request.json`:

```json
{
  "id": "hmac",
  "input": {"text": "hello"},
  "options": {"key": "example-key", "keyFormat": "utf8", "algorithm": "SHA-256", "output": "hex"}
}
```

```sh
devkit run --request request.json --format json
```
