#!/bin/sh
# Captures the gadget to a PNG so a change can be looked at. Usage: ./screenshot.sh [--window] [out.png]
# Default (reliable): the app renders its own content view to the PNG (GADGET_SNAPSHOT), with alpha.
# --window: capture the real on-screen window with `screencapture -l`. This needs window-server access and
#           fails intermittently ("could not create image from window"), so only use it for checks the
#           in-process render can't show (real window shadow, drag, click-through).
# GADGET_MOCK=1, GADGET_REF=<png> etc. are passed through. Run ./build.sh first, then Read the PNG.
set -e
cd "$(dirname "$0")"

MODE=snapshot
if [ "$1" = "--window" ]; then MODE=window; shift; fi
OUT="${1:-build/screenshot.png}"
BIN=build/MyApp.app/Contents/MacOS/MyApp
[ -x "$BIN" ] || { echo "Run ./build.sh first" >&2; exit 1; }
pkill -x MyApp 2>/dev/null || true
rm -f "$OUT"

if [ "$MODE" = snapshot ]; then
    GADGET_SNAPSHOT="$OUT" "$BIN" >/dev/null
    [ -s "$OUT" ] || { echo "Snapshot failed" >&2; exit 1; }
    echo "Wrote $OUT"
    exit 0
fi

LOG=$(mktemp)
GADGET_DEBUG=1 "$BIN" >"$LOG" 2>&1 &
trap 'pkill -x MyApp 2>/dev/null || true; rm -f "$LOG"' EXIT
ID=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.5
    ID=$(sed -n 's/^GADGET_WINDOW_ID=//p' "$LOG")
    [ -n "$ID" ] && break
done
[ -n "$ID" ] || { echo "App did not print a window id:" >&2; cat "$LOG" >&2; exit 1; }
sleep 2
for _ in 1 2 3 4 5; do
    screencapture -o -l "$ID" "$OUT" 2>/dev/null && [ -s "$OUT" ] && { echo "Wrote $OUT"; exit 0; }
    sleep 1
done
echo "screencapture failed for window $ID; use the default snapshot mode" >&2
exit 1
