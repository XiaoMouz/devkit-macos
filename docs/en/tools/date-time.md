# Date & Time Zones

Convert time zones, add or subtract days, and calculate time differences.

CLI: `date-time`

## Usage

Choose time zone conversion, date arithmetic, or time difference. Confirm source and destination zones and use the date/time pickers. Time difference requires a second date.

## Example

Input:

```text
2026-10-11 12:00:00
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `zones` | `zones`, `add-days`, `difference` |
| `sourceZone` | Source time zone | Current system time zone | Text |
| `zone` | Target time zone | Current system time zone | Text |
| `days` | Days to add/subtract | `1` | -36500–36500 |
| `other` | Comparison date | Current time | Text |

## CLI

```sh
devkit describe date-time
```

Read from a file:

```sh
devkit run date-time --input-file ./input.txt
```

## Notes

Date arithmetic uses calendar days in the selected zone; differences use elapsed seconds. A day across a daylight-saving change can be 23 or 25 hours.
