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
# LAUNCH_ASSISTANTS=N starts N fake claude processes in the first N
# windows after they're created. Used by scenarios that exercise the
# tmux-assistant-resurrect save+restore path.
LAUNCH_ASSISTANTS="${LAUNCH_ASSISTANTS:-0}"
# GROUPED_CLONES=N uses tmux new-session -t to create N grouped session
# clones (mimics tmux-local-attach-main creating main-0, main-1, ...).
# Required for repro of the canonical-naming bug.
GROUPED_CLONES="${GROUPED_CLONES:-0}"
# UNPATCH_PLUGIN_AFTER_SAVE=1 reverts the assistant-resurrect patch AFTER the
# initial saves but BEFORE the crash. Mimics a TPM auto-update that wipes
# the patch between user sessions. The next boot's ExecStartPre should
# re-apply it before any new save fires.
UNPATCH_PLUGIN_AFTER_SAVE="${UNPATCH_PLUGIN_AFTER_SAVE:-0}"
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

# Make ~/.local/bin (where the claude/codex stubs live) reachable inside panes
tmux set-environment -g PATH "$HOME/.local/bin:$PATH"

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

# Launch fake assistants in the first N windows. Use respawn-window so the
# pane's literal process is `claude` (avoids racing the shell). Pass a fake
# --resume <UUID> so the assistant-resurrect plugin's "Method 2" detector
# extracts a session_id from argv. Without an ID the plugin logs "detected
# claude but no session ID available" and skips the entry.
if (( LAUNCH_ASSISTANTS > 0 )); then
  for i in $(seq 0 $((LAUNCH_ASSISTANTS - 1))); do
    if (( i >= WINDOW_COUNT )); then break; fi
    fake_id="00000000-0000-0000-0000-00000000000$((i+1))"
    tmux respawn-window -k -t "$SESSION:$i" "$HOME/.local/bin/claude --resume $fake_id"
  done
  sleep 1
  echo "[populate:$SCENARIO] launched $LAUNCH_ASSISTANTS claude stubs"
  for i in $(seq 0 $((LAUNCH_ASSISTANTS - 1))); do
    if (( i >= WINDOW_COUNT )); then break; fi
    cmd=$(tmux display-message -t "$SESSION:$i" -p '#{pane_current_command}')
    echo "[populate:$SCENARIO]   pane $i runs: $cmd"
  done
fi

# Create grouped session clones (mimics kitty's tmux-local-attach-main).
# The plugin captures the canonical name only after our patch is applied;
# without the patch, panes are saved under the most recent grouped clone.
if (( GROUPED_CLONES > 0 )); then
  for i in $(seq 0 $((GROUPED_CLONES - 1))); do
    tmux new-session -d -t "$SESSION" -s "${SESSION}-$i"
  done
  echo "[populate:$SCENARIO] created $GROUPED_CLONES grouped clones"
  tmux list-sessions
fi

# --- Optional: force #{session_group} to come back EMPTY during the save ---
# (Incident 2026-06-08.) The upstream canonicalization trusts #{session_group}
# alone: `g=$(tmux display-message -t "$name" -p '#{session_group}'); [ -n "$g" ]
# && name=$g`. If that query returns empty while a pane is still listed under a
# grouped CLONE (main-N) — which happens when the clone is being torn down
# mid-save, so display-message errors and `|| true` swallows it — the pane is
# saved verbatim as `main-N:`, and the next boot restores 0 of N.
# This knob shadows `tmux` with a wrapper that returns EMPTY for the
# `#{session_group}` query (and passes everything else through), deterministically
# reproducing that race. Patch 2c's suffix-strip fallback must still canonicalize
# to `main:`; without 2c the saved json keeps `main-N:` and the assertion fails.
if [[ "${FORCE_EMPTY_SESSION_GROUP:-0}" == "1" ]]; then
  WRAP_DIR="$HOME/.ar-tmux-wrap"
  mkdir -p "$WRAP_DIR"
  REAL_TMUX="$(command -v tmux)"
  cat >"$WRAP_DIR/tmux" <<WRAP
#!/usr/bin/env bash
# Test shim: emulate a transient empty #{session_group} during save.
# Only the exact session-group probe is forced empty; all else passes through.
for a in "\$@"; do
  case "\$a" in
    '#{session_group}') exit 0 ;;
  esac
done
exec "$REAL_TMUX" "\$@"
WRAP
  chmod +x "$WRAP_DIR/tmux"
  export PATH="$WRAP_DIR:$PATH"
  echo "[populate:$SCENARIO] FORCE_EMPTY_SESSION_GROUP: tmux wrapper active ($WRAP_DIR/tmux)"
