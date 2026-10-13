# Color Converter

Convert HEX, RGB, HSL, and alpha values.

CLI: `color`

## Usage

Enter a color or use the color picker, then run to inspect its sRGB HEX, RGB, HSL, and alpha representations. Copy individual values as needed.

## Example

Input:

```text
#3478f6
```

Result:

```text
#3478F6
rgb(52 120 246 / 1)
hsl(218.97 91.51% 58.43% / 1)
```

## CLI

```sh
devkit describe color
```

Read from a file:

```sh
devkit run color --input-file ./input.txt
```
