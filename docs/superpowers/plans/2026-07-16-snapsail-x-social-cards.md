# SnapSail X Social Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and export four polished 1600 × 900 SnapSail social cards from one standalone HTML page.

**Architecture:** `social/snapsail-x-cards.html` owns the artboards, embedded styles, and navigation logic without network dependencies. A small shell script opens deterministic capture URLs in headless Google Chrome and writes one PNG per artboard to `social/output/`.

**Tech Stack:** Semantic HTML, embedded CSS, vanilla JavaScript, inline SVG, Google Chrome headless screenshots, shell verification.

---

### Task 1: Standalone social-card gallery

**Files:**
- Create: `social/snapsail-x-cards.html`

- [x] **Step 1: Create the gallery shell and four fixed artboards**

Add one toolbar and four `<article class="artboard" data-card="1..4">` elements. Define `--card-width: 1600px` and `--card-height: 900px`, use a responsive scale wrapper for gallery mode, and use `?capture=1&card=N` to isolate one artboard at its exact dimensions.

- [x] **Step 2: Implement the four visual narratives**

Card 1 contains the subscription point of view and oversized capture frame. Card 2 contains the four-stage daily workflow. Card 3 uses a dark local-privacy composition. Card 4 combines feature windows with the free/open-source conclusion. Use only repository-backed product claims.

- [x] **Step 3: Add deterministic controls**

Add previous/next buttons, four direct selectors, focus mode, and keyboard handlers for ArrowLeft, ArrowRight, 1–4, Escape, and F. In capture mode, suppress animation and page chrome so the PNG output is stable.

- [x] **Step 4: Run static checks**

Run:

```bash
test -s social/snapsail-x-cards.html
test "$(rg -o 'class="artboard' social/snapsail-x-cards.html | wc -l | tr -d ' ')" = "4"
! rg -n 'https?://|TODO|TBD' social/snapsail-x-cards.html
```

Expected: exit 0 with no output from the forbidden-pattern scan.

### Task 2: Screenshot export and visual verification

**Files:**
- Create: `social/capture-cards.sh`
- Create: `social/output/snapsail-x-card-01.png`
- Create: `social/output/snapsail-x-card-02.png`
- Create: `social/output/snapsail-x-card-03.png`
- Create: `social/output/snapsail-x-card-04.png`

- [x] **Step 1: Add a repeatable Chrome capture script**

The script resolves the HTML file to an absolute `file://` URL, recreates `social/output`, and calls `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` in headless mode with `--window-size=1600,900`, `--force-device-scale-factor=1`, and a different `card=N` query for every screenshot.

- [x] **Step 2: Export all four cards**

Run:

```bash
zsh social/capture-cards.sh
```

Expected: four PNG paths are printed and Chrome exits successfully.

- [x] **Step 3: Verify image geometry**

Run:

```bash
sips -g pixelWidth -g pixelHeight social/output/*.png
```

Expected: every output reports `pixelWidth: 1600` and `pixelHeight: 900`.

- [x] **Step 4: Inspect each rendered image**

Open all four PNGs and check headline legibility, safe margins, clipping, layering, visual balance, and consistency with the SnapSail product page. Patch the HTML and re-run the capture script until all four pass.

- [x] **Step 5: Run repository verification and commit**

Run:

```bash
git diff --check
zsh social/capture-cards.sh
sips -g pixelWidth -g pixelHeight social/output/*.png
```

Expected: no whitespace errors, four successful captures, and four 1600 × 900 images.

Commit:

```bash
git add social/snapsail-x-cards.html social/capture-cards.sh social/output docs/superpowers/plans/2026-07-16-snapsail-x-social-cards.md
git commit -m "feat: add SnapSail X social cards"
```
