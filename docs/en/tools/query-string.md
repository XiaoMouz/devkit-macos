# Query String

Parse, build, and sort query parameters while preserving duplicate keys and empty values.

CLI: `query-string`

## Usage

Parse mode accepts a query string; Build mode accepts ordered key/value JSON; Sort mode orders parameters. Choose form semantics to match the source. Duplicate keys are preserved.

## Example

Input:

```text
tag=swift&tag=web&q=hello+world
```

Result:

```text
[
  {
    "name" : "tag",
    "value" : "swift"
  },
  {
    "name" : "tag",
    "value" : "web"
  },
  {
    "name" : "q",
    "value" : "hello world"
  }
]
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `parse` | `parse`, `build`, `sort` |
| `form` | Form: + means space | `true` | `true` / `false` |

## CLI

```sh
devkit describe query-string
```

Read from a file:

```sh
devkit run query-string --input-file ./input.txt
```

## Notes

Form mode interprets `+` as a space. Use ordered key/value pairs to represent repeated parameters.
