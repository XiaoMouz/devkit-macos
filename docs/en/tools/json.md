# JSON Workspace

Format, minify, query, compare, validate against a Schema, and generate TypeScript types.

CLI: `json`

## Usage

Choose an operation from the toolbar. Queries require a syntax and path; structural comparison and Schema validation require a second input. Type generation lets you name the root type.

![JSON workspace](/images/json-workspace.png)

See the [JSON task guide](../guides/json.md) for all eight operations.

## Example

Input:

```json
{"name":"DevKit","version":1,"users":[{"id":1,"name":"Ada"}]}
```

Result:

```text
{
  "name": "DevKit",
  "version": 1,
  "users": [
    {
      "id": 1,
      "name": "Ada"
    }
  ]
}
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `format` | `format`, `minify`, `validate`, `tree`, `query`, `diff`, `schema`, `typescript` |
| `syntax` | Query syntax | `jsonpath` | `jsonpath`, `pointer` |
| `path` | Query path | `$` | Text |
| `name` | TypeScript type name | `Root` | Text |

## CLI

```sh
devkit describe json
```

Read from a file:

```sh
devkit run json --input-file ./input.txt
```

## Notes

Schema validation uses Draft 2020-12. The collapsible preview shows up to 10,000 nodes; copying and exporting preserve the full result.
