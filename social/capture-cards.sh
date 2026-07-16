#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HTML_PATH="$ROOT_DIR/social/snapsail-x-cards.html"
OUTPUT_DIR="$ROOT_DIR/social/output"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [[ ! -x "$CHROME" ]]; then
    print -u2 "Google Chrome is required to export the SnapSail cards."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
find "$OUTPUT_DIR" -maxdepth 1 -name 'snapsail-x-card-*.png' -delete

for card in 1 2 3 4; do
    number="$(printf '%02d' "$card")"
    output="$OUTPUT_DIR/snapsail-x-card-$number.png"
    "$CHROME" \
        --headless=new \
        --disable-gpu \
        --hide-scrollbars \
        --force-device-scale-factor=1 \
        --window-size=1600,900 \
        --screenshot="$output" \
        "file://$HTML_PATH?capture=1&card=$card" \
        >/dev/null 2>&1
    print "$output"
done
