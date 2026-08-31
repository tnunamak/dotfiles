#!/usr/bin/env bash
# Pure/isolated desktop component checks for tmux resurrect transaction bundles.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/tmux/.config/tmux/scripts/resurrect-transaction-bundle"
SYSTEMD_RESTORE="$ROOT/tmux/.config/tmux/scripts/systemd-restore.sh"
DESKTOP_RESTORE="$ROOT/bin/.local/bin/desktop-layout-restore"
REAL_TMUX="$(command -v tmux)"
SOCKET="test-bundle-desktop-$$"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-bundle-desktop.XXXXXX")"
HOME_DIR="$WORK/home"
STATE_DIR="$WORK/state"
BIN_DIR="$WORK/bin"

cleanup() {
  "$REAL_TMUX" -L "$SOCKET" kill-session -t bootstrap >/dev/null 2>&1 || true
  chmod -R u+w "$WORK" >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

layout_file() {
  local path="$1"
  printf 'pane\tmain\t7\t1\t:* \t0\ttitle\t:%s\t1\tbash\t:bash\n' "$WORK/cwd" >"$path"
}

assistant_file() {
  local path="$1" session_id="$2"
  jq -n --arg sid "$session_id" --arg ns "$HOME_DIR/.claude-odl" \
    '{sessions:[{pane:"main:7.0",tool:"claude",session_id:$sid,cwd:"/work",env:{CLAUDE_CONFIG_DIR:$ns}}]}' >"$path"
}

manifest_file() {
  local path="$1" sidecar="$2" sidecar_hash="$3" session_id="$4" native="$5"
  jq -n \
    --arg sidecar "$sidecar" \
    --arg sidecar_hash "$sidecar_hash" \
    --arg sid "$session_id" \
    --arg ns "$HOME_DIR/.claude-odl" \
    --arg native "$native" \
    '{
      version:2,
      captured_at:"2026-08-30T23:00:00Z",
      screen:{width:1920,height:1080},
      windows:[{
        kwin_window_id:"kwin-old",
        virtual_desktop:2,
        position:{x:10,y:20},
        size:{width:300,height:200},
        cwd:"/work",
        is_tmux:true,
        tmux_session:"main",
        tmux_window_index:7,
        tmux_window_name:"agent",
        native_session:$native,
        identity_source:"kitty_native_session",
        identity_receipt:{
          assurance:"agent-sidecar",
          agent_identity:{
            sidecar:{path:$sidecar,sha256:$sidecar_hash},
            provider:"claude",
            assistant_session_id:$sid,
            cwd:"/work",
            config_namespace:$ns,
            pane:"main:7.0"
          },
          shell_identity:{tmux_window_index:7,cwd:"/work",command:"setsid",tmux_window_name:"agent"},
          capture_metadata:{native_session:$native}
        }
      }]
    }' >"$path"
}

mkdir -p "$HOME_DIR/.tmux/resurrect" "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts" "$HOME_DIR/.config/tmux/scripts" "$STATE_DIR/desktop-layout/kitty-sessions" "$BIN_DIR" "$WORK/cwd"
ln -s "$CLI" "$HOME_DIR/.config/tmux/scripts/resurrect-transaction-bundle"

cat >"$BIN_DIR/tmux" <<'EOF'
#!/usr/bin/env bash
exec "$REAL_TMUX" -L "$TEST_TMUX_SOCKET" "$@"
EOF
chmod +x "$BIN_DIR/tmux"

cat >"$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/restore.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cp "$(readlink -f "$HOME/.tmux/resurrect/last")" "$TEST_RESTORE_LAYOUT_COPY"
EOF
chmod +x "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

export HOME="$HOME_DIR"
export XDG_STATE_HOME="$STATE_DIR"
export PATH="$BIN_DIR:/usr/bin:/bin"
export REAL_TMUX TEST_TMUX_SOCKET="$SOCKET"
export TEST_RESTORE_LAYOUT_COPY="$WORK/restored-layout.txt"
export TMUX_RESURRECT_DIR="$HOME_DIR/.tmux/resurrect"
export TMUX_RESURRECT_BUNDLE_NOW_ISO="2026-08-30T23:00:00Z"

