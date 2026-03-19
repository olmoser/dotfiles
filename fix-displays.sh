#!/bin/bash
# fix-displays.sh — Detects and corrects display resolution/refresh rate after wake
#
# SETUP:
#   1. brew install displayplacer
#   2. While displays look CORRECT, run: displayplacer list
#   3. Copy the "displayplacer" command printed at the bottom of that output
#   4. Paste it as the value of CORRECT_CONFIG below
#   5. Set your expected values for TARGET_RES and TARGET_HZ
#   6. chmod +x ~/fix-displays.sh

# ── CONFIG ────────────────────────────────────────────────────────────────────
TARGET_RES="3840x2160"        # Expected resolution for each display
TARGET_HZ="144"               # Expected refresh rate

# Paste your `displayplacer list` command here (the last line of its output):
CORRECT_CONFIG='displayplacer "id:XXXXXXXX res:3840x2160 hz:144 color_depth:8 scaling:off origin:(0,0) degree:0" "id:YYYYYYYY res:3840x2160 hz:144 color_depth:8 scaling:off origin:(3840,0) degree:0"'
# ─────────────────────────────────────────────────────────────────────────────

DISPLAYPLACER=$(command -v displayplacer)
if [[ -z "$DISPLAYPLACER" ]]; then
    echo "ERROR: displayplacer not found. Run: brew install displayplacer"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking display configuration..."

LIST_OUTPUT=$("$DISPLAYPLACER" list 2>&1)

# Count displays currently at the correct resolution and refresh rate
CORRECT_COUNT=$(echo "$LIST_OUTPUT" | grep -c "res:${TARGET_RES} hz:${TARGET_HZ}")
TOTAL_DISPLAYS=$(echo "$LIST_OUTPUT" | grep -c "^Persistent screen id:")

echo "  Displays detected : $TOTAL_DISPLAYS"
echo "  At ${TARGET_RES}@${TARGET_HZ}Hz: $CORRECT_COUNT"

if [[ "$CORRECT_COUNT" -lt "$TOTAL_DISPLAYS" ]]; then
    echo "  ⚠️  Mismatch detected — applying correct config..."
    # Small delay so the display stack has fully settled after wake
    sleep 2
    eval "$CORRECT_CONFIG"
    RESULT=$?
    if [[ $RESULT -eq 0 ]]; then
        echo "  ✅ Display config restored successfully."
    else
        echo "  ❌ displayplacer returned error $RESULT"
        exit 1
    fi
else
    echo "  ✅ All displays look correct, nothing to do."
fi
