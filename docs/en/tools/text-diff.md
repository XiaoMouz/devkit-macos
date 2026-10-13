# Text Diff

Compare two texts line by line and inspect additions and deletions.

CLI: `text-diff`

## Usage

Put the original and revised text in the two inputs. Choose whether to ignore whitespace at the start and end of each line, then run to see the summary and line-by-line differences.

## Example

Input:

```text
hello
world
```

Second input:

```text
hello
Web developer
```

Result:

```text
  hello
− world
+ Web developer
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `ignoreWhitespace` | Ignore leading/trailing whitespace | `false` | `true` / `false` |

## CLI

```sh
devkit describe text-diff
```

Read from a file:

```sh
devkit run text-diff --input-file ./input.txt --secondary-file ./secondary.txt
```

## Notes

The two inputs may contain up to 10,000 lines in total. Comparison is line based.
