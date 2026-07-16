# SnapSail Xnip-Style Visual Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild SnapSail's capture selection, scrolling preview, editor, settings, and menu-bar UI into a polished Xnip-like native macOS experience while making scrolling capture measurably smoother.

**Architecture:** Keep the existing AppKit application and Swift Package layout. Move selection geometry and frame-matching decisions into testable `SnapSailCore` models, then replace imperative full-view redraws with focused AppKit views and CALayer-backed visual components. Preserve capture, export, history, and annotation behavior behind the existing coordinator.

**Tech Stack:** Swift 5.7, AppKit, Core Animation, Core Graphics, Carbon hotkeys, XCTest, Swift Package Manager.

---

## File map

- `Sources/SnapSailCore/SelectionModel.swift`: region lifecycle, move, resize, keyboard nudge, handle hit testing.
- `Sources/SnapSailCore/VerticalFrameMatcher.swift`: coarse-to-fine frame search.
- `Sources/SnapSailCore/ScrollStitcher.swift`: preview throttling inputs and accepted-frame state.
- `Sources/SnapSail/DesignSystem.swift`: colors, spacing, corner radii, icon button factory, material card view.
- `Sources/SnapSail/SelectionOverlay.swift`: Xnip-style dimming, window hover, region editing, loupe, handles, toolbar.
- `Sources/SnapSail/CaptureCoordinator.swift`: capture/copy/pin/scroll actions returned by the overlay.
- `Sources/SnapSail/ScrollCaptureController.swift`: narrow live-preview card and throttled preview generation.
- `Sources/SnapSail/EditorWindowController.swift`: icon toolbar and image-focused layout.
- `Sources/SnapSail/SettingsWindowController.swift`: top icon tabs and centered form pages.
- `Sources/SnapSail/MenuBarController.swift`: icon menu items and corrected shortcut modifiers.
- `Tests/SnapSailCoreTests/SelectionModelTests.swift`: region interaction regression tests.
- `Tests/SnapSailCoreTests/VerticalFrameMatcherTests.swift`: matching correctness and search-efficiency coverage.

### Task 1: Selection state model

**Files:**
- Create: `Sources/SnapSailCore/SelectionModel.swift`
- Create: `Tests/SnapSailCoreTests/SelectionModelTests.swift`

- [ ] **Step 1: Write failing region-editing tests**

```swift
import CoreGraphics
import XCTest
@testable import SnapSailCore

final class SelectionModelTests: XCTestCase {
    func testMoveClampsSelectionInsideBounds() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        model.move(by: CGSize(width: 300, height: 300))
        XCTAssertEqual(model.region, CGRect(x: 300, y: 280, width: 200, height: 120))
    }

    func testResizeFromTopLeftKeepsMinimumSize() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        model.resize(handle: .topLeft, to: CGPoint(x: 295, y: 105))
        XCTAssertEqual(model.region.width, 24)
        XCTAssertEqual(model.region.height, 115)
    }

    func testKeyboardNudgeUsesOneOrTenPoints() {
        var model = SelectionModel(bounds: CGRect(x: 0, y: 0, width: 500, height: 400))
        model.setRegion(CGRect(x: 100, y: 100, width: 200, height: 120))
        model.nudge(dx: 1, dy: 0, accelerated: false)
        model.nudge(dx: 0, dy: 1, accelerated: true)
        XCTAssertEqual(model.region?.origin, CGPoint(x: 101, y: 110))
    }
}
```

- [ ] **Step 2: Run the tests and verify RED**

Run: `swift test -j 1 --filter SelectionModelTests`

Expected: compilation fails because `SelectionModel` and `SelectionHandle` do not exist.

- [ ] **Step 3: Implement the model**

Create `SelectionHandle` with eight cases and `SelectionModel` with `setRegion`, `move`, `resize`, `nudge`, `handle(at:tolerance:)`, a 24-point minimum size, and bounds clamping. `resize` must keep the opposite edge fixed and standardize the final rectangle.

- [ ] **Step 4: Run tests and commit**

Run: `swift test -j 1 --filter SelectionModelTests`

Expected: 3 tests pass.

```bash
git add Sources/SnapSailCore/SelectionModel.swift Tests/SnapSailCoreTests/SelectionModelTests.swift
git commit -m "feat: add editable capture selection model"
```

### Task 2: Coarse-to-fine scroll matching

