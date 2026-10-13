# cURL Converter

Convert cURL commands to fetch code or JSON.

CLI: `curl-convert`

## Usage

Paste a cURL command, choose fetch code or JSON output, and convert. The tool parses the command without sending a request. Check the destination and credentials before running generated code.

## Example

Input:

```text
curl 'https://example.com/api' -X POST -H 'Content-Type: application/json' -d '{"hello":"world"}'
```

Result:

```text
const response = await fetch("https://example.com/api", {
  "method": "POST",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"hello\":\"world\"}"
});
const data = await response.text();
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `format` | Output | `fetch` | `fetch`, `json` |

## CLI

```sh
devkit describe curl-convert
```

Read from a file:

```sh
devkit run curl-convert --input-file ./input.txt
```

## Notes

Shell operations and `@file` input are not supported.
