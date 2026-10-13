# Code Formatter

Format JavaScript, TypeScript, HTML, CSS, and SQL.

CLI: `code-format`

## Usage

Choose a language, paste the code, and set indentation. For SQL, also select a dialect. Run using the main toolbar button.

## Example

Input:

```text
const user={name:"Ada",active:true};
```

Result:

```text
const user = { name: "Ada", active: true };

```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `language` | Language | `javascript` | `javascript`, `typescript`, `html`, `css`, `sql` |
| `indent` | Indentation | `2` | 1–8 |
| `dialect` | SQL dialect | `sql` | `sql`, `mysql`, `postgresql`, `sqlite`, `transactsql` |

## CLI

```sh
devkit describe code-format
```

Read from a file:

```sh
devkit run code-format --input-file ./input.txt
```
