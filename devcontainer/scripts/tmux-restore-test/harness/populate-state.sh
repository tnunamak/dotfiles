#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Creates a populated tmux
# session, triggers multiple saves to mimic real continuum history, then
# simulates the post-power-loss state (most recent live save unsynced/lost).
#
# Scenarios are env-driven:
#   WINDOW_COUNT     — initial window count (default 8)
#   SCENARIO         — name for logging
#   SAVES_BEFORE     — how many saves to do BEFORE the "shrink" (default 3)
#   SHRINK_TO        — window count after shrink (default 0 means no shrink)
#   SAVES_AFTER      — how many saves to do AFTER the shrink (default 0)
#   DELETE_LIVE_LAST — 1 to delete the live-dir copy of `last`'s target (the
#                      "unsynced" power-loss simulation). Default 1.
#   DELETE_LIVE_ALL  — 1 to delete ALL live tmux_resurrect_*.txt files (both
#                      real and synthetic). Used when we want to force reads
#                      out of backups/ entirely. Default 0.
#   DELETE_BACKUPS   — 1 to delete backups/ entirely. Default 0.
#   DELETE_BEST      — 1 to delete best.txt only. Default 0.
#   PHASE            — "first" (default) does the full populate+crash;
#                      "second" assumes a previous populate ran, just shrinks
#                      and crashes again to simulate a second power loss.
set -euo pipefail

WINDOW_COUNT="${WINDOW_COUNT:-8}"
SCENARIO="${SCENARIO:-default}"
SAVES_BEFORE="${SAVES_BEFORE:-3}"
SHRINK_TO="${SHRINK_TO:-0}"
SAVES_AFTER="${SAVES_AFTER:-0}"
DELETE_LIVE_LAST="${DELETE_LIVE_LAST:-1}"
DELETE_LIVE_ALL="${DELETE_LIVE_ALL:-0}"
DELETE_BACKUPS="${DELETE_BACKUPS:-0}"
DELETE_BEST="${DELETE_BEST:-0}"
PHASE="${PHASE:-first}"
# ADD_OLD_SAVES creates N synthetic timestamped save files beyond what
# save.sh produces, to ensure the OLD systemd-restore.sh's `find | sort | awk
# exit` pipeline sees enough input to actually trigger the SIGPIPE bug.
# Real users accumulate thousands over time. Default 0 — set to 50+ to repro
# the SIGPIPE-on-sort behavior.
ADD_OLD_SAVES="${ADD_OLD_SAVES:-0}"
RESURRECT_DIR="$HOME/.tmux/resurrect"

# Wait for tmux server (started by tmux.service)
for _ in $(seq 1 20); do
  tmux list-sessions >/dev/null 2>&1 && break
  sleep 0.25
done
tmux list-sessions >/dev/null 2>&1 || { echo "[populate] tmux not running"; exit 1; }

# Rename to 'main' for predictability
tmux rename-session -t '$0' main 2>/dev/null || true
SESSION="$(tmux list-sessions -F '#{session_name}' | head -1)"
echo "[populate:$SCENARIO] using session: $SESSION"

create_windows() {
  local target_count="$1"
  local current_count
  current_count=$(tmux list-windows -t "$SESSION" | wc -l)
  local dirs=(/tmp /var /etc /home /opt /root /usr /srv /run /sys)
  while (( current_count < target_count )); do
    local d="${dirs[$((current_count % ${#dirs[@]}))]}"
    tmux new-window -t "$SESSION:" -c "$d" -n "win-$current_count"
    current_count=$((current_count + 1))
  done
  while (( current_count > target_count )); do
    tmux kill-window -t "$SESSION:$((current_count - 1))"
    current_count=$((current_count - 1))
  done
  echo "[populate:$SCENARIO] now $current_count windows"
}

run_saves() {
  local n="$1"
  local SAVE_SCRIPT="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
  for i in $(seq 1 "$n"); do
    # Mutate state between saves so save.sh's `files_differ` check produces
    # a distinct file per call. Otherwise save.sh deletes the duplicate and
    # `last` doesn't move — defeating the multi-save scenario we want.
    tmux rename-window -t "$SESSION:0" "tick-$i-$RANDOM" 2>/dev/null || true
    bash "$SAVE_SCRIPT" >/dev/null
    sleep 1
  done
  sync
}

