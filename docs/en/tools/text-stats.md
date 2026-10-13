# Text Statistics

Count graphemes, Unicode code points, UTF-16 units, UTF-8 bytes, and lines.

CLI: `text-stats`

## Usage

Enter or import text and run to compare graphemes, code points, UTF-16 units, UTF-8 bytes, and lines. An emoji's visible character count may differ from its encoded length.

## Example

Input:

```text
Hello 世界 👩‍💻
```

Result:

```text
Graphemes: 10
Unicode code points: 12
UTF-16 units: 14
UTF-8 bytes: 24
Lines: 1
Words (whitespace separated): 3
```

## CLI

```sh
devkit describe text-stats
```

Read from a file:

```sh
devkit run text-stats --input-file ./input.txt
```

## Notes

Words are separated by whitespace. Combined emoji may have different grapheme and code point counts.
