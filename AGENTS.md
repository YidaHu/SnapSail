# SnapSail Agent Harness

SnapSail is a native, local-first macOS screenshot workspace built with Swift 5.7+, Swift Package Manager, and AppKit.

## Startup Workflow

Before changing code:

1. Confirm the repository root with `pwd` and inspect `git status --short --branch`.
2. Read this file completely.
3. Read the relevant sections of `README.md`, especially Architecture, Testing, and Contributing.
4. Run `./init.sh`; if the baseline fails, report it before adding new scope.
5. Read `feature_list.json`, then `progress.md` and `session-handoff.md`.
6. Review recent context with `git log --oneline -5`.
7. Select one active feature. If none exists, add the user's current task to `feature_list.json` before implementation.

## Project Map

- `Sources/SnapSailCore/`: reusable logic that does not require AppKit UI.
- `Sources/SnapSail/`: AppKit application, capture workflows, overlays, menu bar, and settings.
- `Tests/SnapSailCoreTests/`: XCTest regression suite for both targets.
- `Resources/Info.plist`: app metadata and privacy descriptions.
- `Scripts/build-app.sh`: Release app packaging and stable local signing.
- `Scripts/run-app.sh`: build and launch helper.
- `README.md`: product behavior, architecture, build, and testing source of truth.

## Working Rules

- Work on one feature or bug at a time. Do not combine unrelated cleanup.
- Preserve existing user changes; inspect the diff before editing overlapping files.
- Add or update a regression test before changing behavior whenever practical.
- Put platform-independent capture logic in `SnapSailCore`; keep AppKit dependencies in `SnapSail`.
- Keep the app local-first: do not add analytics, uploads, accounts, or backend dependencies without explicit approval.
- Do not alter privacy permissions, signing identity, bundle identity, or persisted user data without calling out the impact.
- Do not launch the app or perform live capture tests unless they are relevant to the task.
- Do not commit, push, publish, or create a release unless the user explicitly asks.
- Record durable task state in the repository files below, not in an agent-only memory.

## Capture Safety

Selection overlays run above normal windows and can block desktop input if orphaned.

- Treat overlay lifecycle, capture reentrancy, and teardown changes as high risk.
- Keep a single live selection overlay per capture coordinator.
- For overlay changes, run `swift test --filter SelectionOverlaySafetyTests` before the full suite.
- If a live test leaves the desktop gray or unclickable, restore operability first by terminating the stale SnapSail process, then continue diagnosis.
- A live capture check must verify both creation and teardown across every connected display.

## State Files

- `feature_list.json`: source of truth for task scope, dependencies, status, and verification evidence.
- `progress.md`: concise cross-session status and decisions; update it after meaningful work.
- `session-handoff.md`: exact restart instructions for unfinished or risky work.
- `init.sh`: standard environment and verification entry point.

Allowed feature states are `backlog`, `in-progress`, `blocked`, and `done`. Exactly zero or one feature may be `in-progress`, and `active_feature` must match it.

## Verification

```bash
# Standard startup and full automated test suite
./init.sh

# Focused overlay safety regression
swift test -j 1 --filter SelectionOverlaySafetyTests

# Release packaging and signature verification
./init.sh --release
```

Run focused tests while iterating, then `./init.sh` before claiming code work is complete. Use `./init.sh --release` for packaging, signing, Info.plist, or release-build changes. UI behavior changes also require a concise manual verification record.

## Definition of Done

A task is done only when:

- [ ] The requested behavior and acceptance criteria are satisfied.
- [ ] Relevant regression coverage exists or the reason it cannot exist is recorded.
- [ ] `./init.sh` passes from the repository root.
- [ ] Release-affecting work passes `./init.sh --release`.
- [ ] Required manual macOS checks are recorded with environment and result.
- [ ] `feature_list.json` contains concrete evidence and correct dependencies/status.
- [ ] `progress.md` and, when needed, `session-handoff.md` allow a clean restart.
- [ ] `git diff --check` passes and the final diff contains no unrelated edits.

## End of Session

1. Re-run verification proportional to the changes.
2. Inspect `git status --short` and `git diff --check`.
3. Update the active feature status and evidence in `feature_list.json`.
4. Update `progress.md` with completed work, decisions, risks, and the next action.
5. If work is unfinished, fill in `session-handoff.md` with exact commands and restart steps.
6. Leave generated build output untracked and the repository restartable via `./init.sh`.

## Escalation

Ask before proceeding when requirements would change product privacy, introduce a service dependency, migrate persisted data, change signing/release identity, or broaden the task beyond the active feature. For an ambiguous implementation detail inside the active feature, prefer the smallest reversible change consistent with existing tests and README behavior.
