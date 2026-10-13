# UUID

Generate UUID v4 or v7 in batches, with letter case and hyphen options.

CLI: `uuid`

## Usage

Choose v4 or v7, set the count, letter case, and hyphens, then generate. v4 is random; v7 includes time-ordering information.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `version` | Version | `v4` | `v4`, `v7` |
| `count` | Count | `5` | 1–1000 |
| `uppercase` | Uppercase | `false` | `true` / `false` |
| `hyphens` | Keep hyphens | `true` | `true` / `false` |

## CLI

```sh
devkit describe uuid
```

Generate one result:

```sh
devkit run uuid --text '' --option count=1
```

## Notes

UUID v7 values generated within the same millisecond are not guaranteed to preserve generation order.
