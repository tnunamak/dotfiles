#!/usr/bin/env bash
# Regression test for desktop-layout tmux identity receipts. Uses only stubs,
# JSONL fixtures, and dry-run restore; never talks to production KWin or tmux.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT="$ROOT/bin/.local/bin/desktop-layout-snapshot"
RESTORE="$ROOT/bin/.local/bin/desktop-layout-restore"
WORK="$(mktemp -d "$HOME/.tmp/desktop-layout-identity.XXXXXX")"
FIXTURE_BIN="$WORK/bin"
mkdir -p "$FIXTURE_BIN" "$WORK/home/.tmux/resurrect" "$WORK/agent-cwd" "$WORK/shell-cwd"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

cat >"$FIXTURE_BIN/kdotool" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  search) echo fake-agent-window ;;
  getactivewindow) echo fake-agent-window ;;
  getwindowpid) echo "${DESKTOP_LAYOUT_TEST_PID:?missing test PID}" ;;
  get_desktop_for_window) echo 1 ;;
  getwindowgeometry) printf 'Window fake-agent-window\n  Position: 10,20\n  Geometry: 300x200\n' ;;
  getwindowname) echo volatile-title ;;
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
chmod +x "$FIXTURE_BIN/kdotool" "$FIXTURE_BIN/systemctl"

sidecar="$WORK/home/.tmux/resurrect/assistant-sessions.json"
cat >"$sidecar" <<JSON
{
  "timestamp": "2026-08-30T22:00:00Z",
  "sessions": [
    {
      "pane": "main:7.0",
      "tool": "claude",
      "session_id": "42569d54",
      "cwd": "$WORK/agent-cwd",
      "pid": "123",
      "model": "claude-test",
      "cli_args": "--model test",
      "env": {"CLAUDE_CONFIG_DIR": "$WORK/home/.claude-odl"}
    }
  ]
}
JSON

client_json="$(jq -cn \
  --arg pane_cwd "$WORK/agent-cwd" \
  '{tty:"/dev/pts/123",tmux_session:"main-4",tmux_session_group:"main",tmux_session_id:"$old-session",tmux_window_index:7,tmux_window_id:"@old-window",tmux_window_name:"agent|name",pane_cwd:$pane_cwd,command:"setsid"}')"

DESKTOP_LAYOUT_TMUX_CLIENTS_JSONL="$client_json" \
DESKTOP_LAYOUT_TEST_PID="$$" \
DESKTOP_LAYOUT_TEST_TTY='pts/123' \
DESKTOP_LAYOUT_SCREEN_JSON='{"width":1920,"height":1080}' \
DESKTOP_LAYOUT_ASSISTANT_SIDECAR="$sidecar" \
HOME="$WORK/home" \
PATH="$FIXTURE_BIN:/usr/bin:/bin" \
XDG_STATE_HOME="$WORK/state" \
"$SNAPSHOT"

manifest="$WORK/state/desktop-layout/manifest.json"
jq -e --arg sidecar "$sidecar" --arg agent_cwd "$WORK/agent-cwd" --arg ns "$WORK/home/.claude-odl" '
  .version == 2 and
  .windows[0].tmux_window_index == 7 and
  .windows[0].tmux_window_name == "agent|name" and
  .windows[0].identity_receipt.assurance == "agent-sidecar" and
  .windows[0].identity_receipt.agent_identity.provider == "claude" and
  .windows[0].identity_receipt.agent_identity.assistant_session_id == "42569d54" and
  .windows[0].identity_receipt.agent_identity.cwd == $agent_cwd and
  .windows[0].identity_receipt.agent_identity.config_namespace == $ns and
  .windows[0].identity_receipt.agent_identity.sidecar.path == $sidecar and
  .windows[0].identity_receipt.shell_identity.cwd == $agent_cwd and
  .windows[0].identity_receipt.capture_metadata.kitty_cwd == .windows[0].cwd and
  .windows[0].cwd != .windows[0].identity_receipt.shell_identity.cwd and
  .windows[0].identity_receipt.capture_metadata.tmux_session_id == "$old-session" and
  .windows[0].identity_receipt.capture_metadata.tmux_window_id == "@old-window"
' "$manifest" >/dev/null || fail 'snapshot did not write agent sidecar receipt'

live_json() {
  jq -cn --arg name "$1" --arg cwd "$2" --arg command "$3" \
    '{tmux_session:"main-9",tmux_group:"main",tmux_window_index:7,tmux_window_name:$name,cwd:$cwd,command:$command}'
}

run_restore() {
  local manifest_file="$1" live_rows="$2" out="$3"
  env -i \
    HOME="$WORK/home" \
    PATH="$FIXTURE_BIN:/usr/bin:/bin" \
    DESKTOP_LAYOUT_WAIT_SECONDS=1 \
    DESKTOP_LAYOUT_SCREEN='1920 1080' \
    DESKTOP_LAYOUT_TMUX_WINDOWS_JSONL="$live_rows" \
    "$RESTORE" --dry-run --manifest "$manifest_file" >"$out" 2>&1
}

