#!/usr/bin/env bash
# Regression test: tmux rows must use explicit tmux target selection even when
# a Kitty native session path is present in the manifest.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESTORE="$ROOT/bin/.local/bin/desktop-layout-restore"
WORK="$(mktemp -d "$HOME/.tmp/desktop-layout-target-selection.XXXXXX")"
FIXTURE_BIN="$WORK/bin"
mkdir -p "$FIXTURE_BIN" "$WORK/home/.tmux/resurrect" "$WORK/cwd" "$WORK/state"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$FIXTURE_BIN/kdotool" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  search)
    [[ -s "$DESKTOP_LAYOUT_KITTY_PID_FILE" ]] && echo fake-kitty-window
    ;;
  getactivewindow) echo fake-kitty-window ;;
  getwindowpid) cat "$DESKTOP_LAYOUT_KITTY_PID_FILE" ;;
  get_desktop_for_window) echo 1 ;;
  getwindowgeometry) printf 'Window fake-kitty-window\n  Position: 10,20\n  Geometry: 300x200\n' ;;
  *) exit 0 ;;
esac
EOF

cat >"$FIXTURE_BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "--user show-environment") printf 'WAYLAND_DISPLAY=wayland-test\n' ;;
  "--user is-active") echo inactive ;;
  *) exit 0 ;;
esac
EOF

cat >"$FIXTURE_BIN/kitty" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$$" >"$DESKTOP_LAYOUT_KITTY_PID_FILE"
printf '%s\n' "$*" >"$DESKTOP_LAYOUT_KITTY_ARGV_LOG"
sleep 20
EOF

cat >"$FIXTURE_BIN/tmux" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$FIXTURE_BIN/kdotool" "$FIXTURE_BIN/systemctl" "$FIXTURE_BIN/kitty" "$FIXTURE_BIN/tmux"

sidecar="$WORK/home/.tmux/resurrect/assistant-sessions.json"
cat >"$sidecar" <<JSON
{
  "sessions": [
    {
      "pane": "main:7.0",
      "tool": "claude",
      "session_id": "session-7",
      "env": {"CLAUDE_CONFIG_DIR": "$WORK/home/.claude"}
    }
  ]
}
JSON
sidecar_hash="$(sha256sum "$sidecar" | awk '{print $1}')"
native_session="$WORK/native.kitty-session"
printf 'layout native content\n' >"$native_session"
manifest="$WORK/manifest.json"
jq -n \
  --arg cwd "$WORK/cwd" \
  --arg native "$native_session" \
  --arg ns "$WORK/home/.claude" \
  --arg sidecar "$sidecar" \
  --arg sidecar_hash "$sidecar_hash" \
  '{
    screen:{width:1920,height:1080},
    windows:[{
      is_tmux:true,
      tmux_window_index:7,
      tmux_window_name:"agent",
      virtual_desktop:1,
      position:{x:10,y:20},
      size:{width:300,height:200},
      cwd:$cwd,
      native_session:$native,
      identity_receipt:{
        assurance:"agent-sidecar",
        agent_identity:{
          provider:"claude",
          assistant_session_id:"session-7",
          config_namespace:$ns,
          sidecar:{path:$sidecar,sha256:$sidecar_hash}
        }
      }
    }]
  }' >"$manifest"

live_row="$(jq -cn --arg cwd "$WORK/cwd" \
  '{tmux_session:"main",tmux_group:"main",tmux_window_index:7,tmux_window_name:"agent",cwd:$cwd,command:"setsid"}')"

env -i \
  HOME="$WORK/home" \
  PATH="$FIXTURE_BIN:/usr/bin:/bin" \
  DESKTOP_LAYOUT_WAIT_SECONDS=1 \
  DESKTOP_LAYOUT_SCREEN='1920 1080' \
  DESKTOP_LAYOUT_TMUX_WINDOWS_JSONL="$live_row" \
  DESKTOP_LAYOUT_KITTY_PID_FILE="$WORK/kitty.pid" \
  DESKTOP_LAYOUT_KITTY_ARGV_LOG="$WORK/kitty.argv" \
  "$RESTORE" --force --manifest "$manifest" >"$WORK/out" 2>&1

grep -q 'TMUX_ATTACH_TARGET_WINDOW=7 tmux-local-attach-main' "$WORK/kitty.argv" ||
  fail 'tmux row did not use explicit tmux target launch path'
! grep -q -- '--session' "$WORK/kitty.argv" ||
  fail 'tmux row incorrectly used native-session launch path'

echo 'PASS: desktop-layout-restore prioritizes explicit tmux target selection for tmux rows'
