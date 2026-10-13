# Files & export

## Choose the right input

| Content | Action |
| --- | --- |
| UTF-8 text, JSON, code | Import from the input panel, or drop a text file |
| Images | Choose, drop, or paste an image |
| File checksums | Choose a file in File Checksum |
| A piece of text | Type it or use Paste |

Base64 handles UTF-8 text. Use [Data URL](tools/data-url.md) to encode or decode images.

## File sizes

Combined text input is limited to 5 MiB. Ordinary image and binary input is limited to 32 MiB. Images also have pixel-dimension limits.

File Checksum in the app streams files larger than 32 MiB, displays progress, and supports cancellation. CLI file input still has a 32 MiB limit.

## Copy and export

Select **Copy** in the result panel, or press `⌘⇧C`, to copy the current valid full result. Image results copy the image; text results copy the full text. A copy action beside a row copies only that row.

**Export…** opens the system save dialog. Depending on the tool, output can be text, JSON, PNG, JPEG, ICO, or another attachment. Check the filename and destination before saving. The app does not automatically overwrite the source file.

Favicons can be exported individually or all at once into a separate subfolder at your chosen destination. ZIP export is not currently available.

## Image considerations

Image processing reads the first frame and corrects orientation. JPEG composites transparent areas onto white. Choose PNG to preserve transparency. Conversion, resizing, and metadata removal may re-encode an image; check dimensions, transparency, and color after export.

## A result needs an update

After changing input or options, run the tool again. Once it completes, you can copy or export the updated result.