layout="$WORK/tmux_resurrect_A.txt"
old_sidecar="$WORK/assistant-old.json"
new_sidecar="$WORK/assistant-new.json"
native="$WORK/native original.kitty-session"
manifest="$STATE_DIR/desktop-layout/manifest.json"
layout_file "$layout"
assistant_file "$old_sidecar" "session-ok"
assistant_file "$new_sidecar" "session-ok"
printf 'native-session-v1\n' >"$native"
old_hash="$(sha256sum "$old_sidecar" | awk '{print $1}')"
new_hash="$(sha256sum "$new_sidecar" | awk '{print $1}')"
manifest_file "$manifest" "$old_sidecar" "$old_hash" "session-ok" "$native"
good_manifest="$WORK/good-manifest.json"
cp "$manifest" "$good_manifest"
mutation_hook="$WORK/mutate-manifest-after-copy.sh"
cat >"$mutation_hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
jq '.windows[0].identity_receipt.agent_identity.assistant_session_id = "mutated-after-copy" |
    .windows[0].native_session = "mutated-after-copy.kitty-session" |
    .windows[0].identity_receipt.capture_metadata.native_session = "mutated-after-copy.kitty-session"' \
  "$1" >"$1.tmp"
mv "$1.tmp" "$1"
EOF
chmod +x "$mutation_hook"

bundle_path="$(env TMUX_RESURRECT_BUNDLE_AFTER_DESKTOP_COPY_HOOK="$mutation_hook" \
  "$CLI" commit --layout "$layout" --assistant "$new_sidecar" --desktop-manifest "$manifest" --id desktop-ok)"
bundle_manifest="$bundle_path/bundle.json"
jq -e '.components.desktop.status == "bundled" and .components.desktop.native_count == 1' "$bundle_manifest" >/dev/null \
  || fail 'desktop component was not bundled'
desktop_component="$(jq -r '.components.desktop.file' "$bundle_manifest")"
native_component="$(jq -r '.components.desktop.native_sessions[0].file' "$bundle_manifest")"
jq -e --arg new_hash "$new_hash" --arg sidecar "$HOME_DIR/.tmux/resurrect/assistant-sessions.json" '
  .windows[0].identity_receipt.agent_identity.sidecar == {path:$sidecar, sha256:$new_hash} and
  (.windows[0].native_session | contains("/desktop-layout/kitty-sessions/native-")) and
  .windows[0].identity_receipt.capture_metadata.native_session == .windows[0].native_session
' "$bundle_path/$desktop_component" >/dev/null || fail 'desktop manifest was not rebound to accepted sidecar/native activation paths'
! grep -q 'mutated-after-copy' "$bundle_path/$desktop_component" \
  || fail 'desktop bundle used manifest content written after staged copy'
[[ "$(sha256sum "$bundle_path/$native_component" | awk '{print $1}')" == "$(sha256sum "$native" | awk '{print $1}')" ]] \
  || fail 'native session was not copied with integrity'

printf 'raw newer desktop\n' >"$STATE_DIR/desktop-layout/manifest.json"
printf 'raw newer native\n' >"$STATE_DIR/desktop-layout/kitty-sessions/raw.kitty-session"
"$REAL_TMUX" -L "$SOCKET" new-session -d -s bootstrap 'exec bash'
bash "$SYSTEMD_RESTORE"
grep -q '"session-ok"' "$STATE_DIR/desktop-layout/manifest.json" || fail 'bundled desktop manifest was not activated'
! grep -q 'raw newer' "$STATE_DIR/desktop-layout/manifest.json" || fail 'newer raw desktop manifest survived activation'
activated_native="$(jq -r '.windows[0].native_session' "$STATE_DIR/desktop-layout/manifest.json")"
[[ "$(cat "$activated_native")" == "native-session-v1" ]] || fail 'bundled native session was not activated'
grep -q 'activated bundled desktop manifest for bundle desktop-ok' "$HOME_DIR/.tmux/resurrect/systemd-restore.log" \
  || fail 'desktop activation was not logged'
prior_last="$(readlink "$HOME_DIR/.tmux/resurrect/last")"
prior_assistant_hash="$(sha256sum "$HOME_DIR/.tmux/resurrect/assistant-sessions.json" | awk '{print $1}')"
prior_receipt_bundle="$(jq -r '.bundle_id' "$STATE_DIR/desktop-layout/.bundle-activation.json")"

