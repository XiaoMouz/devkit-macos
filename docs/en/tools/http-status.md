# HTTP Status Codes

Look up HTTP status code names and meanings.

CLI: `http-status`

## Usage

Enter a status code such as 404 and run to read its name and description. Codes outside the included list link to IANA's reference.

## Example

Input:

```text
404
```

Result:

```text
404 · Not Found
Resource not found
```

## CLI

```sh
devkit describe http-status
```

Read from a file:

```sh
devkit run http-status --input-file ./input.txt
```
