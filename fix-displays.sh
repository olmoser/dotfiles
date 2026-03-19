#!/bin/bash
set -euo pipefail
# fix-displays.sh — Detects and corrects display resolution/refresh rate after wake
#
# SETUP:
#   1. brew install displayplacer sleepwatcher
#   2. While displays look CORRECT, run: displayplacer list
#   3. Copy the "displayplacer" command printed at the bottom of that output
#   4. Paste it as the value of CORRECT_CONFIG below
#   5. Set your expected values for TARGET_RES and TARGET_HZ
#   6. brew services start sleepwatcher

# ── CONFIG ────────────────────────────────────────────────────────────────────
TARGET_RES="3840x2160"        # Expected resolution for each display
TARGET_HZ="144"               # Expected refresh rate

# Paste your `displayplacer list` command here (the last line of its output):
CORRECT_CONFIG='displayplacer "id:XXXXXXXX res:3840x2160 hz:144 color_depth:8 scaling:off origin:(0,0) degree:0" "id:YYYYYYYY res:3840x2160 hz:144 color_depth:8 scaling:off origin:(3840,0) degree:0"'
# ─────────────────────────────────────────────────────────────────────────────

LOG_FILE="${HOME}/.fix-displays.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# Sleepwatcher runs with a minimal PATH — ensure Homebrew is available
for brew_bin in /opt/homebrew/bin /usr/local/bin; do
    case ":${PATH}:" in
        *":${brew_bin}:"*) ;;
        *) [[ -d "$brew_bin" ]] && export PATH="${brew_bin}:${PATH}" ;;
    esac
done

if [[ "$CORRECT_CONFIG" == *"XXXXXXXX"* ]]; then
    log "ERROR: CORRECT_CONFIG still contains placeholder IDs. Run 'displayplacer list' and paste the correct command."
    exit 1
fi

DISPLAYPLACER=$(command -v displayplacer) || true
if [[ -z "$DISPLAYPLACER" ]]; then
    log "ERROR: displayplacer not found. Run: brew install displayplacer"
    exit 1
fi

log "Checking display configuration..."

LIST_OUTPUT=$("$DISPLAYPLACER" list 2>&1)

CORRECT_COUNT=$(echo "$LIST_OUTPUT" | grep -c "res:${TARGET_RES} hz:${TARGET_HZ}" || true)
TOTAL_DISPLAYS=$(echo "$LIST_OUTPUT" | grep -c "^Persistent screen id:" || true)

log "Displays detected: $TOTAL_DISPLAYS | At ${TARGET_RES}@${TARGET_HZ}Hz: $CORRECT_COUNT"

if [[ "$TOTAL_DISPLAYS" -eq 0 ]]; then
    log "No displays detected — skipping"
    exit 0
fi

if [[ "$CORRECT_COUNT" -lt "$TOTAL_DISPLAYS" ]]; then
    log "Mismatch detected — waiting for display stack to settle..."
    sleep 2
    eval "$CORRECT_CONFIG" >> "$LOG_FILE" 2>&1
    log "Display config restored successfully."
else
    log "All displays correct, nothing to do."
fi