fi

run_saves "$SAVES_BEFORE"
echo "[populate:$SCENARIO] phase A: ran $SAVES_BEFORE saves with $WINDOW_COUNT windows"

# Remove the shim immediately after the pre-crash saves so it can't perturb the
# crash simulation or the post-reboot restore (which must use real tmux).
if [[ "${FORCE_EMPTY_SESSION_GROUP:-0}" == "1" ]]; then
  rm -rf "$HOME/.ar-tmux-wrap"
  export PATH="${PATH#"$HOME/.ar-tmux-wrap":}"
  echo "[populate:$SCENARIO] FORCE_EMPTY_SESSION_GROUP: tmux wrapper removed"
fi

# --- Optional: capture-skip test (Patch 3) ---
# Echo a marker into every pane so each has scrollback, then run ONE save with
# pane-content capture and stage the resulting archive for the assertion script.
# Assistant panes (windows 0..LAUNCH_ASSISTANTS-1) must be ABSENT from the
# archive; plain panes (the rest) must be PRESENT. We stage a copy because the
# crash simulation below mutates/removes the live archive.
if [[ "${CAPTURE_SKIP_TEST:-0}" == "1" ]]; then
  echo "[populate:$SCENARIO] capture-skip: seeding pane scrollback + running capture save"
  # Assistant panes run the claude stub (no shell to echo into), so they have no
  # extra scrollback — that's fine, the point is they must not be captured.
  # Seed plain panes with a marker so they have content worth capturing.
  for w in $(tmux list-windows -t "$SESSION" -F '#{window_index}'); do
    if (( w >= LAUNCH_ASSISTANTS )); then
      tmux send-keys -t "$SESSION:$w" "echo CAPTURE_MARKER_win_$w" Enter 2>/dev/null || true
    fi
  done
  sleep 1
  # A fresh save with capture on. tmux.conf sets @resurrect-capture-pane-contents on.
  rm -f "$RESURRECT_DIR/pane_contents.tar.gz"
  tmux rename-window -t "$SESSION:0" "cap-$RANDOM" 2>/dev/null || true
  bash "$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh" >/dev/null 2>&1 || true
  sleep 1
  if [[ -f "$RESURRECT_DIR/pane_contents.tar.gz" ]]; then
    cp "$RESURRECT_DIR/pane_contents.tar.gz" "$RESURRECT_DIR/capture-test-archive.tar.gz"
    echo "[populate:$SCENARIO] capture-skip: staged archive; entries:"
    gzip -dc "$RESURRECT_DIR/capture-test-archive.tar.gz" 2>/dev/null | tar tf - 2>/dev/null | grep 'pane-' | sed 's/^/    /'
  else
    echo "[populate:$SCENARIO] capture-skip: WARNING no pane_contents.tar.gz produced"
  fi
  # Leak check MUST run here (pre-reboot): /tmp is cleared on the simulated
  # reboot, so checking in assert would be meaningless. Record the count of
  # leaked tmp.* dirs to a file the assertion script reads.
  leaked_now="$(find /tmp -maxdepth 1 -name 'tmp.*' -type d 2>/dev/null | wc -l)"
  echo "$leaked_now" > "$RESURRECT_DIR/capture-test-tmp-leak-count"
  echo "[populate:$SCENARIO] capture-skip: /tmp/tmp.* dirs after capture save: $leaked_now"
fi

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

# Simulate a TPM auto-update wiping our patch. Re-clone the plugin from
# scratch (the same thing TPM's update_plugins does). The next save would
# produce broken pane addresses unless something re-applies the patch.
if (( UNPATCH_PLUGIN_AFTER_SAVE )); then
  PLUGIN_DIR="$HOME/.tmux/plugins/tmux-assistant-resurrect"
  if [[ -e "$PLUGIN_DIR" && ! -L "$PLUGIN_DIR" ]]; then
    cd "$PLUGIN_DIR"
    git checkout -- scripts/save-assistant-sessions.sh 2>/dev/null || true
    cd "$HOME"
    echo "[populate:$SCENARIO] CRASH: reverted plugin patch via 'git checkout' (mimics TPM update)"
  else
    # Plugin is symlinked (host dotfiles dev); just rewrite the file content
    # from the upstream version. Skip — host doesn't normally use this scenario.
    echo "[populate:$SCENARIO] CRASH: plugin is symlinked, can't safely revert"
  fi
fi

echo "[populate:$SCENARIO] DONE"
