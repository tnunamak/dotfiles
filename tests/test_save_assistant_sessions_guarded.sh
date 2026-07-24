#!/usr/bin/env bash
# Unit-style regression checks for the assistant sidecar cliff guard.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$ROOT/tmux/.config/tmux/scripts/save-assistant-sessions-guarded.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/assistant-sidecar-guard.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

sessions_json() {
  local count="$1" i
  printf '{"sessions":['
  for ((i = 0; i < count; i++)); do
    if (( i > 0 )); then printf ','; fi
    printf '{"session_id":"%s"}' "$i"
  done
  printf ']}\n'
}

run_case() {
  local old="$1" new="$2" expected="$3" home
  home="$WORK/$old-$new"
  mkdir -p "$home/.tmux/resurrect" "$home/.tmux/plugins/tmux-assistant-resurrect/scripts"
  sessions_json "$old" >"$home/.tmux/resurrect/assistant-sessions.json"
  sessions_json "$new" >"$home/new.json"
  printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' \
    'cp "$HOME/new.json" "$HOME/.tmux/resurrect/assistant-sessions.json"' \
    >"$home/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"
  chmod +x "$home/.tmux/plugins/tmux-assistant-resurrect/scripts/save-assistant-sessions.sh"
  HOME="$home" bash "$GUARD"
  actual="$(jq '.sessions | length' "$home/.tmux/resurrect/assistant-sessions.json")"
  [[ "$actual" == "$expected" ]] || { echo "expected $old -> $new to leave $expected, got $actual" >&2; return 1; }
  if [[ "$expected" == "$old" ]]; then
    grep -q 'CLIFF GUARD: REFUSING' "$home/.tmux/resurrect/assistant-save.log"
  fi
}

run_case 164 7 164
run_case 50 40 40
run_case 5 0 5
echo "PASS: assistant sidecar cliff guard"
