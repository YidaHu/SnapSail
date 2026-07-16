# Capture Reliability and Shadow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the first drag work on every display, make Download open a destination chooser, and add a visible Xnip-style shadow to live and exported area captures.

**Architecture:** Put screen-local overlay placement and screenshot-shadow rendering in testable `SnapSailCore` utilities. Keep per-screen AppKit windows, but construct them with local content coordinates and accept first mouse events. Route Download to the existing native save panel after copying the image.

**Tech Stack:** Swift 5.7, AppKit, Core Graphics, XCTest, Swift Package Manager.

---

### Task 1: Correct per-screen overlay placement

**Files:**
- Create: `Sources/SnapSailCore/OverlayScreenGeometry.swift`
- Create: `Tests/SnapSailCoreTests/OverlayScreenGeometryTests.swift`
- Modify: `Sources/SnapSail/SelectionOverlay.swift`

- [ ] **Step 1: Write failing placement tests**

Test that `OverlayScreenGeometry.localContentRect(for:)` returns origin `(0, 0)` and preserves size for main `(0,0,1680,1050)`, left `(-1080,-8,1080,1920)`, and upper `(0,1050,1920,1080)` screen frames.

- [ ] **Step 2: Verify RED**

Run: `swift test -j 1 --filter OverlayScreenGeometryTests`

Expected: compilation fails because `OverlayScreenGeometry` does not exist.

- [ ] **Step 3: Implement local geometry and first-click handling**

Create the utility, pass its local rectangle to `NSWindow(...screen:)`, override `acceptsFirstMouse(for:)` to return `true`, call `NSApplication.shared.activate(ignoringOtherApps: true)`, and make the overlay under the current mouse pointer key while leaving all overlay windows visible.

- [ ] **Step 4: Verify and commit**

Run: `swift test -j 1 --filter OverlayScreenGeometryTests && swift build -j 1`

Expected: placement tests and app build pass.

```bash
git add Sources/SnapSailCore/OverlayScreenGeometry.swift Tests/SnapSailCoreTests/OverlayScreenGeometryTests.swift Sources/SnapSail/SelectionOverlay.swift
git commit -m "fix: capture on first drag across displays"
```

### Task 2: Native Download destination chooser

**Files:**
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`
- Modify: `Sources/SnapSail/ImageUtilities.swift`

- [ ] **Step 1: Route Download to the save panel**

For `.save`, call `recordAndCopy(image)` and then `ImageExporter.presentSavePanel(for:preferences:window:nil)`. Remove the silent `ImageExporter.save` call from this action while retaining automatic save only when the separate `saveAfterCapture` preference is enabled.

- [ ] **Step 2: Preserve the last chosen directory**

Keep the existing successful-save assignment `preferences.saveDirectory = url.deletingLastPathComponent()`. Cancelling returns without alerts and leaves the clipboard unchanged.

- [ ] **Step 3: Build and commit**

Run: `swift build -j 1`

Expected: build passes; no call to direct `save` remains in the `.save` switch case.

```bash
git add Sources/SnapSail/CaptureCoordinator.swift Sources/SnapSail/ImageUtilities.swift
git commit -m "fix: choose a destination when downloading captures"
```

### Task 3: Exported screenshot shadow

**Files:**
- Create: `Sources/SnapSailCore/ScreenshotShadowRenderer.swift`
- Create: `Tests/SnapSailCoreTests/ScreenshotShadowRendererTests.swift`
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`
- Modify: `Sources/SnapSail/SelectionOverlay.swift`

- [ ] **Step 1: Write failing shadow tests**

Render a 100×60 opaque patterned image with 20-pixel padding. Assert output is 140×100, corner alpha is zero, a pixel just outside the image has non-zero alpha, and a center pixel matches the source.

- [ ] **Step 2: Verify RED**

Run: `swift test -j 1 --filter ScreenshotShadowRendererTests`

Expected: compilation fails because `ScreenshotShadowRenderer` does not exist.

- [ ] **Step 3: Implement exact-pixel shadow compositing**

Use an RGBA bitmap context, a black shadow at 32% opacity, 18-pixel blur, and downward offset. Draw the source into the padded rectangle with the shadow, clear the shadow state, and draw the source again for exact center pixels.

- [ ] **Step 4: Apply shadows to area and scrolling captures**

After annotation rasterization, wrap area results with the renderer. Wrap completed scrolling captures the same way. Do not wrap window captures because Core Graphics already supplies the native window shadow.

- [ ] **Step 5: Strengthen the live glow**

Draw 14-point and 7-point low-alpha blue strokes before the crisp 2-point selection border so the glow remains visible without relying only on `NSShadow`.

- [ ] **Step 6: Verify and commit**

Run: `swift test -j 1 --filter ScreenshotShadowRendererTests && swift build -j 1`

Expected: shadow tests and app build pass.

```bash
git add Sources/SnapSailCore/ScreenshotShadowRenderer.swift Tests/SnapSailCoreTests/ScreenshotShadowRendererTests.swift Sources/SnapSail/CaptureCoordinator.swift Sources/SnapSail/SelectionOverlay.swift
git commit -m "feat: add visible shadows to region captures"
```

### Task 4: Three-display and release verification

**Files:**
- Verify only.

- [ ] **Step 1: Verify actual overlay bounds**

Trigger capture and query WindowServer bounds. Expect overlays at `(0,0,1680,1050)`, `(-1080,-862,1080,1920)`, and `(0,-1080,1920,1080)` rather than doubled origins.

- [ ] **Step 2: Exercise first drag and Download**

Perform one drag on each display. Verify each produces a capture without a preparatory click. Press Download and verify `NSSavePanel` appears; cancel and verify the clipboard still contains an image.

- [ ] **Step 3: Run clean release verification**

Run: `swift package clean && swift test -j 1 && zsh Scripts/build-app.sh && plutil -lint build/SnapSail.app/Contents/Info.plist && codesign --verify --deep --strict --verbose=2 build/SnapSail.app`

Expected: all tests, release packaging, plist validation, and persistent-signature validation pass.

