#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
cd "$ROOT_DIR"

swift build -c release -j 1
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$ROOT_DIR/build/SnapSail.app"
SIGNING_IDENTITY="${SNAPSAIL_CODESIGN_IDENTITY:-OpenTypeless Local Code Signing 2026}"

if ! security find-identity -v -p codesigning | grep -Fq "\"$SIGNING_IDENTITY\""; then
    print -u2 "SnapSail requires the persistent code-signing identity: $SIGNING_IDENTITY"
    print -u2 "Set SNAPSAIL_CODESIGN_IDENTITY to another stable identity if needed."
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/SnapSail" "$APP_DIR/Contents/MacOS/SnapSail"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod +x "$APP_DIR/Contents/MacOS/SnapSail"

codesign --force --deep --sign "$SIGNING_IDENTITY" "$APP_DIR"
echo "$APP_DIR"
