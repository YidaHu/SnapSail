# Session Handoff

No feature is currently in progress. `fix-001` was completed and manually verified in WPS.

## Resume Checklist

1. Run `pwd` and confirm the repository is `SnapSail`.
2. Read `AGENTS.md` completely.
3. Inspect `git status --short --branch` and recent commits.
4. Run `./init.sh` and report any baseline failure before changing code.
5. Read `feature_list.json` and `progress.md`.
6. Resume only the feature referenced by `active_feature`, or create one entry for the user's current task.

## Handoff Template

Replace the sections below whenever a session ends with unfinished or risky work.

### Active Feature

- ID and name: none
- Status: idle
- Acceptance criteria: none

### Completed This Session

- Added pre-activation frozen desktop capture for area screenshots.
- Added Retina and negative-origin multi-display crop geometry.
- Restored frozen pixels inside the selection after clearing the dim layer.
- Added capture ordering, geometry, compositing, and overlay safety regression tests.
- Built, signed, verified, and launched `build/SnapSail.app`.

### Remaining Work

1. None.

### Exact Restart Commands

```bash
swift test -j 1 --filter SelectionOverlaySafetyTests
./init.sh
```

### Verification Run

- Command:
- Result: `./init.sh --release` passed 62 tests; signed app and metadata verification passed.
- Manual environment and result: WPS area capture retained the filter dropdown in both preview and final image.

### Files Changed

- `Sources/SnapSail/CaptureCoordinator.swift`
- `Sources/SnapSail/CaptureService.swift`
- `Sources/SnapSail/FrozenBackgroundPainter.swift`
- `Sources/SnapSail/SelectionOverlay.swift`
- `Sources/SnapSailCore/FrozenCaptureGeometry.swift`
- `Tests/SnapSailCoreTests/FrozenBackgroundPainterTests.swift`
- `Tests/SnapSailCoreTests/FrozenCaptureGeometryTests.swift`
- `Tests/SnapSailCoreTests/SelectionOverlaySafetyTests.swift`

### Decisions, Risks, and Blockers

- Decision: preserve current focus/input behavior and freeze pixels before activation instead of removing key-window activation.
- Risk: frozen area captures temporarily retain one full-resolution image per display until selection completes.
- Blocker: none.

### Working Tree Notes

- Expected branch: `main`
- Expected modified/untracked files: Harness files plus the focused capture implementation and tests.
- Do not overwrite: unrelated user changes if any appear during the session.
