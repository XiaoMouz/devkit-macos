# DNS Lookup

Look up A, AAAA, CNAME, MX, TXT, and other DNS records.

CLI: `dns`

## Usage

Enter a domain and choose a record type. Leave the resolver empty for system settings, or specify a resolver IP and port. Run to inspect the server, answers, and elapsed time.

## Example

Input:

```text
example.com
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `record` | Record type | `A` | `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`, `SOA`, `CAA` |
| `resolver` | Resolver IP (empty for system) | Empty | Text |
| `port` | Resolver port | `53` | 1–65535 |

## CLI

```sh
devkit describe dns
```

Read from a file:

```sh
devkit run dns --input-file ./input.txt --allow-network
```

## Notes

Each query has a 3-second timeout. A custom resolver must be an IP address.
