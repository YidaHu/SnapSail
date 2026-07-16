# Custom Shortcuts and Pinned Image Dragging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users record persistent global capture shortcuts and drag pinned screenshots from anywhere on the image.

**Architecture:** Add platform-neutral shortcut and pin-interaction models to `SnapSailCore`, then connect them to `UserDefaults`, Carbon registration, the preferences recorder controls, and the menu bar. Keep pinned-window movement on AppKit's native window-drag API.

**Tech Stack:** Swift 5.7, AppKit, Carbon hotkeys, Core Graphics, UserDefaults, XCTest, Swift Package Manager.

---

### Task 1: Shortcut and Pin Interaction Models

**Files:**
- Create: `Sources/SnapSailCore/KeyboardShortcut.swift`
- Create: `Sources/SnapSailCore/PinInteraction.swift`
- Create: `Tests/SnapSailCoreTests/KeyboardShortcutTests.swift`
- Create: `Tests/SnapSailCoreTests/PinInteractionTests.swift`

- [ ] **Step 1: Write failing model tests**

Test that the three actions default to Command-Shift-2/3/4, formatting produces `⌘ ⇧ 2`, duplicate validation identifies another action using the same combination, and a primary click maps to drag while a double-click maps to close.

- [ ] **Step 2: Verify the tests fail for missing types**

Run: `swift test -j 1 --filter 'KeyboardShortcutTests|PinInteractionTests'`

Expected: compilation fails because `KeyboardShortcut`, `CaptureShortcutAction`, and `PinInteraction` do not exist.

- [ ] **Step 3: Implement minimal core models**

Define `ShortcutModifiers: OptionSet`, `KeyboardShortcut`, and `CaptureShortcutAction` with stable action IDs and defaults. Add `KeyboardShortcut.conflicts(for:among:)`. Define `PinPrimaryClickAction` and `PinInteraction.primaryAction(clickCount:)`.

- [ ] **Step 4: Verify focused tests pass**

Run: `swift test -j 1 --filter 'KeyboardShortcutTests|PinInteractionTests'`

Expected: all focused tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/SnapSailCore/KeyboardShortcut.swift Sources/SnapSailCore/PinInteraction.swift Tests/SnapSailCoreTests/KeyboardShortcutTests.swift Tests/SnapSailCoreTests/PinInteractionTests.swift
git commit -m "feat: model custom capture shortcuts"
```

### Task 2: Persistence and Atomic Hotkey Replacement

**Files:**
- Modify: `Sources/SnapSail/AppPreferences.swift`
- Modify: `Sources/SnapSail/GlobalHotKeyManager.swift`
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`
- Modify: `Sources/SnapSail/MenuBarController.swift`

- [ ] **Step 1: Persist shortcuts per action**

Import `SnapSailCore` in preferences. Register the action defaults and add `shortcut(for:)`, `setShortcut(_:for:)`, and `resetShortcut(for:)` using action-specific key-code, modifier, and display-label keys.

- [ ] **Step 2: Register persisted shortcuts at startup**

Replace the three hard-coded calls in `CaptureCoordinator.start()` with `installHotKeys()`, which builds a fresh `GlobalHotKeyManager`, registers all persisted combinations, and retains it only if every registration succeeds.

- [ ] **Step 3: Replace one shortcut atomically**

Add `replaceShortcut(_:for:) -> Bool`: remember the old shortcut, persist the candidate, reinstall all registrations, and restore/reinstall the old set if Carbon rejects the candidate.

- [ ] **Step 4: Refresh menu equivalents**

Keep references to the three capture menu items in `MenuBarController` and implement `updateShortcuts(_:)` to apply the persisted key labels and AppKit modifier masks after startup and successful replacement.

- [ ] **Step 5: Build and commit**

Run: `swift build -j 1`

Expected: build succeeds.

```bash
git add Sources/SnapSail/AppPreferences.swift Sources/SnapSail/GlobalHotKeyManager.swift Sources/SnapSail/CaptureCoordinator.swift Sources/SnapSail/MenuBarController.swift
git commit -m "feat: persist and reload global shortcuts"
```

### Task 3: Shortcut Recorder UI

**Files:**
- Create: `Sources/SnapSail/ShortcutRecorderButton.swift`
- Modify: `Sources/SnapSail/SettingsWindowController.swift`

- [ ] **Step 1: Add a focused recorder control**

Create an `NSButton` subclass that becomes first responder on click, displays `Press shortcut…`, accepts a modified key event, uses Escape to cancel, and uses Delete/Backspace to propose the action default. It must reject modifier-only or unmodified keys with `NSBeep()`.

- [ ] **Step 2: Replace static shortcut labels**

Change each shortcut row to host a recorder for its `CaptureShortcutAction`. On a proposal, reject duplicates, call the coordinator replacement callback, retain the previous value on failure, and show a concise collision alert.

- [ ] **Step 3: Build and commit**

Run: `swift build -j 1`

Expected: build succeeds without warnings.

```bash
git add Sources/SnapSail/ShortcutRecorderButton.swift Sources/SnapSail/SettingsWindowController.swift Sources/SnapSail/CaptureCoordinator.swift
git commit -m "feat: record shortcuts in preferences"
```

### Task 4: Drag Pinned Screenshots

**Files:**
- Modify: `Sources/SnapSail/EditorWindowController.swift`
- Test: `Tests/SnapSailCoreTests/PinInteractionTests.swift`

- [ ] **Step 1: Route primary clicks through the tested decision**

In `PinImageView.mouseDown`, close for `.close` and call `window?.performDrag(with: event)` for `.drag`. Do not call `super.mouseDown`, because `NSImageView` consumes the background drag.

- [ ] **Step 2: Verify focused tests and build**

Run: `swift test -j 1 --filter PinInteractionTests && swift build -j 1`

Expected: focused tests and application build pass.

- [ ] **Step 3: Commit**

```bash
git add Sources/SnapSail/EditorWindowController.swift
git commit -m "fix: drag pinned screenshots from the image"
```

### Task 5: End-to-End Verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document the new interactions**

Document shortcut recording/reset and single-drag pinned image movement.

- [ ] **Step 2: Verify custom shortcut behavior**

Build and launch the release app. Use Accessibility to open Preferences, record a non-default shortcut, trigger it to open the capture overlay, restart SnapSail, and trigger it again. Restore the default after verification.

- [ ] **Step 3: Verify pinned image dragging**

Create a pinned screenshot, synthesize a single drag inside its image, and confirm the pinned window's global origin changes while its size remains stable.

- [ ] **Step 4: Run complete release checks**

Run:

```bash
swift package clean
swift test -j 1
zsh Scripts/build-app.sh
plutil -lint build/SnapSail.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 build/SnapSail.app
git diff --check
```

Expected: all tests pass, the release app builds, plist and signing checks pass, and the diff check is clean.

- [ ] **Step 5: Commit documentation**

```bash
git add README.md
git commit -m "docs: explain shortcut and pin interactions"
```
