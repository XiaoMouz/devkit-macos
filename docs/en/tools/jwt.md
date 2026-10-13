# JWT Workspace

Decode JWT headers and payloads, with optional HS256 signature verification.

CLI: `jwt`

## Usage

Paste a three-part JWT to decode its header and payload. To verify HS256, enable verification and enter the key. Check the signature result separately from exp / nbf time validity. The sample token is only for decoding.

## Example

Input:

```text
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFkYSJ9.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

The signature in this sample is a placeholder. Use it to inspect the header and payload; it does not demonstrate a valid signature.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `verify` | Verify HS256 signature | `false` | `true` / `false` |
| `key` | HS256 key | Empty | Text |

## CLI

```sh
devkit describe jwt
```

Read from a file:

```sh
devkit run jwt --input-file ./input.txt
```

## Notes

Check HS256 signature verification separately from `exp` / `nbf` time validity. Validate claims such as `aud` and `iss` against your application's rules.