# --- Phase A: populate up to WINDOW_COUNT and save N times ---
create_windows "$WINDOW_COUNT"
run_saves "$SAVES_BEFORE"
echo "[populate:$SCENARIO] phase A: ran $SAVES_BEFORE saves with $WINDOW_COUNT windows"

# --- Phase B (optional): shrink and save again ---
# Mimics the "user closed some windows just before crash" or "broken state"
if (( SHRINK_TO > 0 )); then
  create_windows "$SHRINK_TO"
  run_saves "$SAVES_AFTER"
  echo "[populate:$SCENARIO] phase B: shrank to $SHRINK_TO windows and ran $SAVES_AFTER saves"
fi

# Show final state
echo "[populate:$SCENARIO] resurrect dir contents:"
ls -la "$RESURRECT_DIR/" 2>/dev/null
echo "[populate:$SCENARIO] backups:"
ls -la "$RESURRECT_DIR/backups/" 2>/dev/null

LAST_TARGET="$(readlink "$RESURRECT_DIR/last" 2>/dev/null || echo MISSING)"
echo "[populate:$SCENARIO] last -> $LAST_TARGET"

# --- Optional: synthesize old saves ---
# Drops N additional fake save files in the live dir with backdated timestamps,
# to mimic a long-running system's save history. Required for triggering the
# old systemd-restore.sh's SIGPIPE bug, which only fires with enough input
# for `sort` to buffer past the pipe before `awk exit` runs.
if (( ADD_OLD_SAVES > 0 )); then
  echo "[populate:$SCENARIO] adding $ADD_OLD_SAVES synthetic old saves"
  for i in $(seq 1 "$ADD_OLD_SAVES"); do
    # Backdated timestamps so these stay older than any save.sh-produced file.
    ts="20250101T$(printf '%06d' "$((i % 235959))")"
    # Each fake save needs to be parseable enough that `grep -c '^pane'`
    # returns 0 (we want OLD restore to see "no panes"), but real enough
    # that `find | sort` does meaningful work.
    head -c 5000 /dev/urandom > "$RESURRECT_DIR/tmux_resurrect_$ts.txt" 2>/dev/null || true
    # Backdate so newer real saves still sort first
    touch -d "2025-01-01 12:00:$((i % 60))" "$RESURRECT_DIR/tmux_resurrect_$ts.txt" 2>/dev/null || true
  done
  echo "[populate:$SCENARIO] live dir now has $(find "$RESURRECT_DIR" -maxdepth 1 -name 'tmux_resurrect_*.txt' | wc -l) save files"
fi

# --- Crash simulation phase ---
if (( DELETE_LIVE_LAST )) && [[ "$LAST_TARGET" != "MISSING" ]]; then
  LIVE_FILE="$RESURRECT_DIR/$LAST_TARGET"
  if [[ -f "$LIVE_FILE" ]]; then
    rm -f "$LIVE_FILE"
    echo "[populate:$SCENARIO] CRASH: removed live $LAST_TARGET — last is now dangling"
  fi
fi

if (( DELETE_LIVE_ALL )); then
  # Wipe every live save (real + synthetic) so the only remaining good copy
  # of the "previous" target is in backups/. Simulates the user's original
  # incident: an unsynced live dir but a healthy backups/ copy.
  rm -f "$RESURRECT_DIR"/tmux_resurrect_*.txt
  echo "[populate:$SCENARIO] CRASH: removed ALL live tmux_resurrect_*.txt files"
fi

if (( DELETE_BACKUPS )); then
  rm -rf "$RESURRECT_DIR/backups"
  echo "[populate:$SCENARIO] CRASH: removed backups/ dir entirely"
fi

if (( DELETE_BEST )); then
  rm -f "$RESURRECT_DIR/backups/best.txt"
  echo "[populate:$SCENARIO] CRASH: removed best.txt only"
fi

echo "[populate:$SCENARIO] DONE"
