# Image Converter

Convert images between PNG, JPEG, and HEIC.

CLI: `image-convert`

## Usage

Load an image, choose PNG, JPEG, or HEIC, set quality where applicable, and convert/export. JPEG composites transparent areas onto white.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `format` | Format | `png` | `png`, `jpeg`, `heic` |
| `quality` | Lossy quality (%) | `85` | 1–100 |

## CLI

```sh
devkit describe image-convert
```

Read from a file:

```sh
devkit run image-convert --file ./image.png
```

## Notes

Processes the first frame. JPEG composites transparency onto white; choose PNG to preserve transparency. WebP encoding is not currently supported.
