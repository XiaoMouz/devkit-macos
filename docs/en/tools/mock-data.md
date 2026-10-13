# Mock Data

Generate JSON or CSV test data from a field template.

CLI: `mock-data`

## Usage

Enter a JSON object mapping field names to field types. Set the row count, seed, and JSON / CSV format, then generate. Reuse the same seed and configuration for repeatable data.

## Example

Input:

```json
{"id":"index","name":"name","email":"email","active":"boolean","score":"integer"}
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `count` | Rows | `10` | 1–10000 |
| `seed` | Repeatable seed | `42` | 0–2147483647 |
| `format` | Format | `json` | `json`, `csv` |

## CLI

```sh
devkit describe mock-data
```

Read from a file:

```sh
devkit run mock-data --input-file ./input.txt
```

## Notes

The same seed and configuration produce the same test data. Do not use generated data as security credentials.