**Files:**
- Modify: `Sources/SnapSailCore/VerticalFrameMatcher.swift`
- Modify: `Tests/SnapSailCoreTests/VerticalFrameMatcherTests.swift`

- [ ] **Step 1: Add failing tests for large frames and candidate count**

Extend `VerticalFrameMatch` with `evaluatedCandidates`. Add a 1200×800 synthetic-frame test whose expected shift is 96 and assert `evaluatedCandidates < 120`, while preserving confidence above 0.9.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `swift test -j 1 --filter VerticalFrameMatcherTests`

Expected: compilation fails because `evaluatedCandidates` is missing.

- [ ] **Step 3: Implement coarse and refinement passes**

Use a coarse shift step of `max(2, height / 90)`, sample no more than 80 rows and 120 columns, then refine within one coarse step of the best candidate using a shift step of 1. Return the total number of evaluated candidates. Keep the existing acceptance score and unrelated-frame rejection.

- [ ] **Step 4: Run all core tests and commit**

Run: `swift test -j 1`

Expected: all tests pass and the 1200×800 test completes without a timeout.

```bash
git add Sources/SnapSailCore/VerticalFrameMatcher.swift Tests/SnapSailCoreTests/VerticalFrameMatcherTests.swift
git commit -m "perf: accelerate scrolling frame matching"
```

### Task 3: Native visual system

**Files:**
- Create: `Sources/SnapSail/DesignSystem.swift`

- [ ] **Step 1: Create shared visual tokens**

Define `SnapSailStyle` with `accent = NSColor.systemBlue`, `selectionFill = systemBlue.withAlphaComponent(0.08)`, `overlayDim = black.withAlphaComponent(0.18)`, `cardCornerRadius = 11`, `controlHeight = 30`, and spacing constants 8/12/16/24/32.

- [ ] **Step 2: Create reusable views**

Add `MaterialCardView`, `SymbolButton`, `PillLabel`, and `HoverButton`. `SymbolButton` uses `NSImage(systemSymbolName:)`, template rendering, an 18-point symbol, tooltips, 30×30 hit area, and blue selected background. `MaterialCardView` uses `NSVisualEffectView`, rounded masks, border, and shadow.

- [ ] **Step 3: Build and commit**

Run: `swift build -j 1`

Expected: build succeeds without warnings.

```bash
git add Sources/SnapSail/DesignSystem.swift
git commit -m "feat: add SnapSail native visual system"
```

### Task 4: Xnip-style selection overlay

