# Number Base

Convert signed integers between bases, including large integers.

CLI: `number-base`

## Usage

Enter an integer, select source and destination bases, and convert. Keep large numbers as text; there is no need to convert them to floating point first.

## Example

Input:

```text
255
```

Result:

```text
ff
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `from` | Source base | `10` | `2`, `8`, `10`, `16` |
| `to` | Target base | `16` | `2`, `8`, `10`, `16` |

## CLI

```sh
devkit describe number-base
```

Read from a file:

```sh
devkit run number-base --input-file ./input.txt
```

## Notes

Supports signed integers, but not fixed-width two's-complement conversion.
