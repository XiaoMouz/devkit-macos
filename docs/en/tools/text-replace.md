# Find & Replace

Find and replace literal text or regular expressions.

CLI: `text-replace`

## Usage

Enter the source, search text, and replacement. Literal mode replaces strings; regex mode uses an ECMAScript expression and flags. Check the result to confirm which occurrences were replaced.

## Example

Input:

```text
hello world
hello DevKit
```

Result:

```text
Hello world
Hello DevKit
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `search` | Search | `hello` | Text |
| `replacement` | Replacement | `Hello` | Text |
| `regex` | Regex mode | `false` | `true` / `false` |
| `flags` | Regex flags | `g` | Text |

## CLI

```sh
devkit describe text-replace
```

Read from a file:

```sh
devkit run text-replace --input-file ./input.txt
```