**Files:**
- Rewrite: `Sources/SnapSail/SelectionOverlay.swift`
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`

- [ ] **Step 1: Separate selection result from action**

Add `SelectionAction` cases `capture`, `scroll`, `copy`, `pin`, and `cancel`. Return `SelectionOutcome(selection: SelectionResult, action: SelectionAction)` from the overlay completion. Update the coordinator so each action uses the same selected image or starts scrolling.

- [ ] **Step 2: Keep the selection alive after mouse-up**

Use `SelectionModel` per active screen. Mouse-up transitions from `.dragging` to `.editing`; it does not finish capture. Editing supports moving inside the region, resizing from eight 8-point handles, arrow-key nudging, Return capture, and Esc cancel.

- [ ] **Step 3: Replace full opaque drawing with refined overlay drawing**

Draw an 18% black mask, cut a clear selection hole with `.copy`, add an 8% blue selection fill, a 2-point blue stroke, 8 white handles with blue borders, and a blue pill size label. Window hover uses the same blue stroke and selected windows use system green.

- [ ] **Step 4: Add loupe and floating toolbar**

Create a 120×86 loupe near the cursor using `CGWindowListCreateImage` for a 20×14-point cursor neighborhood, scaled with nearest-neighbor interpolation and a centered crosshair. Create a material toolbar with SF Symbols `checkmark`, `arrow.down.to.line.compact`, `doc.on.doc`, `pin`, and `xmark`.

- [ ] **Step 5: Build and manually exercise transitions**

Run: `swift build -j 1`

Expected: build succeeds. Start the app and verify drag → edit → resize → capture, window hover → select, Esc cancel, and Return capture.

```bash
git add Sources/SnapSail/SelectionOverlay.swift Sources/SnapSail/CaptureCoordinator.swift
git commit -m "feat: rebuild Xnip-style capture overlay"
```

### Task 5: Smooth scrolling preview

**Files:**
- Rewrite: `Sources/SnapSail/ScrollCaptureController.swift`

- [ ] **Step 1: Throttle preview rendering**

Track `lastPreviewUpdate`. Call `stitcher.makeImage()` only when at least 500 ms elapsed, on first frame, or on finish. Continue processing accepted frames without rebuilding the complete image.

- [ ] **Step 2: Replace the large panel with a narrow material card**

Use a 248×360 borderless floating panel with rounded material background, a 208×250 preview, a pill status label, and two icon buttons. Position it 12 points outside the selection and flip sides when necessary.

- [ ] **Step 3: Add status colors and preserve responsiveness**

Use green for appended frames, secondary gray for waiting, orange for paused, and blue for completion. Keep one processing frame in flight and skip timer ticks while processing.

- [ ] **Step 4: Build and commit**

Run: `swift build -j 1`

Expected: build succeeds without warnings.

```bash
git add Sources/SnapSail/ScrollCaptureController.swift
git commit -m "perf: polish and throttle scrolling preview"
```

### Task 6: Image-focused editor

**Files:**
- Modify: `Sources/SnapSail/EditorWindowController.swift`
- Modify: `Sources/SnapSail/AnnotationCanvasView.swift`

- [ ] **Step 1: Replace text tool buttons with symbols**

Map tools to SF Symbols: arrow `arrow.up.right`, line `line.diagonal`, rectangle `rectangle`, ellipse `circle`, pen `pencil.tip`, text `textformat`, highlight `highlighter`, pixelate `eye.slash`, number `number.circle`. Use `SymbolButton` and tooltips.

- [ ] **Step 2: Restyle editor layout**

Use a 48-point material toolbar, dark neutral canvas surround, 24-point image margins, and a 52-point footer. Place Undo/Redo/Color/Line Width on the left and Pin/Copy/Save on the right. Save is the blue primary button.

- [ ] **Step 3: Build and commit**

Run: `swift build -j 1`

Expected: build succeeds and editor opens with a consistent toolbar.

```bash
git add Sources/SnapSail/EditorWindowController.swift Sources/SnapSail/AnnotationCanvasView.swift
git commit -m "feat: redesign annotation editor"
```

### Task 7: Xnip-style preferences and menu

**Files:**
- Rewrite: `Sources/SnapSail/SettingsWindowController.swift`
- Modify: `Sources/SnapSail/MenuBarController.swift`

- [ ] **Step 1: Build top icon tabs**

Create a 74-point top toolbar with General, Capture, Scrolling, Export, and Shortcuts icon tabs. Keep the window at 720×600 and switch page views without resizing the window.

- [ ] **Step 2: Build centered form rows**

Use a 140-point right-aligned label column and a 360-point control column. Group related checkboxes and auxiliary descriptions, use consistent 30-point controls, and keep 16-point row spacing.

- [ ] **Step 3: Correct menu shortcut presentation**

Use Command-Shift only for the three capture items, Command-H for history, and Command-comma for settings. Add template SF Symbols to capture, history, and settings menu items.

- [ ] **Step 4: Build and commit**

Run: `swift build -j 1`

Expected: build succeeds without warnings.

```bash
git add Sources/SnapSail/SettingsWindowController.swift Sources/SnapSail/MenuBarController.swift
git commit -m "feat: match Xnip preferences styling"
```

### Task 8: Full verification and packaging

**Files:**
- Modify: `README.md` only if shortcuts or interaction instructions changed.

- [ ] **Step 1: Run automated verification**

```bash
swift test -j 1
swift build -j 1
git diff --check
```

Expected: all tests pass, debug build succeeds without warnings, and diff check is clean.

- [ ] **Step 2: Package and verify the app**

```bash
zsh Scripts/build-app.sh
plutil -lint build/SnapSail.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 build/SnapSail.app
```

Expected: release build succeeds, plist is OK, and the app satisfies its designated requirement.

- [ ] **Step 3: Run the app and verify the interaction matrix**

Verify area capture, region resize, window hover, scrolling capture, Copy, Pin, Save, annotation, history, settings tabs, and global shortcuts. Confirm the process stays alive after opening and closing every window.

- [ ] **Step 4: Commit final verification changes**

```bash
git add README.md Sources Tests
git commit -m "feat: finish Xnip-style SnapSail redesign"
```
