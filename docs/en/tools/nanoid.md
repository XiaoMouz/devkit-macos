# Nano ID

Generate Nano IDs with a chosen length and alphabet.

CLI: `nanoid`

## Usage

Set the length, count, and alphabet, then generate.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `length` | Length | `21` | 1–4096 |
| `count` | Count | `5` | 1–1000 |
| `alphabet` | Alphabet | `_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ` | Text |

## CLI

```sh
devkit describe nanoid
```

Generate one result:

```sh
devkit run nanoid --text '' --option count=1
```

## Notes

Total output is limited to 100,000 characters per run.
