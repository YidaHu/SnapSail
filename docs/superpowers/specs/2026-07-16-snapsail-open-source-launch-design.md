# SnapSail Open Source Launch Design

## Objective

Publish SnapSail as a polished public GitHub project under `YidaHu/SnapSail`, using the local Git identity `YidaHu <huyidada@gmail.com>`, with documentation strong enough for a new macOS developer to understand, build, trust, and contribute to the app.

## Repository presentation

The repository should lead with one clear promise: a fast, native, local-first screenshot tool for macOS with area capture, window capture, scrolling capture, inline annotation, pinning, and bilingual preferences. The README will be English-first for GitHub reach, while keeping concise Chinese guidance where it helps the existing audience.

The README structure is:

1. Product name, positioning line, badges, and a compact feature summary.
2. A truthful capability overview with no claim of notarized binary distribution.
3. Feature table covering capture, scrolling, annotation, pinning, shortcuts, export, history, language, and privacy.
4. Requirements, permission explanation, build, run, and packaging commands.
5. First-use workflow and separate scrolling-capture guidance.
6. Settings, storage locations, export behavior, keyboard shortcuts, architecture, and project layout.
7. Testing, troubleshooting, privacy, roadmap, contributing, and license.

## Public repository hygiene

- Add an MIT license owned by YidaHu.
- Keep generated `build/` and Swift build artifacts out of Git.
- Scan tracked files for credentials, tokens, private endpoints, and machine-only build output before publishing.
- Validate with all Swift tests, a Release app build, plist validation, and code-signature verification.
- Create a public GitHub repository named `SnapSail`, attach it as `origin`, push `main`, and verify repository visibility and default branch through GitHub.

## Boundaries

- The launch distributes source code, not a notarized downloadable app.
- The README must not claim App Store availability or Apple notarization.
- Screen Recording permission remains required by macOS.
- Current local signing is for stable development permission identity, not public distribution signing.

## Success criteria

- `https://github.com/YidaHu/SnapSail` is public and contains the complete clean `main` branch.
- The README supports first build without hidden steps.
- The Git identity is locally configured as requested.
- Tests and Release packaging pass before the first push.

