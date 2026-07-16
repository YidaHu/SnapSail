# Product Page Toolbar Visual Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the native capture toolbar visually match the polished toolbar illustration on the SnapSail product page without changing capture behavior.

**Architecture:** Keep AppKit ownership in `InlineCaptureToolbar`, move reusable visual constants into `SnapSailStyle`, and expose stable accessibility identifiers for view-level regression tests. Preserve every existing callback and annotation tool.

**Tech Stack:** Swift 5.7, AppKit, Core Animation, XCTest, Swift Package Manager.

---

### Task 1: Lock the visual contract with failing tests

**Files:**
- Create: `Tests/SnapSailCoreTests/InlineCaptureToolbarTests.swift`
- Modify: `Sources/SnapSail/InlineCaptureToolbar.swift`
- Modify: `Sources/SnapSail/DesignSystem.swift`

- [ ] **Step 1: Write the failing view tests**

Add tests that instantiate `InlineCaptureToolbar` and assert:

```swift
XCTAssertEqual(InlineCaptureToolbar.preferredSize, CGSize(width: 744, height: 62))
XCTAssertEqual(toolbar.layer?.cornerRadius, 22)
XCTAssertEqual(button("capture.copy").layer?.backgroundColor, SnapSailStyle.accent.cgColor)
XCTAssertEqual(button("capture.copy").contentTintColor, .white)
```

Select the rectangle button with `performClick(nil)` and assert its background is `SnapSailStyle.captureToolbarSelectionBackground` and its tint is `SnapSailStyle.accent`. Assert the first two tool buttons have a 4pt horizontal gap.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `swift test -j 1 --filter InlineCaptureToolbarTests`

Expected: the size/corner assertions fail and identifier lookups fail because the native toolbar still uses the old compact layout.

- [ ] **Step 3: Add shared style tokens**

Extend `SnapSailStyle` with:

```swift
static let captureToolbarSize = CGSize(width: 744, height: 62)
static let captureToolbarCornerRadius: CGFloat = 22
static let captureToolbarSelectionBackground = NSColor(calibratedRed: 0.906, green: 0.945, blue: 1, alpha: 1)
static let captureToolbarHoverBackground = NSColor(calibratedWhite: 0.94, alpha: 1)
static let captureToolbarDestructiveHoverBackground = NSColor.systemRed.withAlphaComponent(0.10)
```

- [ ] **Step 4: Rebuild the toolbar layout**

Use 12pt outer padding, `40 × 42 pt` buttons, 4pt gaps, and two 8pt separator regions. Add identifiers in the form `capture.tool.rectangle`, `capture.color`, `capture.undo`, `capture.redo`, `capture.cancel`, `capture.scroll`, `capture.save`, and `capture.copy`.

- [ ] **Step 5: Implement explicit button roles**

Replace `isEmphasized` with a role enum containing `.standard`, `.destructive`, and `.primary`. Render `.primary` as blue/white in normal and hover states, `.destructive` as red with a pale red hover background, and selected tools as pale blue/system blue.

- [ ] **Step 6: Run the focused and complete tests**

Run: `swift test -j 1 --filter InlineCaptureToolbarTests`

Expected: all toolbar tests pass.

Run: `swift test -j 1`

Expected: all SnapSail tests pass with zero failures.

- [ ] **Step 7: Build the production app and commit**

Run: `zsh Scripts/build-app.sh`

Expected: `build/SnapSail.app` is produced successfully.

```bash
git add Sources/SnapSail/DesignSystem.swift Sources/SnapSail/InlineCaptureToolbar.swift Tests/SnapSailCoreTests/InlineCaptureToolbarTests.swift
git commit -m "feat: match capture toolbar to product page"
```