# Agent binding comes from sidecar provider/session/config namespace, not
# pre-stop tmux IDs or Kitty cwd/setsid. Changed restart-local tmux IDs are OK.
run_restore "$manifest" "$(live_json 'agent|name' "$WORK/home" setsid)" "$WORK/agent-ok.out" ||
  fail 'restore rejected matching agent sidecar receipt'
grep -q 'launch tmux window 7 desktop 1 at 10,20' "$WORK/agent-ok.out" ||
  fail 'dry-run output changed for matching agent receipt'

set +e
run_restore "$manifest" "" "$WORK/empty-live.out"
empty_live_rc=$?
set -e
[[ "$empty_live_rc" -ne 0 ]] || fail 'restore accepted tmux manifest without live evidence'
grep -q 'live tmux evidence is unavailable' "$WORK/empty-live.out" ||
  fail 'empty live evidence was not diagnosed'

mutated_sidecar="$WORK/mutated-assistant-sessions.json"
jq '.sessions[0].session_id = "different-session"' "$sidecar" >"$mutated_sidecar"
jq --arg path "$mutated_sidecar" '.windows[0].identity_receipt.agent_identity.sidecar.path = $path' \
  "$manifest" >"$WORK/stale-sidecar.json"
set +e
run_restore "$WORK/stale-sidecar.json" "$(live_json 'agent|name' "$WORK/home" setsid)" "$WORK/stale-sidecar.out"
stale_rc=$?
set -e
[[ "$stale_rc" -ne 0 ]] || fail 'restore accepted sidecar generation mismatch'
grep -q 'sidecar generation mismatch' "$WORK/stale-sidecar.out" ||
  fail 'sidecar generation mismatch was not diagnosed'

jq '.windows += [(.windows[0] | .kwin_window_id = "fake-agent-window-2")]' \
  "$manifest" >"$WORK/repeated-agent-view.json"
run_restore "$WORK/repeated-agent-view.json" "$(live_json 'agent|name' "$WORK/home" setsid)" "$WORK/repeated-agent-view.out" ||
  fail 'restore rejected distinct visual rows viewing the same agent target'
[[ "$(grep -c 'launch tmux window 7 desktop 1 at 10,20' "$WORK/repeated-agent-view.out")" -eq 2 ]] ||
  fail 'repeated agent view did not produce two deterministic dry-run launches'

jq '.windows += [.windows[0]]' "$manifest" >"$WORK/duplicate-visual.json"
set +e
run_restore "$WORK/duplicate-visual.json" "$(live_json 'agent|name' "$WORK/home" setsid)" "$WORK/dup-visual.out"
dup_visual_rc=$?
set -e
[[ "$dup_visual_rc" -ne 0 ]] || fail 'restore accepted duplicate visual identity'
grep -q 'duplicate visual identity kwin:fake-agent-window' "$WORK/dup-visual.out" ||
  fail 'duplicate visual identity was not diagnosed'

ambiguous_live="$(printf '%s\n%s\n' "$(live_json 'agent|name' "$WORK/home" setsid)" "$(live_json 'agent|other' "$WORK/home" setsid)")"
set +e
run_restore "$manifest" "$ambiguous_live" "$WORK/ambiguous-live.out"
ambiguous_live_rc=$?
set -e
[[ "$ambiguous_live_rc" -ne 0 ]] || fail 'restore accepted ambiguous live tmux target'
grep -q 'tmux window index 7 resolves to 2 current main-group targets' "$WORK/ambiguous-live.out" ||
  fail 'ambiguous live tmux target was not diagnosed'

shell_manifest="$WORK/shell-manifest.json"
jq --arg cwd "$WORK/shell-cwd" '
  .windows[0].cwd = $cwd |
  .windows[0].tmux_window_name = "shell|name" |
  .windows[0].identity_receipt = {
    assurance: "shell-weaker-index-cwd-command-name",
    agent_identity: null,
    shell_identity: {tmux_window_index: 7, cwd: $cwd, command: "bash", tmux_window_name: "shell|name"},
    capture_metadata: {tmux_session_id: "$old-session", tmux_window_id: "@old-window", title: "volatile-title"}
  }
' "$manifest" >"$shell_manifest"

run_restore "$shell_manifest" "$(live_json 'shell|name' "$WORK/shell-cwd" bash)" "$WORK/shell-ok.out" ||
  fail 'restore rejected matching shell receipt with delimiter in name'

set +e
run_restore "$shell_manifest" "$(live_json 'shell|name' "$WORK/shell-cwd" zsh)" "$WORK/shell-mismatch.out"
shell_mismatch_rc=$?
set -e
[[ "$shell_mismatch_rc" -ne 0 ]] || fail 'restore accepted shell command mismatch'
grep -q 'command mismatch expected=bash actual=zsh' "$WORK/shell-mismatch.out" ||
  fail 'shell command mismatch was not diagnosed'

echo 'PASS: desktop-layout uses sidecar-backed agent receipts, weaker shell receipts, and JSONL tmux evidence'
