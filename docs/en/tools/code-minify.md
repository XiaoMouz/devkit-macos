# Code Minifier

Minify JavaScript, CSS, and HTML.

CLI: `code-minify`

## Usage

Choose JavaScript, CSS, or HTML, enter code, and run. JavaScript conservatively removes whitespace and comments without renaming identifiers.

## Example

Input:

```text
const user={name:"Ada",active:true};
```

Result:

```text
const user={name:"Ada",active:true};
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `language` | Language | `javascript` | `javascript`, `css`, `html` |

## CLI

```sh
devkit describe code-minify
```

Read from a file:

```sh
devkit run code-minify --input-file ./input.txt
```

## Notes

JavaScript minification does not rename identifiers.
