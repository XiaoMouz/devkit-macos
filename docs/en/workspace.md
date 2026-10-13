# Workspace & windows

The workspace contains a sidebar, toolbar, input, and results. Each tool uses text editors, date/number forms, file pickers, or a dedicated network interface.

![JSON input and results side by side; screenshot shown in Chinese](/images/json-workspace.png)

## Input, options, and execution

Use the sample, paste, or import actions to enter content, then adjust the options above the input area.

Select the main toolbar action or press `⌘Return` to run. You can cancel during execution. After changing input or options, run again to update the result.

## Side-by-side and full-panel layouts

| Layout | Purpose |
| --- | --- |
| Side by side | Edit input and read results together |
| Input | Make room for long text or many input options |
| Result | Read long output, images, or validation reports |
| Automatic | Choose a layout based on content size and window width |

Choose input, result, or side-by-side mode from the toolbar. Adjust automatic layout in the window/layout menu. A manually selected layout does not keep switching as you type. Tools such as structural comparison and Schema validation provide a second input.

## Reading results

Editing input marks the result as needing an update. Run again before copying or exporting.

Use the result view menu to switch between text, rows, previews, or a collapsible view. Validation and comparison tools include a conclusion and detailed findings.

## Separate windows

Open input, result, or side-by-side windows from the window/layout menu. Each separate window shares its source tool's in-memory session. Editing input marks the results in all related windows as needing an update.

Switching tools in the main window does not change existing separate windows. They remain usable after you close the main window. Opening the same panel again activates its existing window. The contents are discarded when the last window for that session closes.

WebSocket uses its own connection interface instead of the standard conversion tool window workflow.

## Large text

Large text is shown in segments. Use the previous/next segment actions to navigate, or copy the full text. Processing and export use the complete content.

Segmented editing uses plain text. Switching segments clears the current segment's undo history. Very long lines can scroll horizontally. See [Files & export](files.md) for input limits.
