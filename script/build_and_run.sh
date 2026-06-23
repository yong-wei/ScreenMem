#!/usr/bin/env bash
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"
MODE="${1:-run}"

if [ "$MODE" != "run" ] && [ "$MODE" != "--smoke-test" ]; then
    echo "Usage: $0 [--smoke-test]" >&2
    exit 2
fi

mkdir -p .logs
LOG_FILE="${ROOT_DIR}/.logs/screenmem.log"
PID_FILE="${ROOT_DIR}/.logs/screenmem.pid"
rm -f "$PID_FILE"

swift build
BIN_DIR="$(swift build --show-bin-path)"
APP_DIR="${ROOT_DIR}/.build/ScreenMem.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "${BIN_DIR}/ScreenMem" "$APP_DIR/Contents/MacOS/ScreenMem"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ScreenMem</string>
    <key>CFBundleIdentifier</key>
    <string>dev.screenmem.ScreenMem</string>
    <key>CFBundleName</key>
    <string>ScreenMem</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST
codesign --force --sign - --identifier dev.screenmem.ScreenMem "$APP_DIR" >/dev/null

APP_EXECUTABLE="${BIN_DIR}/ScreenMem"

if [ "$MODE" = "--smoke-test" ]; then
    "$APP_EXECUTABLE" --smoke-check >> "$LOG_FILE" 2>&1
    echo "ScreenMem smoke check completed."
    echo "App bundle: ${APP_DIR}"
    exit 0
fi

echo "$$" > "$PID_FILE"
echo "ScreenMem launching in foreground."
echo "App bundle: ${APP_DIR}"
exec "$APP_EXECUTABLE" >> "$LOG_FILE" 2>&1
