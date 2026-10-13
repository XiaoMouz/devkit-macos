# Markdown

Preview Markdown and export HTML.

CLI: `markdown`

## Usage

Enter or import Markdown, then run to view sanitized HTML. You can also switch to the text result. The preview does not load external resources or execute scripts.

## Example

Input:

````text
# DevKit

- Encoding conversions
- **Text processing**

```js
const hello = "world";
```
````

## CLI

```sh
devkit describe markdown
```

Read from a file:

```sh
devkit run markdown --input-file ./input.txt
```

## Notes

The preview removes scripts and external resource references.
