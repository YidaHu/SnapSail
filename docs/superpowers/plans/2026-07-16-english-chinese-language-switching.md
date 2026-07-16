# English and Simplified Chinese Language Switching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent English/Chinese language selector that refreshes SnapSail's visible interface immediately.

**Architecture:** Keep language data and key completeness in `SnapSailCore`, persist the chosen language in `AppPreferences`, and route app UI text through one `L10n` facade. Rebuild the menu and Preferences pages when the user switches language; all other newly presented UI reads the current language.

**Tech Stack:** Swift 5.7, AppKit, UserDefaults, XCTest, Swift Package Manager.

---

### Task 1: Test and Implement Localization Catalog

**Files:**
- Create: `Sources/SnapSailCore/AppLocalization.swift`
- Create: `Tests/SnapSailCoreTests/AppLocalizationTests.swift`

- [ ] Write tests asserting representative English and Chinese strings and that every `AppTextKey` has a non-empty translation in both languages.
- [ ] Run `swift test -j 1 --filter AppLocalizationTests` and confirm it fails because the localization types are missing.
- [ ] Implement `AppLanguage`, `AppTextKey`, and `AppLocalization.text(_:language:)` with complete English and Simplified Chinese catalogs.
- [ ] Run the focused tests and confirm they pass.

### Task 2: Persist Language and Rebuild Primary Chrome

**Files:**
- Create: `Sources/SnapSail/L10n.swift`
- Modify: `Sources/SnapSail/AppPreferences.swift`
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`
- Modify: `Sources/SnapSail/MenuBarController.swift`
- Modify: `Sources/SnapSail/SettingsWindowController.swift`

- [ ] Register and persist `AppLanguage.english` as the default.
- [ ] Add the General-page language popup and save its selection.
- [ ] Rebuild the menu and Preferences pages after a language change while preserving the selected page and shortcut values.
- [ ] Run `swift build -j 1` and confirm the app builds without warnings.

### Task 3: Localize Capture and Supporting UI

**Files:**
- Modify: `Sources/SnapSail/SelectionOverlay.swift`
- Modify: `Sources/SnapSail/InlineCaptureToolbar.swift`
- Modify: `Sources/SnapSail/ShortcutRecorderButton.swift`
- Modify: `Sources/SnapSail/History.swift`
- Modify: `Sources/SnapSail/EditorWindowController.swift`
- Modify: `Sources/SnapSail/CaptureCoordinator.swift`

- [ ] Replace visible embedded strings with localization keys for capture instructions, tooltips, recorder states, history, editor controls, alerts, and pinned-image actions.
- [ ] Run localization tests plus `swift build -j 1` and confirm both pass.

### Task 4: Accessibility and Release Verification

**Files:**
- Modify: `README.md`

- [ ] Use Accessibility to switch to Chinese and verify Preferences plus menu-bar text immediately.
- [ ] Restart SnapSail and verify Chinese persists; switch back to English after verification.
- [ ] Verify F1 can be recorded without modifiers, triggers capture immediately, persists after restart, and can be reset.
- [ ] Verify a pinned screenshot moves on drag and closes without terminating SnapSail.
- [ ] Run the complete test suite, release build, plist validation, signing validation, and `git diff --check`.
- [ ] Document shortcut recording, pinned dragging, and language switching in `README.md`.
