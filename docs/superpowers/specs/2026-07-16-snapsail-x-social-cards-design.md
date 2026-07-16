# SnapSail X Social Cards Design

## Objective

Create one self-contained HTML page that presents four screenshot-ready promotional cards for SnapSail. Each card is exactly 1600 × 900 pixels and can be captured directly from a desktop browser for use beneath the first English-language X post.

## Visual direction

The cards reinterpret the existing SnapSail product page rather than copying it. They use warm paper white, ink black, SnapSail blue, precise grid marks, native macOS window chrome, and the product's blue capture-selection geometry. The result should feel like a refined editorial campaign for a native Mac utility: quiet, technical, tactile, and recognizably SnapSail.

The layout avoids generic gradient marketing cards, dense feature checklists, stock imagery, external image dependencies, and unsupported claims. Text remains legible when each card is displayed in the X timeline.

## Card sequence

1. **Point of view** — “Screenshot apps shouldn’t be subscriptions.” A strong editorial headline beside an oversized capture-selection composition. Supporting copy identifies SnapSail as native, local-first, free, and open source.
2. **Daily workflow** — “Capture. Annotate. Pin. Move on.” A left-to-right workflow illustrates the short path from shortcut to finished result and emphasizes repeated everyday use.
3. **Privacy** — “Your screenshots stay on your Mac.” A dark precision card shows a local Mac window, privacy boundary, and concise facts: no account, no upload, local history.
4. **Product overview** — “Free. Open source. Built for everyday use.” A feature-rich final card combines area capture, scrolling capture, inline annotation, and pinning without reading like a pricing advertisement.

All primary card copy is English to match the recommended first X post and the product's Western-market focus.

## Page behavior

- The page contains a compact control bar followed by four vertically stacked artboards.
- Each `.artboard` has a fixed 1600 × 900 CSS-pixel canvas and a stable `data-card` identifier.
- Controls provide previous/next navigation, direct card selection, and a focus mode that hides the page chrome and isolates the current card for screenshots.
- Keyboard controls support left/right navigation, number keys 1–4, and `F` for focus mode.
- At narrower browser widths, artboards scale visually while preserving their 16:9 composition and exact internal coordinate system.
- Motion is limited to the page presentation and controls. Cards themselves settle into a static state so captured output is deterministic.

## Implementation boundaries

- Add a standalone HTML file under `social/` with embedded CSS and JavaScript so it can be opened directly without a build step.
- Use CSS shapes, gradients, typography, and inline SVG only; do not depend on remote fonts, JavaScript packages, or image services.
- Reuse product facts verified in the repository: native macOS, local-first processing, no account, no uploads, region and window capture, scrolling capture, inline annotation, pinning, and MIT-licensed open source.
- Do not imply a notarized download, App Store availability, a paid subscription, or a user-count claim.

## Verification

- Open the file in a browser at a 1600 × 900 viewport and capture every artboard.
- Inspect all four rendered images for clipping, small text, overlap, incorrect stacking, and inconsistent spacing.
- Confirm controls and keyboard navigation work.
- Confirm the file has no network dependencies and that every artboard reports a 1600 × 900 layout size.
- Keep the existing SnapSail test suite unchanged because the deliverable is an isolated social asset rather than application runtime code.
