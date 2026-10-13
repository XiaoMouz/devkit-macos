# Hash

Calculate MD5, SHA-1, SHA-256, and SHA-512 digests.

CLI: `hash`

## Usage

Enter text, choose an algorithm and hexadecimal letter case, then calculate the digest. Newlines and leading or trailing spaces are included.

## Example

Input:

```text
hello
```

Result:

```text
2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `algorithm` | Algorithm | `SHA-256` | `MD5`, `SHA-1`, `SHA-256`, `SHA-512` |
| `uppercase` | Uppercase | `false` | `true` / `false` |

## CLI

```sh
devkit describe hash
```

Read from a file:

```sh
devkit run hash --input-file ./input.txt
```

## Notes

MD5 and SHA-1 are provided for legacy compatibility and checksum workflows.
