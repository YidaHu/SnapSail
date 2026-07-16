#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_DIR="$ROOT_DIR/build/SnapSail.app"

if [[ ! -d "$APP_DIR" ]]; then
  zsh "$ROOT_DIR/Scripts/build-app.sh"
fi

pkill -x SnapSail 2>/dev/null || true
open "$APP_DIR"
