# CSS Units

Convert between px, rem, em, vw, and vh.

CLI: `css-unit`

## Usage

Enter a length, choose source and destination units, and set root/parent font sizes and viewport dimensions as needed. Check the context values used for the result.

## Example

Input:

```text
24
```

Result:

```text
1.5rem
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `from` | Source unit | `px` | `px`, `rem`, `em`, `vw`, `vh` |
| `to` | Target unit | `rem` | `px`, `rem`, `em`, `vw`, `vh` |
| `root` | Root font size (px) | `16` | 1–256 |
| `parent` | Parent font size (px) | `16` | 1–256 |
| `width` | Viewport width (px) | `1440` | 1–20000 |
| `height` | Viewport height (px) | `900` | 1–20000 |

## CLI

```sh
devkit describe css-unit
```

Read from a file:

```sh
devkit run css-unit --input-file ./input.txt
```

## Notes

`rem` uses the root font size, `em` the parent font size, and `vw` / `vh` the viewport width / height.
