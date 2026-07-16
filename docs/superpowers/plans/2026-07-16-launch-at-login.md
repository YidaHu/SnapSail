# Launch at Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bilingual General-settings switch that controls SnapSail's real macOS login item.

**Architecture:** Isolate ServiceManagement behind a small launch-at-login controller with an injectable service protocol. Keep Settings responsible only for rendering and user interaction, and derive state from macOS instead of persisting a duplicate preference.

**Tech Stack:** Swift 5.7, AppKit, ServiceManagement, XCTest, Swift Package Manager.

---

### Task 1: Add failing settings regression test

**Files:**
- Create: `Tests/SnapSailCoreTests/LaunchAtLoginSettingsTests.swift`

- [ ] Instantiate `SettingsWindowController` with isolated preferences.
- [ ] Recursively search its window for `settings.launchAtLogin` and require an enabled checkbox.
- [ ] Run `swift test -j 1 --filter LaunchAtLoginSettingsTests`; require FAIL because the control is absent.

### Task 2: Implement system login-item controller

**Files:**
- Create: `Sources/SnapSail/LaunchAtLoginController.swift`
- Create: `Tests/SnapSailCoreTests/LaunchAtLoginControllerTests.swift`

- [ ] Define disabled, enabled, requires-approval, and unavailable states.
- [ ] Wrap `SMAppService.mainApp` behind an injectable service protocol.
- [ ] Verify register, unregister, no-op, approval, and unavailable behavior using a fake service.
- [ ] Run `swift test -j 1 --filter LaunchAtLoginControllerTests`; require PASS.

### Task 3: Add bilingual General-settings switch

**Files:**
- Modify: `Sources/SnapSailCore/AppLocalization.swift`
- Modify: `Sources/SnapSail/SettingsWindowController.swift`
- Modify: `Tests/SnapSailCoreTests/AppLocalizationTests.swift`

- [ ] Add English and Simplified Chinese strings for the switch and status/error hints.
- [ ] Add the checkbox to the General page with identifier `settings.launchAtLogin`.
- [ ] Load system state whenever settings open, call the controller only when this checkbox changes, and restore state after errors.
- [ ] Run the launch-at-login and localization test groups; require PASS.

### Task 4: Verify and publish

**Files:**
- Verify only.

- [ ] Run `swift test -j 1` and require all tests to pass.
- [ ] Run `zsh Scripts/build-app.sh`, `plutil -lint build/SnapSail.app/Contents/Info.plist`, and `codesign --verify --deep --strict build/SnapSail.app`.
- [ ] Open the General settings page and verify the new switch without enabling it automatically.
- [ ] Commit and push `main`, then confirm local and remote commit hashes match.
