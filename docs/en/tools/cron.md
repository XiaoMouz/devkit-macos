# Cron

Preview upcoming times for a five-field Cron expression.

CLI: `cron`

## Usage

Enter a five-field expression, choose a time zone, starting time, and result count. Use the current time or a specific start, then inspect upcoming times and their UTC offsets.

## Example

Input:

```text
*/15 9-18 * * 1-5
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `timezone` | Time zone | Current system time zone | Text |
| `start` | Start time | Empty | Text |
| `count` | Result count | `10` | 1–100 |

## CLI

```sh
devkit describe cron
```

Read from a file:

```sh
devkit run cron --input-file ./input.txt
```

## Notes

Uses five fields with no seconds field. Results include UTC offsets. This tool previews times; it does not schedule jobs.
