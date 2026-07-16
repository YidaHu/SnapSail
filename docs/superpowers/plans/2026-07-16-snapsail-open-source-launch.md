# SnapSail Open Source Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish SnapSail as a clean public GitHub repository with complete developer and product documentation.

**Architecture:** Keep the existing Swift/AppKit source unchanged except for repository presentation files. Treat README, license, Git hygiene, verification, and GitHub creation as separate gates so public state is only created after local validation succeeds.

**Tech Stack:** Swift 5.7, AppKit, Swift Package Manager, shell build scripts, Git, GitHub CLI.

---

### Task 1: Repository documentation and hygiene

**Files:**
- Modify: `README.md`
- Create: `LICENSE`
- Create: `.gitignore`

- [ ] Replace the short README with the complete product, setup, usage, architecture, testing, troubleshooting, privacy, contributing, and roadmap guide defined in the design spec.
- [ ] Add an MIT license for `Copyright (c) 2026 YidaHu`.
- [ ] Ignore `.build/`, `build/`, `.swiftpm/`, Xcode user data, `.DS_Store`, and local environment files without ignoring tracked source assets.
- [ ] Run `git diff --check` and scan tracked text with `rg -n '(gho_|github_pat_|BEGIN .*PRIVATE KEY|api[_-]?key|secret)'`.
- [ ] Commit with `docs: prepare SnapSail for open source`.

### Task 2: Local release verification

**Files:**
- Verify: `Package.swift`
- Verify: `Scripts/build-app.sh`
- Verify: `build/SnapSail.app`

- [ ] Run `swift test -j 1` and require zero failures.
- [ ] Run `zsh Scripts/build-app.sh` and require a Release app at `build/SnapSail.app`.
- [ ] Run `plutil -lint build/SnapSail.app/Contents/Info.plist`.
- [ ] Run `codesign --verify --deep --strict --verbose=2 build/SnapSail.app`.

### Task 3: GitHub publication

**Files:**
- Configure: local Git repository metadata and remote.

- [ ] Set local Git identity to `user.name=YidaHu` and `user.email=huyidada@gmail.com`.
- [ ] Confirm `gh auth status` uses the `YidaHu` account and confirm `YidaHu/SnapSail` does not already exist.
- [ ] Create the public repository with GitHub CLI, add `origin`, and push `main`.
- [ ] Verify repository visibility, default branch, description, and pushed commit with `gh repo view YidaHu/SnapSail --json ...`.

