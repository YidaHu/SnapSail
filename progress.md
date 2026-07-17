# Session Progress

## Current State

- Last updated: 2026-07-17
- Active feature: none
- Repository baseline: `swift test -j 1` passes 55 tests
- Working tree at harness creation: clean on `main` before harness files were added

## Completed

- Added the initial SnapSail agent harness covering instructions, state, verification, scope, and session lifecycle.
- Kept `README.md` as the product and architecture source of truth instead of duplicating derivable project knowledge.
- Defined standard verification through `./init.sh` and release verification through `./init.sh --release`.
- Completed `fix-001`: WPS filter dropdowns remain visible in both the area-selection preview and final screenshot.

## In Progress

- None.

## Next

1. Add the next user-requested feature or bug to `feature_list.json` before implementation.

## Blockers and Risks

- None currently known.
- Live selection-overlay tests remain high risk because orphaned full-screen windows can block desktop input; follow the safety procedure in `AGENTS.md`.

## Decisions

- Use a minimal root-level harness so Codex and other repository-aware coding agents discover it without extra configuration.
- Do not pre-populate roadmap items as committed work; `README.md` explicitly describes them as directional.
- Keep expensive signed Release packaging opt-in while making the full automated test suite the default startup health check.

## Evidence

- Baseline command: `swift test -j 1`
- Baseline result: 55 tests passed, 0 failures on 2026-07-17.
- Harness command: `./init.sh`
- Harness result: package validation and all 55 tests passed, 0 failures on 2026-07-17.
- Fix verification: `./init.sh --release` passed 62 tests, built the signed app, linted Info.plist, and passed strict codesign verification.
- Runtime verification: the new `build/SnapSail.app` launched as PID 46744 with zero idle overlay windows.
- Review verification: no remaining Critical or Important issues after fixing frozen-selection compositing.
- Manual verification: WPS filter dropdown remained visible in both the preview and final image.

## Notes for the Next Session

`fix-001` is complete. The new SnapSail build remains running; start the next task from an idle Harness state.
