# Number Format

Set decimal places, rounding, and digit grouping.

CLI: `number-format`

## Usage

Enter a decimal number, choose decimal places, rounding, and grouping, then run. Check both the input and rounding rules when exact decimal values matter.

## Example

Input:

```text
1234567.895
```

Result:

```text
1,234,567.90
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `scale` | Decimal places | `2` | 0–20 |
| `rounding` | Rounding | `plain` | `plain`, `bankers`, `down`, `up` |
| `grouping` | Digit grouping | `true` | `true` / `false` |

## CLI

```sh
devkit describe number-format
```

Read from a file:

```sh
devkit run number-format --input-file ./input.txt
```

## Notes

Supports up to 38 significant digits and does not output scientific notation.
