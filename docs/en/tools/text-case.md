# Text Case

Convert camelCase, PascalCase, snake_case, kebab-case, uppercase, and lowercase.

CLI: `text-case`

## Usage

Enter words or a variable name, choose the target case, and run. Punctuation acts as a word boundary.

## Example

Input:

```text
helloWorld HTTPServer
```

Result:

```text
helloWorldHttpServer
```

## Formats and Spotlight commands

The app and Spotlight share format names, and command examples follow the interface language. For example, use `text-case camelCase hello world` or `case UPPERCASE hello world`. Translated operation names are also accepted; canonical CLI values remain unchanged.

| Format | Command / CLI value |
| --- | --- |
| Camel Case | `camelCase` |
| Pascal Case | `PascalCase` |
| Snake Case | `snake_case` |
| Kebab Case | `kebab-case` |
| Uppercase | `UPPERCASE` |
| Lowercase | `lowercase` |

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `mode` | Format | `camelCase` | `camelCase`, `PascalCase`, `snake_case`, `kebab-case`, `UPPERCASE`, `lowercase` |

## CLI

```sh
devkit describe text-case
```

Read from a file:

```sh
devkit run text-case --input-file ./input.txt
```
