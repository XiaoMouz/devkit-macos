# Unit Converter

Convert file sizes, durations, and rates.

CLI: `unit-convert`

## Usage

Enter a value and select source and destination units of the same kind. KiB / MiB use base 1024; KB / MB use base 1000.

## Example

Input:

```text
1024
```

Result:

```text
1048576 B
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `from` | Source unit | `KiB` | `B`, `KB`, `MB`, `GB`, `KiB`, `MiB`, `GiB`, `ms`, `s`, `min`, `h`, `bit/s`, `Kbit/s`, `Mbit/s`, `MB/s` |
| `to` | Target unit | `B` | `B`, `KB`, `MB`, `GB`, `KiB`, `MiB`, `GiB`, `ms`, `s`, `min`, `h`, `bit/s`, `Kbit/s`, `Mbit/s`, `MB/s` |

## CLI

```sh
devkit describe unit-convert
```

Read from a file:

```sh
devkit run unit-convert --input-file ./input.txt
```

## Notes

KB / MB use base 1000; KiB / MiB use base 1024.
