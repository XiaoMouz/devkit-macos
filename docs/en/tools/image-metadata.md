# Image Metadata

Inspect dimensions, EXIF, and color information, or remove metadata.

CLI: `image-metadata`

## Usage

Load an image to inspect its metadata. To remove metadata, enable the removal option, run again, and export the re-encoded image.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `strip` | Export PNG without metadata | `false` | `true` / `false` |

## CLI

```sh
devkit describe image-metadata
```

Read from a file:

```sh
devkit run image-metadata --file ./image.png
```

## Notes

Removing metadata re-encodes the image as PNG.
