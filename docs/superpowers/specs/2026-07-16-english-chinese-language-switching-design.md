# English and Simplified Chinese Language Switching

## Scope

SnapSail will support two explicitly selectable interface languages: English and Simplified Chinese. The selection is stored locally and remains active after restart.

## Interaction

The General preferences page adds a `Language / 语言` popup with `English` and `简体中文`. Selecting a language immediately rebuilds the menu bar and Preferences window in that language. Capture overlays and other windows created afterward read the current language, so they do not require an application restart.

## Architecture

`SnapSailCore` owns an `AppLanguage` enum, a stable set of localization keys, and complete English/Chinese dictionaries. English is the deterministic fallback for any missing value. `AppPreferences` persists the selected language.

The app target exposes a small `L10n.text(_:)` facade that reads the current preference. UI components use keys rather than embedding user-facing strings. `MenuBarController` can rebuild its menu while preserving callbacks and current shortcuts. `SettingsWindowController` can rebuild its pages while preserving the selected tab and saved values.

The first localization pass covers menu-bar commands, all Preferences pages and hints, capture-overlay instructions and shortcut-recorder messages, history controls, editor actions, save/collision alerts, and pinned-image context actions.

## Testing

- Core tests verify English and Chinese output, English fallback, and dictionary completeness for every key.
- Accessibility verification changes the popup, confirms menu/Preferences text updates immediately, restarts the app, and confirms persistence.
- Existing shortcut, capture, pin-drag, release build, and signing checks remain required.
