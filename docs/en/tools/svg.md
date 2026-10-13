# SVG Workspace

Optimize SVG source and preview the graphic.

CLI: `svg`

## Usage

Paste or import SVG source and run to inspect the optimized result and restricted preview. Input containing scripts, entities, or external references is rejected.

## Example

Input:

```text
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="160"><rect width="240" height="160" rx="28" fill="#3478f6"/><circle cx="120" cy="80" r="42" fill="white"/></svg>
```

## CLI

```sh
devkit describe svg
```

Read from a file:

```sh
devkit run svg --input-file ./input.txt
```

## Notes

Input with scripts, entities, or external references is rejected. Exports SVG only; raster image export is not available.
