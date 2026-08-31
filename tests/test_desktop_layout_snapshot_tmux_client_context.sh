#!/usr/bin/env bash
# Regression test for tmux 3.6b client field lookup: display-message -c <tty>
# evaluates in the invoking client context, so snapshot must use filtered
# list-clients rows when joining kitty windows to tmux identities.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT="$ROOT/bin/.local/bin/desktop-layout-snapshot"
WORK="$(mktemp -d "$HOME/.tmp/desktop-layout-tmux-client-context.XXXXXX")"
FIXTURE_BIN="$WORK/bin"
mkdir -p "$FIXTURE_BIN"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$FIXTURE_BIN/kdotool" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  search) printf 'fake-window-a\nfake-window-b\n' ;;
  getwindowpid)
    case "$2" in
      fake-window-a) echo 1001 ;;
      fake-window-b) echo 1002 ;;
      *) exit 1 ;;
    esac
    ;;
  get_desktop_for_window) echo 1 ;;
  getwindowgeometry)
    case "$2" in
      fake-window-a) printf 'Window fake-window-a\n  Position: 10,20\n  Geometry: 300x200\n' ;;
      fake-window-b) printf 'Window fake-window-b\n  Position: 40,50\n  Geometry: 600x400\n' ;;
      *) exit 1 ;;
    esac
    ;;
  getwindowname) echo "$2-title" ;;
  *) exit 0 ;;
esac
EOF

cat >"$FIXTURE_BIN/ps" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == *"-p 1001"* ]]; then
  echo 'pts/101'
elif [[ "$*" == *"-p 1002"* ]]; then
  echo 'pts/202'
else
  exit 1
fi
EOF

cat >"$FIXTURE_BIN/tmux" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "-N" ]] && shift
cmd="${1:-}"; shift || true

field_for() {
  local tty="$1" format="$2"
  case "$tty:$format" in
    /dev/pts/101:'#{session_name}') echo main-1 ;;
    /dev/pts/101:'#{session_group}') echo main ;;
    /dev/pts/101:'#{session_id}') echo '$s1' ;;
    /dev/pts/101:'#{window_index}') echo 3 ;;
    /dev/pts/101:'#{window_id}') echo '@3' ;;
    /dev/pts/101:'#{window_name}') echo alpha ;;
    /dev/pts/101:'#{pane_current_path}') echo "$HOME/alpha" ;;
    /dev/pts/101:'#{pane_current_command}') echo zsh ;;
    /dev/pts/202:'#{session_name}') echo main-2 ;;
    /dev/pts/202:'#{session_group}') echo main ;;
    /dev/pts/202:'#{session_id}') echo '$s2' ;;
    /dev/pts/202:'#{window_index}') echo 8 ;;
    /dev/pts/202:'#{window_id}') echo '@8' ;;
    /dev/pts/202:'#{window_name}') echo beta ;;
    /dev/pts/202:'#{pane_current_path}') echo "$HOME/beta" ;;
    /dev/pts/202:'#{pane_current_command}') echo bash ;;
    *) exit 1 ;;
  esac
}

case "$cmd" in
  list-clients)
    filter=""; format=""
    while (($#)); do
      case "$1" in
        -f) filter="$2"; shift 2 ;;
        -F) format="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    if [[ -z "$filter" ]]; then
      [[ "$format" == '#{client_tty}' ]] || exit 1
      printf '/dev/pts/101\n/dev/pts/202\n'
      exit 0
    fi
    case "$filter" in
      *'/dev/pts/101'*) field_for /dev/pts/101 "$format" ;;
      *'/dev/pts/202'*) field_for /dev/pts/202 "$format" ;;
      *) exit 1 ;;
    esac
    ;;
  display-message)
    # Simulate tmux 3.6b: -c does not provide the requested target client
    # context for these fields, so every lookup sees the invoking client.
    format=""
    while (($#)); do
      case "$1" in
        -F) format="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    field_for /dev/pts/101 "$format"
    ;;
  *) exit 1 ;;
esac
EOF

chmod +x "$FIXTURE_BIN/kdotool" "$FIXTURE_BIN/ps" "$FIXTURE_BIN/tmux"

HOME="$WORK/home" \
PATH="$FIXTURE_BIN:/usr/bin:/bin" \
XDG_STATE_HOME="$WORK/state" \
DESKTOP_LAYOUT_SCREEN_JSON='{"width":1920,"height":1080}' \
"$SNAPSHOT"

manifest="$WORK/state/desktop-layout/manifest.json"
jq -e --arg home "$WORK/home" '
  [.windows[] | {id:.kwin_window_id, index:.tmux_window_index, name:.tmux_window_name, cwd:.identity_receipt.shell_identity.cwd, command:.identity_receipt.shell_identity.command}] | sort_by(.id) ==
  [
    {id:"fake-window-a", index:3, name:"alpha", cwd:($home + "/alpha"), command:"zsh"},
    {id:"fake-window-b", index:8, name:"beta", cwd:($home + "/beta"), command:"bash"}
  ]
' "$manifest" >/dev/null || {
  jq '.windows[] | {id:.kwin_window_id, index:.tmux_window_index, name:.tmux_window_name, cwd:.identity_receipt.shell_identity.cwd, command:.identity_receipt.shell_identity.command}' "$manifest" >&2
  fail 'snapshot collapsed distinct tmux client identities'
}

echo 'PASS: desktop-layout-snapshot keeps distinct tmux client context via filtered list-clients'
