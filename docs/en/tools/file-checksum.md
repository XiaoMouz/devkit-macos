# File Checksum

Calculate a file digest and compare it with an expected value.

CLI: `file-checksum`

## Usage

Choose a file and an algorithm, then calculate the checksum. To check a download, enter the publisher's checksum as the expected value. The result shows both the digest and comparison status. You can cancel while processing a large file.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `algorithm` | Algorithm | `SHA-256` | `MD5`, `SHA-1`, `SHA-256`, `SHA-512` |
| `expected` | Expected checksum (optional) | Empty | Text |

## CLI

```sh
devkit describe file-checksum
```

Read from a file:

```sh
devkit run file-checksum --file ./download.zip
```

## Notes

The app streams large files and supports cancellation. CLI file input is limited to 32 MiB.
