# URL Parser

Inspect a URL's scheme, host, port, path, query, and fragment.

CLI: `url-parser`

## Usage

Paste a complete URL and parse it to inspect each component. Use Query String to edit query parameters.

## Example

Input:

```text
https://example.com:8080/api/users?q=hello%20world#result
```

Result:

```text
Scheme: https
Host: example.com
Port: 8080
Path: /api/users
Query: q=hello%20world
Fragment: result
Full URL: https://example.com:8080/api/users?q=hello%20world#result
```

## CLI

```sh
devkit describe url-parser
```

Read from a file:

```sh
devkit run url-parser --input-file ./input.txt
```
