# Inline Capture Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make area capture look and behave like the supplied Xnip reference, with inline annotations and one-click copy/save/pin completion instead of opening a separate editor.

**Architecture:** Add a platform-neutral annotation history model to `SnapSailCore`, an AppKit renderer that draws the same annotation snapshot both in the overlay and into the final image, and a dedicated capsule toolbar owned by the overlay. Extend `SelectionOutcome` so the coordinator receives annotations and performs direct completion actions.

**Tech Stack:** Swift 5.7, AppKit, Core Graphics, Core Image, XCTest, Swift Package Manager.

---

## File map

- `Sources/SnapSailCore/InlineAnnotationModel.swift`: normalized annotation geometry and undo/redo history.
- `Tests/SnapSailCoreTests/InlineAnnotationModelTests.swift`: model regression tests.
- `Sources/SnapSail/InlineAnnotationRenderer.swift`: overlay drawing and final-image compositing.
- `Sources/SnapSail/InlineCaptureToolbar.swift`: Xnip-style white capsule, tool selection, and completion callbacks.
- `Sources/SnapSail/SelectionOverlay.swift`: routes mouse input between selection editing and annotations; positions the measurement pill, pin button, and capsule.
- `Sources/SnapSail/CaptureCoordinator.swift`: captures once, composites annotations, copies/saves/pins directly.
- `Sources/SnapSail/DesignSystem.swift`: opaque capsule and circular completion button styles.

### Task 1: Normalized annotation history

**Files:**
- Create: `Sources/SnapSailCore/InlineAnnotationModel.swift`
- Create: `Tests/SnapSailCoreTests/InlineAnnotationModelTests.swift`

- [ ] **Step 1: Write failing tests**

Add tests that construct `InlineAnnotationHistory`, commit two annotations, undo one, redo it, and assert a new commit clears the redo stack. Add a normalization test using `InlineAnnotation.normalizedPoint(_:in:)` for a point at the center of a 400×200 selection.

- [ ] **Step 2: Verify RED**

Run: `swift test -j 1 --filter InlineAnnotationModelTests`

Expected: compilation fails because `InlineAnnotationHistory` and `InlineAnnotation` do not exist.

- [ ] **Step 3: Implement the model**

Define `InlineAnnotationTool`, `InlineAnnotationColor`, `InlineAnnotation`, and `InlineAnnotationHistory`. Store start/end/freehand points normalized to 0...1, a line width in screen points, optional text, and marker number. Expose `commit`, `undo`, `redo`, `canUndo`, and `canRedo`.

- [ ] **Step 4: Verify GREEN and commit**

Run: `swift test -j 1 --filter InlineAnnotationModelTests`

Expected: all focused tests pass.

```bash
git add Sources/SnapSailCore/InlineAnnotationModel.swift Tests/SnapSailCoreTests/InlineAnnotationModelTests.swift
git commit -m "feat: add inline annotation history"
```

### Task 2: Shared annotation renderer

**Files:**
- Create: `Sources/SnapSail/InlineAnnotationRenderer.swift`

- [ ] **Step 1: Implement overlay rendering**

Create `InlineAnnotationRenderer.draw(_:draft:in:)`. Map normalized points into the current selection rectangle and draw rectangle, ellipse, line, arrow, pen, highlight, text, numbered marker, and a pixelation preview grid.

- [ ] **Step 2: Implement final compositing**

Create `InlineAnnotationRenderer.render(base:annotations:selectionPointSize:) -> CGImage?`. Draw the base image at native pixel size, scale annotation widths by the image-to-selection ratio, and use `CIPixellate` clipped to pixelation rectangles.

- [ ] **Step 3: Build and commit**

Run: `swift build -j 1`

Expected: the app target builds.

```bash
git add Sources/SnapSail/InlineAnnotationRenderer.swift
git commit -m "feat: render inline capture annotations"
```

### Task 3: Xnip-style inline overlay

**Files:**
- Create: `Sources/SnapSail/InlineCaptureToolbar.swift`
- Modify: `Sources/SnapSail/DesignSystem.swift`
- Modify: `Sources/SnapSail/SelectionOverlay.swift`

- [ ] **Step 1: Build the capsule toolbar**

Create an opaque white rounded capsule with 40-point symbol buttons. Add rectangle, ellipse, line, arrow, pen, pixelate, text, number, highlight, color-cycle, undo, redo, cancel, scrolling, direct save, and copy/finish controls. Publish callbacks instead of capture logic.

- [ ] **Step 2: Match measurement and pin placement**

Replace the small size label with a centered `width  lock  height  pt` blue pill. Add a 44-point white circular pin button just outside the selection's upper-right corner. Position the 700-point capsule below the selection and flip it above when needed.

- [ ] **Step 3: Route annotation input**

When a tool is active and mouse-down occurs inside the region, create a normalized draft. Commit on mouse-up; number commits on click; text creates an inline `NSTextField` and commits on Return. Keep selection move/resize behavior when no tool is active.

- [ ] **Step 4: Return immutable annotation snapshots**

Extend `SelectionAction` with `save`. Extend `SelectionOutcome` with `[InlineAnnotation]` and the selected region's point size. Keep window capture annotations empty.

- [ ] **Step 5: Build and commit**

Run: `swift build -j 1`

Expected: the capture overlay target builds with no warnings.

```bash
git add Sources/SnapSail/InlineCaptureToolbar.swift Sources/SnapSail/DesignSystem.swift Sources/SnapSail/SelectionOverlay.swift
git commit -m "feat: add Xnip-style inline capture toolbar"
```

### Task 4: Direct completion workflow

**Files:**
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`

- [ ] **Step 1: Composite exactly once**

After the overlay closes, capture the clean region, render its annotation snapshot, and pass the final image to the requested action. Do not call `presentEditor` for new area or window captures.

- [ ] **Step 2: Implement zero-dialog actions**

For default/copy: add history when enabled, copy, play the sound, and finish. For save: perform the default/copy behavior and call `ImageExporter.save(_:to:preferences:)` using `preferences.saveDirectory` without `NSSavePanel`. For pin: copy, add history, pin, and finish. For scrolling capture completion: copy directly and add history.

- [ ] **Step 3: Verify behavior and commit**

Run: `swift test -j 1 && swift build -j 1`

Expected: all tests pass and the app builds.

```bash
git add Sources/SnapSail/CaptureCoordinator.swift
git commit -m "feat: complete screenshots without editor dialogs"
```

### Task 5: Release verification

**Files:**
- Verify only.

- [ ] **Step 1: Run clean automated verification**

Run: `swift package clean && swift test -j 1 && zsh Scripts/build-app.sh`

Expected: all tests pass and `build/SnapSail.app` is created with the persistent signing identity.

- [ ] **Step 2: Verify package and launch**

Run: `plutil -lint build/SnapSail.app/Contents/Info.plist && codesign --verify --deep --strict --verbose=2 build/SnapSail.app && open build/SnapSail.app`

Expected: plist and signature validate and the menu-bar process remains running.

- [ ] **Step 3: Exercise the reference workflow**

Verify region drag, size pill, capsule positioning, one annotation with undo/redo, Return copy/finish, direct save without a panel, pin, scrolling capture, and Escape cancellation.