layout_fail="$WORK/tmux_resurrect_fail.txt"
layout_file "$layout_fail"
printf 'pane\tmain\t8\t1\t:* \t0\ttitle\t:%s\t1\tbash\t:bash\n' "$WORK/cwd" >>"$layout_fail"
"$CLI" commit --layout "$layout_fail" --assistant "$new_sidecar" --desktop-manifest "$good_manifest" --id desktop-fail >/dev/null
if env TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_STAGE=1 bash "$SYSTEMD_RESTORE" >/dev/null 2>&1; then
  fail 'injected activation failure did not fail systemd restore'
fi
[[ "$(readlink "$HOME_DIR/.tmux/resurrect/last")" == "$prior_last" ]] \
  || fail 'activation failure advanced tmux last symlink'
[[ "$(sha256sum "$HOME_DIR/.tmux/resurrect/assistant-sessions.json" | awk '{print $1}')" == "$prior_assistant_hash" ]] \
  || fail 'activation failure advanced assistant sidecar'
[[ "$(jq -r '.bundle_id' "$STATE_DIR/desktop-layout/.bundle-activation.json")" == "$prior_receipt_bundle" ]] \
  || fail 'activation failure advanced desktop activation receipt'
if find "$HOME_DIR/.tmux/resurrect" "$STATE_DIR/desktop-layout" -name '*.tmp.*' -o -name '.bundle-activation-plan.*' -o -name '.last.tmp.*' | grep -q .; then
  fail 'activation failure leaked staged temp files'
fi

bad_manifest="$WORK/bad-manifest.json"
manifest_file "$bad_manifest" "$old_sidecar" "$old_hash" "different-session" "$native"
"$CLI" commit --layout "$layout" --assistant "$new_sidecar" --desktop-manifest "$bad_manifest" --id desktop-mismatch >/dev/null
jq -e '.components.desktop.status == "not-bundled" and (.components.desktop.reason | contains("not present exactly once"))' \
  "$HOME_DIR/.tmux/resurrect/transactions/desktop-mismatch/bundle.json" >/dev/null \
  || fail 'mismatched desktop agent identity did not produce no-desktop receipt'
printf '{"version":2,"windows":[{"is_tmux":false,"virtual_desktop":9,"position":{"x":0,"y":0},"size":{"width":1,"height":1},"cwd":"raw-stale"}]}\n' \
  >"$STATE_DIR/desktop-layout/manifest.json"
bash "$SYSTEMD_RESTORE"
[[ -s "$STATE_DIR/desktop-layout/.no-desktop-receipt.json" ]] || fail 'no-desktop activation receipt missing'
desktop_restore_out="$WORK/no-desktop-restore.out"
"$DESKTOP_RESTORE" --dry-run >"$desktop_restore_out" 2>&1
grep -q 'transaction bundle has no desktop component; skipping desktop restore' "$desktop_restore_out" \
  || fail 'desktop restore did not skip no-desktop transaction before raw manifest use'

missing_native_manifest="$WORK/missing-native-manifest.json"
manifest_file "$missing_native_manifest" "$old_sidecar" "$old_hash" "session-ok" "$WORK/missing.kitty-session"
"$CLI" commit --layout "$layout" --assistant "$new_sidecar" --desktop-manifest "$missing_native_manifest" --id desktop-missing-native >/dev/null
jq -e '.components.desktop.status == "not-bundled" and (.components.desktop.reason | contains("native session missing"))' \
  "$HOME_DIR/.tmux/resurrect/transactions/desktop-missing-native/bundle.json" >/dev/null \
  || fail 'missing native session did not produce no-desktop receipt'

corrupt_bundle="$("$CLI" commit --layout "$layout" --assistant "$new_sidecar" --desktop-manifest "$good_manifest" --id desktop-native-corrupt)"
corrupt_native="$(jq -r '.components.desktop.native_sessions[0].file' "$corrupt_bundle/bundle.json")"
chmod -R u+w "$corrupt_bundle"
printf 'corrupted native session\n' >"$corrupt_bundle/$corrupt_native"
if "$CLI" resolve >"$WORK/corrupt-native.out" 2>&1; then
  fail 'corrupt bundled native session resolved successfully'
fi
grep -q 'desktop native session hash mismatch' "$WORK/corrupt-native.out" \
  || fail 'corrupt native session was not diagnosed'

printf 'PASS: transaction bundle rebinds desktop receipts, activates native sessions, and rejects mismatched desktop identity\n'
