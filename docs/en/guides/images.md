# Images & favicons

Choose, drop, or paste an image. Adjust options, run, then copy the image or export attachments from the result panel.

## Resize an image

Image Resize provides three modes:

| Mode | Use case |
| --- | --- |
| Proportional scaling | Fit within width/height bounds while keeping the whole image |
| Transparent canvas | Keep the whole image and fill out the specified canvas |
| Center crop | Fill the target dimensions and crop overflow |

For an 800 × 600 preview, load the image, enter width and height, and choose a mode based on whether cropping is acceptable. Output is PNG. Check padding and crop boundaries before export.

## Convert and compress

Image Converter encodes PNG, JPEG, and HEIC. WebP encoding is not currently available. JPEG composites transparent areas onto white. Animated or multi-frame images use only the first frame.

Image Compression outputs JPEG. Adjust quality or set a target size. If the target cannot be met, the tool tells you. It does not provide lossless PNG compression. To retain transparency, use PNG conversion or resizing.

## Inspect and remove metadata

Image Metadata displays image information. Removing metadata re-encodes the image; individual fields cannot be selectively retained or removed. Check dimensions and quality after exporting. The source file is not automatically overwritten.

## Generate favicons

Load a square source image in Favicon to generate multiple PNG sizes and an ICO. Export items individually or save all files into a separate subfolder. Reference the exported files according to your website's build setup.

## Convert between images and text

[Data URL](../tools/data-url.md) converts an image to `data:image/...;base64,...` and can restore an image from it. Decoding preserves the original bytes and format. SVG and non-image payloads are not accepted.

[QR Code](../tools/qr-code.md) generates a PNG from text or a URL, or recognizes text in an image. Preserve the quiet zone around generated codes. Scan again after placing them on a page or in printed material.

![A QR code generated from a documentation URL; screenshot shown in Chinese](/images/qr-code.png)

More options: [Image Resize](../tools/image-resize.md) · [Image Converter](../tools/image-convert.md) · [Image Compression](../tools/image-compress.md) · [Image Metadata](../tools/image-metadata.md) · [Favicon](../tools/favicon.md)
