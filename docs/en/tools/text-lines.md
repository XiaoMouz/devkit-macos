# Text Lines

Sort, deduplicate, remove empty lines, number lines, and add prefixes or suffixes.

CLI: `text-lines`

## Usage

Enter multiple lines and choose an operation. For affixes, enter the prefix and suffix before running. The result is separate from the original input.

## Example

Input:

```text
banana
apple
banana

cherry
```

Result:

```text
banana
apple

cherry
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `mode` | Operation | `deduplicate` | `deduplicate`, `sort`, `reverse-sort`, `remove-empty`, `number`, `affix` |
| `prefix` | Prefix | Empty | Text |
| `suffix` | Suffix | Empty | Text |

## CLI

```sh
devkit describe text-lines
```

Read from a file:

```sh
devkit run text-lines --input-file ./input.txt
```
