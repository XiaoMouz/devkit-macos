# Regex Tester

Test ECMAScript regular expressions, inspect capture groups, and preview replacements.

CLI: `regex`

## Usage

Enter the source text, an ECMAScript expression, and flags. Match mode shows matches and captures. For Replace mode, also enter a replacement template such as $1.

## Example

Input:

```text
user@example.com
hello@devkit.app
```

Result:

```text
[
  {
    "index": 0,
    "match": "user@example.com",
    "groups": [
      "user",
      "example.com"
    ]
  },
  {
    "index": 17,
    "match": "hello@devkit.app",
    "groups": [
      "hello",
      "devkit.app"
    ]
  }
]
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `pattern` | Pattern | `([\w.-]+)@([\w.-]+)` | Text |
| `flags` | Flags | `g` | Text |
| `operation` | Operation | `match` | `match`, `replace` |
| `replacement` | Replacement text | `$1@new.test` | Text |

## CLI

```sh
devkit describe regex
```

Read from a file:

```sh
devkit run regex --input-file ./input.txt
```

## Notes

Returns up to 10,000 matches. Expressions that take too long are terminated.
