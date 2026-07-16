# Compact Capture Chrome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the capture measurement pill and annotation toolbar while preserving all existing actions and interaction behavior.

**Architecture:** Keep geometry tokens in `SnapSailStyle` and component-local layout metrics in `MeasurementPillView` and `InlineCaptureToolbar`. `SelectionOverlayView` consumes each component's preferred size so placement cannot drift from rendering. Add AppKit regression tests that assert the public geometry and loaded SF Symbol sizes.

**Tech Stack:** Swift 5.7, AppKit, XCTest, Swift Package Manager.

---

### Task 1: Lock compact geometry with failing tests

**Files:**
- Modify: `Tests/SnapSailCoreTests/InlineCaptureToolbarTests.swift`
- Create: `Tests/SnapSailCoreTests/MeasurementPillViewTests.swift`

- [ ] Change the toolbar assertions to require `660 × 54 pt`, 19pt corner radius, `36 × 38 pt` buttons, 3pt gaps, and 18pt medium symbols.
- [ ] Add a measurement-pill test requiring `164 × 34 pt`, 14pt numeric labels, 10pt unit text, and a 10pt lock symbol.
- [ ] Run `swift test -j 1 --filter InlineCaptureToolbarTests` and `swift test -j 1 --filter MeasurementPillViewTests`; require failures against the old geometry.

### Task 2: Implement the compact measurement pill

**Files:**
- Modify: `Sources/SnapSail/DesignSystem.swift`
- Modify: `Sources/SnapSail/SelectionOverlay.swift`

- [ ] Add `MeasurementPillView.preferredSize = CGSize(width: 164, height: 34)` and resize its typography, symbol, layout frames, corner radius, and shadow.
- [ ] Construct and position the pill using `preferredSize`; use a 10pt exterior gap and an 8pt interior fallback.
- [ ] Run `swift test -j 1 --filter MeasurementPillViewTests`; require PASS.

### Task 3: Implement the compact toolbar

**Files:**
- Modify: `Sources/SnapSail/DesignSystem.swift`
- Modify: `Sources/SnapSail/InlineCaptureToolbar.swift`
- Modify: `Tests/SnapSailCoreTests/InlineCaptureToolbarTests.swift`

- [ ] Set the toolbar token to `660 × 54 pt` with a 19pt corner radius.
- [ ] Use 10pt outer padding, `36 × 38 pt` buttons, 3pt gaps, 22pt separators, and 18pt icons.
- [ ] Keep the existing symbol names, identifiers, tooltips, states, and callbacks unchanged.
- [ ] Run `swift test -j 1 --filter InlineCaptureToolbarTests`; require PASS.

### Task 4: Verify, inspect, and publish

**Files:**
- Verify only.

- [ ] Run `swift test -j 1` and require all tests to pass.
- [ ] Run `zsh Scripts/build-app.sh`, `plutil -lint build/SnapSail.app/Contents/Info.plist`, and `codesign --verify --deep --strict build/SnapSail.app`.
- [ ] Relaunch `build/SnapSail.app`, trigger F1, draw a real selection, and visually inspect the pill and toolbar.
- [ ] Commit the implementation and push `main`; confirm the local and remote commit hashes match.
