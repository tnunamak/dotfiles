#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Builds a tmux session plus an
# assistant-sessions.json sidecar, so tmux-agent-resume-scale-test.sh can
# exercise the tool at production scale without needing real Claude/Codex
# processes.
#
# Two data sources, set via USE_REAL_FIXTURE:
#   0 (default) - synthetic, ENTRY_COUNT entries with small field values.
#                  Good for pushing scale past what's proven (500+ entries)
#                  but does NOT reliably reproduce the 2026-07-24 crash — a
#                  first synthetic attempt at 200 entries (35KB payload)
#                  ran clean against the confirmed pre-fix code; only the
#                  real fixture below did.
#   1            - fixtures/agent-resume-real-169.json, a redacted copy of
#                  the ACTUAL sidecar that crashed production at 169
#                  entries / 144KB (see CLAUDE.md "2026-07-24" section).
#                  Confirmed to reproduce "jq: Argument list too long"
#                  against pre-fix code (commit 45a18ba~1) and to run clean
#                  against the fix. This is the authoritative regression
#                  fixture — prefer it when in doubt.
set -euo pipefail

ENTRY_COUNT="${ENTRY_COUNT:-200}"
WINDOW_COUNT="${WINDOW_COUNT:-30}"
USE_REAL_FIXTURE="${USE_REAL_FIXTURE:-0}"
FIXTURE_PATH=/workspace/devcontainer/scripts/tmux-restore-test/fixtures/agent-resume-real-169.json

echo "[populate] HOME=$HOME entry_count=$ENTRY_COUNT window_count=$WINDOW_COUNT use_real_fixture=$USE_REAL_FIXTURE"

cd /workspace
stow --target="$HOME" --no-folding bin
echo "[populate] stowed bin package"

mkdir -p "$HOME/.tmux/resurrect"

if [ "$USE_REAL_FIXTURE" = "1" ]; then
  ENTRY_COUNT=$(jq -r '.sessions | length' "$FIXTURE_PATH")
  # Fixture cwds are already /home/tester/... (redacted at capture time);
  # this container's user IS tester, so no rewrite needed.
  cp "$FIXTURE_PATH" "$HOME/.tmux/resurrect/assistant-sessions.json"
  echo "[populate] using real fixture: $ENTRY_COUNT entries"
fi

tmux kill-server 2>/dev/null || true
tmux new-session -d -s main -x 200 -y 50
for i in $(seq 1 "$((WINDOW_COUNT - 1))"); do
  tmux new-window -t main -n "w$i"
done
echo "[populate] created $WINDOW_COUNT tmux windows in session 'main'"

if [ "$USE_REAL_FIXTURE" != "1" ]; then
  # cwd must exist: resume_command emits `cd <cwd> || exit`, so an invented
  # path makes every real launch attempt exit immediately — this broke the
  # scale test itself (200 simultaneous cd-failures) before it ever
  # exercised the tool. Use $HOME, which is guaranteed to exist for every
  # entry.
  {
    printf '{"timestamp":"2026-07-25T00:00:00Z","sessions":['
    for i in $(seq 0 $((ENTRY_COUNT - 1))); do
      [ "$i" -gt 0 ] && printf ','
      win=$((i % WINDOW_COUNT))
      if [ $((i % 2)) -eq 0 ]; then tool=claude; else tool=codex; fi
      id=$(printf '00000000-0000-4000-8000-%012d' "$i")
      printf '{"pane":"main:%d.0","tool":"%s","session_id":"%s","cwd":"%s","pid":"%d","model":"","cli_args":"--dangerously-skip-permissions"}' \
        "$win" "$tool" "$id" "$HOME" "$((10000 + i))"
    done
    printf ']}'
  } > "$HOME/.tmux/resurrect/assistant-sessions.json"
fi

# ENTRY_COUNT for export to the assert script (fixture mode overwrote it above)
echo "$ENTRY_COUNT" > /tmp/agent-resume-scale-entry-count

actual_count=$(jq -r '.sessions | length' "$HOME/.tmux/resurrect/assistant-sessions.json")
echo "[populate] wrote sidecar with $actual_count entries"
[ "$actual_count" -eq "$ENTRY_COUNT" ] || { echo "[populate] FATAL: expected $ENTRY_COUNT, got $actual_count"; exit 1; }
