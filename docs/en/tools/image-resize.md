# Image Resize

Scale proportionally, fit onto a canvas, or crop from the center.

CLI: `image-resize`

## Usage

Load an image and enter the target width and height. Choose proportional scaling, transparent canvas, or center crop, then run. Check the edges and crop in the preview and export PNG.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `width` | Width (px) | `800` | 1–10000 |
| `height` | Height (px) | `600` | 1–10000 |
| `mode` | Mode | `scale` | `scale`, `fit`, `fill` |

## CLI

```sh
devkit describe image-resize
```

Read from a file:

```sh
devkit run image-resize --file ./image.png
```
