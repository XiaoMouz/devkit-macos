# Data URL

Convert images to and from Data URLs.

CLI: `data-url`

## Usage

To encode, choose, drop, or paste an image and select Generate Data URL. To decode, paste the complete data:image/... value and select Restore Image, then export the result.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `encode` | `encode`, `decode` |

## CLI

```sh
devkit describe data-url
```

Read from a file:

```sh
devkit run data-url --file ./image.png
```

## Notes

Data URL text is limited to 5 MiB. Image payloads are supported; SVG is not. Decoding preserves the original image format.
