#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
cd "$ROOT_DIR"

usage() {
    cat <<'EOF'
Usage: ./init.sh [--quick|--release|--help]

  no option   Validate the environment and run the full XCTest suite.
  --quick     Validate the environment and Swift package manifest only.
  --release   Run tests, build the signed app, and verify its metadata/signature.
EOF
}

mode="${1:-test}"
case "$mode" in
    test|--quick|--release)
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        print -u2 "Unknown option: $mode"
        usage >&2
        exit 2
        ;;
esac

if [[ "$(uname -s)" != "Darwin" ]]; then
    print -u2 "SnapSail requires macOS."
    exit 1
fi

for command_name in swift git; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        print -u2 "Missing required command: $command_name"
        exit 1
    fi
done

echo "=== SnapSail Harness Initialization ==="
echo "Repository: $ROOT_DIR"
swift --version | head -n 1
git status --short --branch

echo "=== Validating Swift Package ==="
swift package describe >/dev/null

if [[ "$mode" == "--quick" ]]; then
    echo "=== Quick Validation Complete ==="
    exit 0
fi

echo "=== Running XCTest Suite ==="
swift test -j 1

if [[ "$mode" == "--release" ]]; then
    for command_name in plutil codesign; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            print -u2 "Missing required release command: $command_name"
            exit 1
        fi
    done

    echo "=== Building Signed Release App ==="
    zsh Scripts/build-app.sh
    plutil -lint build/SnapSail.app/Contents/Info.plist
    codesign --verify --deep --strict --verbose=2 build/SnapSail.app
fi

echo "=== Verification Complete ==="
echo "Next: read feature_list.json and work on exactly one active feature."
