# SnapSail

<p align="center">
  <strong>A fast, native, local-first screenshot workspace for macOS.</strong><br />
  Capture a region or window, stitch a scrolling page, annotate inline, pin the result, and get back to work.
</p>

<p align="center">
  <a href="https://github.com/YidaHu/SnapSail/actions"><img alt="Swift" src="https://img.shields.io/badge/Swift-5.7%2B-F05138?logo=swift&logoColor=white"></a>
  <img alt="macOS" src="https://img.shields.io/badge/macOS-12%2B-111111?logo=apple&logoColor=white">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-147EFB"></a>
  <img alt="Local first" src="https://img.shields.io/badge/Privacy-Local--first-18A058">
</p>

> SnapSail 是一款原生 macOS 截图工具，支持区域截图、窗口截图、滚动长截图、即时标注、钉图、自定义快捷键以及中英文界面。截图在本机处理，不依赖后端服务。

## Why SnapSail?

Most screenshot tasks should take seconds, not a trip through an editor and a stack of dialogs. SnapSail keeps the whole flow in one lightweight native workspace:

1. Trigger a shortcut.
2. Draw or adjust the selection.
3. Annotate without leaving the overlay.
4. Copy, download, pin, or start a scrolling capture.

The app is built with Swift and AppKit, stores history locally, and does not require an account or backend.

## Features

| Area | What it does |
| --- | --- |
| Region capture | Drag, move, resize, and nudge a precise selection across connected displays. |
| Window capture | Select one or multiple windows, with optional native window shadow. |
| Scrolling capture | Stitch overlapping frames into a long image while rejecting stationary duplicate frames. |
| Inline annotation | Rectangle, ellipse, line, arrow, pen, pixelation, text, numbered markers, and highlight. |
| Clipboard and download | Copy finishes without writing a file; Download saves directly to the configured folder without another dialog. |
| Pin on screen | Keep a screenshot floating above other windows, drag it anywhere, and adjust opacity with Option-scroll. |
| Capture history | Keep the latest 20 screenshots locally, open them again, or clear the history from the app. |
| Custom shortcuts | Record custom shortcuts, including standalone F1–F20 keys. |
| Multi-display support | Create and interact with selection overlays on every connected display. |
| Bilingual UI | Switch between English and Simplified Chinese without restarting the app. |
| Local-first privacy | Screenshots, preferences, and history remain on your Mac. |

## Current status

SnapSail is an active open-source project. The repository currently provides source code and a local build script. A notarized downloadable binary and Mac App Store release are not available yet.

## Requirements

- macOS 12 Monterey or later
- Xcode 14 or later, or a compatible Swift 5.7+ toolchain
- Screen Recording permission in **System Settings → Privacy & Security → Screen Recording**

The app uses only Apple frameworks and Swift Package Manager; there are no third-party runtime dependencies.

## Build and run

Clone the repository:

```bash
git clone https://github.com/YidaHu/SnapSail.git
cd SnapSail
```

Build the command-line Swift package:

```bash
swift build
```

Build the packaged macOS application:

```bash
zsh Scripts/build-app.sh
```

The app bundle is written to:

```text
build/SnapSail.app
```

Launch the packaged app:

```bash
zsh Scripts/run-app.sh
```

On first launch, grant Screen Recording permission when macOS asks. If SnapSail was already running when permission changed, quit and relaunch it.

## First capture

The default shortcuts are:

| Action | Default shortcut |
| --- | --- |
| Capture Area | `Command–Shift–2` |
| Capture Window | `Command–Shift–3` |
| Scrolling Capture | `Command–Shift–4` |

For an area capture:

1. Press `Command–Shift–2`.
2. Drag to create a selection.
3. Drag inside the selection to move it, use the handles to resize it, or use the arrow keys for one-point nudges. Hold Shift while nudging to move ten points.
4. Choose an annotation tool if needed.
5. Use **Copy and Finish** to place the image on the clipboard, **Download** to save it directly to the configured folder, or **Pin** to keep it on screen.

## Scrolling capture

1. Press `Command–Shift–4` or choose **Scrolling Capture** from the menu bar.
2. Select only the content area that actually scrolls. Avoid browser chrome, fixed sidebars, and floating controls when possible.
3. Scroll downward slowly and steadily.
4. Watch the live preview and choose **Finish** when the required content is captured.

SnapSail compares adjacent frames, appends only new rows, and ignores effectively stationary frames. If the page contains large animations or sticky elements, pause on stable content and continue more slowly.

## Annotation tools

- Rectangle and ellipse outlines
- Straight line and arrow
- Freehand pen
- Source-based pixelation
- Text labels
- Numbered markers
- Semi-transparent highlight
- Undo and redo

Annotations are rendered at the captured image's native pixel dimensions, so Retina screenshots stay sharp.

## Settings

Open the SnapSail menu-bar icon and choose **Settings…**.

### General

