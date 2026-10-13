# Random String

Generate random strings with a chosen alphabet, length, and count.

CLI: `random-string`

## Usage

Set the alphabet, length, count, and whether to exclude similar-looking characters, then generate.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `length` | Length | `24` | 1–4096 |
| `count` | Count | `5` | 1–1000 |
| `alphabet` | Alphabet | `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789` | Text |
| `excludeSimilar` | Exclude similar characters | `true` | `true` / `false` |

## CLI

```sh
devkit describe random-string
```

Generate one result:

```sh
devkit run random-string --text '' --option count=1
```

## Notes

Total output is limited to 100,000 characters per run.
