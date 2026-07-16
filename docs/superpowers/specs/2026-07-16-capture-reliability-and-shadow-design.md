# Capture Reliability and Shadow Design

## Goal

Fix first-drag responsiveness, enable capture on every connected display, make download location explicit, and add an Xnip-like shadow to both the live selection and exported region screenshots.

## Input and Multi-Display Windows

SnapSail keeps one borderless overlay window per `NSScreen`. When the screen-specific `NSWindow` initializer is used, its content rectangle is local to that screen and must start at `(0, 0)`; passing `screen.frame` repeats the display origin and misplaces non-primary windows.

Each overlay view accepts the first mouse event even while SnapSail is inactive. Clicking or dragging any display makes that display's overlay key, sets it as the active selection view, and clears selections on the other displays. Keyboard actions continue to target the active view.

## Save Behavior

- Copy/finish remains the default zero-dialog action.
- Download first copies the final image, then opens the native `NSSavePanel` with the configured directory, generated filename, and current PNG/JPEG format.
- A successful save updates the configured directory for the next download.
- Cancelling the save panel leaves the image in the clipboard and closes the capture overlay.
- No editor window opens during copy or download.

## Shadow Rendering

### Live selection

Draw three blue strokes around the selected region: a wide low-opacity glow, a medium glow, and a crisp 2-point border. This remains visible against both light and dark content.

### Exported area image

After annotations are rasterized, wrap area captures in a transparent canvas with 36 pixels of padding on each side. Draw a soft black shadow with downward offset and then the original image at full resolution. The shadow renderer preserves the source pixels and adds only the padding.

Window captures retain the native window shadow supplied by Core Graphics. Scrolling captures receive the same exported shadow as area captures. JPEG export composites transparency onto white; PNG and clipboard output retain alpha.

## Testing

- Screen-placement tests prove secondary screen origins are not applied twice.
- Shadow tests prove output dimensions, transparent corners, non-empty shadow pixels, and unchanged center content.
- Existing selection, annotation, scrolling, signing, and build tests remain green.
- Manual integration covers a single first drag on each connected display, Save-panel appearance, clipboard retention after cancelling Save, and visible output shadow.

