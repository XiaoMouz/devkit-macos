# QR Code

Generate QR code PNGs or read QR codes from images.

CLI: `qr-code`

## Usage

To generate, enter text or a URL, select error correction and scale, then preview, copy, or save the PNG. To scan, choose, drop, or paste a QR code image and run recognition.

## Example

![QR code generation and image preview; screenshot shown in Chinese](/images/qr-code.png)

Input:

```text
https://example.com
```

The result is a QR code PNG that you can preview and save. Scanning it yields the example URL.

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `operation` | Operation | `generate` | `generate`, `scan` |
| `correction` | Error correction | `M` | `L`, `M`, `Q`, `H` |
| `scale` | Pixel scale | `10` | 2–30 |

## CLI

```sh
devkit describe qr-code
```

Read from a file:

```sh
devkit run qr-code --input-file ./input.txt
```

## Notes

Input is limited to 2,000 UTF-8 bytes. Preserve the quiet zone around the QR code when exporting or arranging it in a layout.
