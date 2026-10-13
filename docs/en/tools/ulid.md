# ULID

Generate ULIDs or extract their timestamps.

CLI: `ulid`

## Usage

In Generate mode, set the count. In Parse mode, enter an existing ULID to inspect its timestamp.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `generate` | `generate`, `parse` |
| `count` | Count | `5` | 1–1000 |

## CLI

```sh
devkit describe ulid
```

Generate one result:

```sh
devkit run ulid --text '' --option count=1
```

## Notes

The random parts are independent within the same millisecond; generation order is not guaranteed to match sort order.
