# Custom Shortcuts and Pinned Image Dragging

## Scope

This change fixes two interaction gaps without changing the capture workflow:

1. The three global capture shortcuts can be recorded in Preferences and take effect immediately.
2. A pinned screenshot can be moved by dragging anywhere on the image.

## Shortcut Design

The Shortcuts preferences page keeps its current three compact rows. The static key label becomes a recorder control. Clicking it enters recording mode; the next valid key combination replaces the shortcut. Escape cancels recording, while Delete or Backspace restores that action's default shortcut.

A shortcut must include at least one of Command, Shift, Option, or Control. The three SnapSail actions cannot use the same combination. If macOS refuses a combination because another application owns it, SnapSail keeps the previous working shortcut and shows a concise alert.

Shortcut values are persisted in `UserDefaults` as key code, modifier mask, and display label. `CaptureCoordinator` owns registration. Preferences asks the coordinator to replace one registration atomically, so a failed replacement can restore the old working value. The menu bar capture items refresh their displayed key equivalents after a successful change.

## Pinned Image Design

The borderless pinned window already supports resizing, opacity adjustment, double-click close, and a context menu. A single mouse press on the image will now call the native `NSWindow.performDrag(with:)` path. This makes the entire screenshot a drag handle while preserving double-click close and right-click behavior.

## Testing

- Core tests cover default shortcut definitions, display formatting, duplicate detection, and pin click decisions.
- Focused tests are run red before implementation and green afterward.
- Manual accessibility/event verification records a custom shortcut, confirms the new global hotkey opens the overlay, restarts the app to confirm persistence, and drags a pinned image while checking its window origin changes.
- The full Swift test suite, release build, signing verification, and launch check remain required.
