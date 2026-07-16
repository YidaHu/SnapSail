# SnapSail

SnapSail is a native macOS menu-bar screenshot app built with Swift and AppKit. It supports area capture, window capture, manual scrolling capture, annotation, pinning, local history, clipboard copy, and PNG/JPEG export.

## Requirements

- macOS 12 or later
- Xcode 14 / Swift 5.7 or later
- Screen Recording permission

## Build and run

```bash
zsh Scripts/build-app.sh
zsh Scripts/run-app.sh
```

The packaged app is written to `build/SnapSail.app`.

Pinned images can be closed by double-clicking or by choosing **Close Pinned Image** from the right-click menu. Hold Option while scrolling over a pinned image to adjust its opacity.

## Shortcuts

- `Command-Shift-2`: area capture
- `Command-Shift-3`: window capture
- `Command-Shift-4`: scrolling capture

For scrolling capture, select only the scrolling content, then scroll downward slowly. SnapSail pauses safely when it cannot match adjacent frames and keeps the content already captured.

## Privacy

SnapSail processes screenshots locally. Capture history is stored in `~/Library/Application Support/SnapSail/History` and can be disabled or cleared from the app.
