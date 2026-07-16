# SnapSail Inline Capture Workspace Design

## Goal

Replace the post-selection mini action bar and separate editor window with an Xnip-style inline capture workspace. Selection, annotation, pinning, copying, and saving remain inside the full-screen capture overlay so the normal completion path has no secondary window or confirmation dialog.

## Visual Layout

- Keep the desktop under a dark translucent overlay and reveal the selected rectangle.
- Draw a bright blue 2-point selection border with strong corner markers.
- Place a blue measurement pill centered above the selection. It shows width, a lock icon, height, and `pt`.
- Place a circular pin button immediately outside the selection's upper-right edge.
- Place a wide white capsule toolbar below the selection, falling back above it when the lower screen edge is too close.
- Use dark monochrome SF Symbols, 40-point hit targets, 12-point internal spacing, and thin separators between tool groups.

## Toolbar

The capsule is divided into three groups:

1. Annotation tools: rectangle, ellipse, line, arrow, pen, pixelate, text, numbered marker, and highlight.
2. Editing controls: color, undo, redo, and cancel.
3. Completion controls: pin, scrolling capture, save to the configured directory, and copy/finish.

The selected annotation tool uses a soft blue fill and blue symbol. Cancel is red. Disabled undo and redo use reduced opacity.

## Interaction

- After the drag ends, the selection remains editable with eight resize handles and keyboard nudging.
- Choosing an annotation tool changes the pointer to crosshair inside the selection.
- Annotation geometry is stored in selection-local coordinates so moving the selection keeps annotations aligned.
- Undo and redo apply only to inline annotations.
- `Return` performs the default completion action: render, copy to clipboard, and close.
- Copy/finish performs the same action without opening `EditorWindowController`.
- Save renders and writes directly to the configured directory without an `NSSavePanel`, copies the result to the clipboard, and closes.
- Pin renders the result, opens a pinned image, copies it to the clipboard, and closes.
- Scrolling capture remains available from the completion group and starts from the current selection.
- `Escape` cancels the capture workspace.

## Rendering and Data Flow

`SelectionOverlayView` owns an inline annotation model. Mouse events are routed to selection movement/resizing unless an annotation tool is active and the pointer starts inside the selection. The overlay renders annotations for immediate feedback. Before a completion action, the coordinator captures the clean selected screen rectangle and composites the annotation model into a final `CGImage` using the same coordinate mapping as the overlay.

`SelectionOutcome` carries the selection, completion action, and immutable annotation snapshot. `CaptureCoordinator` performs copy/save/pin behavior directly. The separate editor remains available for history items but is no longer part of the standard screenshot path.

## Performance

- Store lightweight annotation vectors; never recapture the screen while drawing.
- Redraw only the overlay during pointer movement.
- Capture and rasterize exactly once when a completion action is selected.
- Keep undo snapshots value-based and bounded to the current capture session.

## Error Handling

- If capture or rendering fails, close the overlay and show one capture-failure alert.
- If direct saving fails, keep the rendered image in the clipboard and show one concise save-failure alert.
- A tiny selection cannot enter editing mode.

## Tests

- Annotation model tests cover commit, undo, redo, and selection-local geometry.
- Completion policy tests cover default copy, direct save plus copy, pin plus copy, and scrolling behavior.
- Existing selection, scrolling matcher, packaging, signing, and launch checks remain required.

