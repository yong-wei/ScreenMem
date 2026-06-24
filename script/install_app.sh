#!/usr/bin/env bash
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

DEST_DIR="${1:-/Applications}"
APP_NAME="ScreenMem.app"
SOURCE_APP="${ROOT_DIR}/.build/${APP_NAME}"
DEST_APP="${DEST_DIR}/${APP_NAME}"

bash "${ROOT_DIR}/script/build_and_run.sh" --smoke-test

if [ ! -d "$SOURCE_APP" ]; then
    echo "Missing built app bundle: ${SOURCE_APP}" >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

if pgrep -x ScreenMem >/dev/null 2>&1; then
    pkill -x ScreenMem
fi

rm -rf "$DEST_APP"
ditto "$SOURCE_APP" "$DEST_APP"

codesign --verify --deep --strict "$DEST_APP"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -f "$DEST_APP" >/dev/null 2>&1 || true
fi

mdimport "$DEST_APP" >/dev/null 2>&1 || true

echo "Installed ${DEST_APP}"
echo "Launch with: open -a ScreenMem"
