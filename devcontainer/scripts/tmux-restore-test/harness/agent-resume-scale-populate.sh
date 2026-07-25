#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Builds a tmux session plus a
# synthetic assistant-sessions.json sidecar at ENTRY_COUNT entries, so
# tmux-agent-resume-scale-test.sh can exercise it at production scale without
# needing 200 real Claude/Codex processes.
#
# ENTRY_COUNT default (200) is deliberately above the 169 that broke in
# production 2026-07-24 (see CLAUDE.md "2026-07-24" section) — the margin is
# the point, not just reproduction.
set -euo pipefail

ENTRY_COUNT="${ENTRY_COUNT:-200}"
WINDOW_COUNT="${WINDOW_COUNT:-30}"

echo "[populate] HOME=$HOME entry_count=$ENTRY_COUNT window_count=$WINDOW_COUNT"

cd /workspace
stow --target="$HOME" --no-folding bin
echo "[populate] stowed bin package"

tmux kill-server 2>/dev/null || true
tmux new-session -d -s main -x 200 -y 50
for i in $(seq 1 "$((WINDOW_COUNT - 1))"); do
  tmux new-window -t main -n "w$i"
done
echo "[populate] created $WINDOW_COUNT tmux windows in session 'main'"

# cwd must exist: resume_command emits `cd <cwd> || exit`, so an invented
# path makes every real launch attempt exit immediately — this broke the
# scale test itself (200 simultaneous cd-failures) before it ever exercised
# the tool. Use $HOME, which is guaranteed to exist for every entry.
mkdir -p "$HOME/.tmux/resurrect"
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

actual_count=$(jq -r '.sessions | length' "$HOME/.tmux/resurrect/assistant-sessions.json")
echo "[populate] wrote sidecar with $actual_count entries"
[ "$actual_count" -eq "$ENTRY_COUNT" ] || { echo "[populate] FATAL: expected $ENTRY_COUNT, got $actual_count"; exit 1; }
