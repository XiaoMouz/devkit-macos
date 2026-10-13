# Color Contrast

Calculate foreground/background contrast and check WCAG AA / AAA results.

CLI: `contrast`

## Usage

Choose foreground and background colors, then run to inspect the contrast ratio and AA / AAA results for different text sizes. Only opaque colors are accepted.

## Example

Input:

```text
#FFFFFF
```

Result:

```text
Contrast ratio: 4.0671:1
AA normal text ≥4.5: Fail
AA large text ≥3: Pass
AAA normal text ≥7: Fail
AAA large text ≥4.5: Fail
```

## Parameters

| Parameter | Name | Default | Values or range |
| --- | --- | --- | --- |
| `background` | Background color | `#3478F6` | Text |

## CLI

```sh
devkit describe contrast
```

Read from a file:

```sh
devkit run contrast --input-file ./input.txt
```

## Notes

Only opaque colors are supported. Normal and large text have different contrast requirements.
