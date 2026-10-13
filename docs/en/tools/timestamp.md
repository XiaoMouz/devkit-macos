# Timestamp

Convert Unix seconds or milliseconds to and from dates.

CLI: `timestamp`

## Usage

Choose seconds, milliseconds, or date input, select a time zone, and convert. Use the date/time picker for calendar input. Switching input modes preserves millisecond precision.

## Example

Input:

```text
1700000000
```

In `Asia/Shanghai`, `1700000000` seconds corresponds to `2023-11-15 06:13:20`. Changing the time zone changes the displayed date, not the instant.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `unit` | Timestamp unit | `seconds` | `seconds`, `milliseconds` |
| `timezone` | Time zone | Current system time zone | Text |

## CLI

```sh
devkit describe timestamp
```

Read from a file:

```sh
devkit run timestamp --input-file ./input.txt
```

## Notes

Timestamps are interpreted in the selected unit; dates are displayed in the selected time zone.