- Play a completion sound
- Show capture notifications
- Keep or disable local capture history
- Switch between English and Simplified Chinese

### Capture

- Include native window shadows
- Configure automatic clipboard/file behavior for non-explicit capture flows

Explicit overlay actions remain deterministic: **Copy and Finish** only copies, while **Download** only writes to the configured folder.

### Export

- PNG or JPEG
- JPEG quality
- Filename prefix
- Download folder

If a filename already exists, SnapSail appends `-2`, `-3`, and so on instead of overwriting it.

### Shortcuts

Click a shortcut capsule and press a new combination. Press Escape to cancel recording, or Delete/Backspace to restore the default. Standalone function keys `F1`–`F20` are supported; depending on your keyboard settings, you may need to hold `Fn` when pressing the physical key.

## Pinning controls

- Drag anywhere on a pinned image to move it.
- Double-click a pinned image to close it.
- Right-click and choose **Close Pinned Image**.
- Hold Option while scrolling over the image to adjust opacity.

## Local data and privacy

SnapSail does not upload screenshots or analytics.

| Data | Location |
| --- | --- |
| Capture history | `~/Library/Application Support/SnapSail/History/` |
| Preferences and shortcuts | macOS `UserDefaults` for `com.yidahu.snapsail` |
| Downloaded screenshots | The folder selected in **Settings → Export** |
| Clipboard image | The macOS system pasteboard |

History is limited to the latest 20 PNG files. Disabling history stops new history writes; **Clear History** removes the existing local history files.

## Architecture

SnapSail separates reusable capture logic from AppKit UI:

```text
SnapSail/
├── Sources/
│   ├── SnapSail/                 # AppKit application, overlays, menu bar, settings
│   └── SnapSailCore/             # Geometry, stitching, annotations, shortcuts, rendering
├── Tests/SnapSailCoreTests/      # XCTest regression suite
├── Resources/Info.plist          # App metadata and permission description
├── Scripts/build-app.sh          # Release app packaging and stable local signing
├── Scripts/run-app.sh            # Build-and-launch helper
└── Package.swift                 # Swift Package Manager manifest
```

Important components:

- `CaptureCoordinator` owns capture workflows and output actions.
- `SelectionOverlayController` creates one native overlay per display.
- `ScrollCaptureController` schedules frames and updates the long-image preview.
- `VerticalFrameMatcher` and `ScrollStitcher` detect overlap and append new rows.
- `InlineAnnotationRasterizer` renders annotations into the exported image.
- `AppPreferences` persists capture, export, language, and shortcut settings.

## Testing

Run the full suite:

```bash
swift test -j 1
```

Build and verify the Release app:

```bash
zsh Scripts/build-app.sh
plutil -lint build/SnapSail.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 build/SnapSail.app
```

The tests cover capture geometry, multi-display overlay coordinates, selection behavior, shortcuts, annotation rendering, pixelation preview, window shadows, scrolling-frame matching, long-image stitching, history retention, localization, and copy/download semantics.

## Troubleshooting

### SnapSail keeps asking for Screen Recording permission

1. Quit SnapSail completely.
2. Open **System Settings → Privacy & Security → Screen Recording**.
3. Enable the exact SnapSail build you are launching.
4. Relaunch `build/SnapSail.app`.

macOS associates privacy permission with the app's code-signing identity. `Scripts/build-app.sh` uses a persistent local signing identity when available so rebuilding does not create a different permission identity every time.

### A function-key shortcut does not trigger

Check **System Settings → Keyboard**. If the top-row keys control brightness or media, use `Fn–F1` or enable “Use F1, F2, etc. keys as standard function keys.” Also verify that another app has not registered the same global shortcut.

### Scrolling capture repeats or stops matching

Select a smaller content-only region, remove animated/sticky content from the selection, and scroll more slowly. SnapSail intentionally rejects ambiguous or stationary frames instead of silently adding repeated content.

### Downloaded images are not where expected

Open **Settings → Export** and inspect **Save folder**. The Download action writes there immediately and does not open a save panel.

## Roadmap

- Signed and notarized release downloads
- Improved automatic handling of sticky headers during scrolling capture
- More annotation styling controls
- Optional history thumbnails and search
- Accessibility and localization refinements

Roadmap items are directional, not release commitments. Issues and focused pull requests are welcome.

## Contributing

1. Fork the repository and create a focused branch.
2. Add or update a regression test before changing behavior.
3. Run `swift test -j 1` and the Release build checks.
4. Keep capture logic in `SnapSailCore` when it does not require AppKit UI.
5. Open a pull request describing the user-visible behavior and verification performed.

For bugs, include your macOS version, display arrangement, exact capture mode, reproduction steps, and whether the issue appears in the preview, exported image, or both.

## License

SnapSail is available under the [MIT License](LICENSE).

## Author

Built by [YidaHu](https://github.com/YidaHu). Product story: [yidahu.top/projects/snapsail](https://www.yidahu.top/projects/snapsail).
