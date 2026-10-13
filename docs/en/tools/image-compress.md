# Image Compression

Adjust JPEG quality or compress toward a target file size.

CLI: `image-compress`

## Usage

Load an image, set JPEG quality and an optional target size, then compress. Check the actual size. If the target cannot be reached, adjust dimensions or quality as suggested.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `quality` | Maximum quality (%) | `85` | 10–100 |
| `targetKB` | Target KB (0 for unlimited) | `0` | 0–32000 |

## CLI

```sh
devkit describe image-compress
```

Read from a file:

```sh
devkit run image-compress --file ./image.png
```

## Notes

Output is JPEG. If the target cannot be reached, lower the quality or resize the image first.
