#!/usr/bin/env bash
# Pure/isolated desktop component checks for tmux resurrect transaction bundles.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/tmux/.config/tmux/scripts/resurrect-transaction-bundle"
SYSTEMD_RESTORE="$ROOT/tmux/.config/tmux/scripts/systemd-restore.sh"
DESKTOP_RESTORE="$ROOT/bin/.local/bin/desktop-layout-restore"
REAL_TMUX="$(command -v tmux)"
REAL_SYNC="$(command -v sync)"
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

assert_no_activation_artifacts() {
  if find "$HOME_DIR/.tmux/resurrect" "$STATE_DIR/desktop-layout" \
    \( -name '*.tmp.*' -o -name '.bundle-activation-plan.*' -o -name '.last.tmp.*' \) -print -quit | grep -q .; then
    fail 'activation left staged temp files'
  fi
}

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

cat >"$BIN_DIR/sync" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_SYNC_LOG"
exec "$REAL_SYNC" "$@"
EOF
chmod +x "$BIN_DIR/sync"

cat >"$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/restore.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
touch "$TEST_RESTORE_LAUNCH_MARKER"
cp "$(readlink -f "$HOME/.tmux/resurrect/last")" "$TEST_RESTORE_LAYOUT_COPY"
EOF
chmod +x "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

export HOME="$HOME_DIR"
export XDG_STATE_HOME="$STATE_DIR"
export PATH="$BIN_DIR:/usr/bin:/bin"
export REAL_TMUX TEST_TMUX_SOCKET="$SOCKET"
export REAL_SYNC
export TEST_RESTORE_LAYOUT_COPY="$WORK/restored-layout.txt"
export TEST_RESTORE_LAUNCH_MARKER="$WORK/restore-launched"
export TEST_SYNC_LOG="$WORK/sync.log"
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
live_last="$(readlink "$HOME_DIR/.tmux/resurrect/last")"
live_layout_hash="$(sha256sum "$HOME_DIR/.tmux/resurrect/$live_last" | awk '{print $1}')"
live_assistant_hash="$(sha256sum "$HOME_DIR/.tmux/resurrect/assistant-sessions.json" | awk '{print $1}')"
live_manifest_hash="$(sha256sum "$STATE_DIR/desktop-layout/manifest.json" | awk '{print $1}')"
live_native_path="$(jq -r '.windows[0].native_session' "$STATE_DIR/desktop-layout/manifest.json")"
live_native_hash="$(sha256sum "$live_native_path" | awk '{print $1}')"
live_receipt_hash="$(sha256sum "$STATE_DIR/desktop-layout/.bundle-activation.json" | awk '{print $1}')"
rm -f "$TEST_RESTORE_LAUNCH_MARKER"
"$REAL_TMUX" -L "$SOCKET" new-window -d -t bootstrap -n live-one 'exec bash'
"$REAL_TMUX" -L "$SOCKET" new-window -d -t bootstrap -n live-two 'exec bash'
bash "$SYSTEMD_RESTORE"
[[ "$(readlink "$HOME_DIR/.tmux/resurrect/last")" == "$live_last" ]] || fail 'live tmux invocation changed last'
[[ "$(sha256sum "$HOME_DIR/.tmux/resurrect/$live_last" | awk '{print $1}')" == "$live_layout_hash" ]] \
  || fail 'live tmux invocation changed raw layout'
[[ "$(sha256sum "$HOME_DIR/.tmux/resurrect/assistant-sessions.json" | awk '{print $1}')" == "$live_assistant_hash" ]] \
  || fail 'live tmux invocation changed raw assistant sidecar'
[[ "$(sha256sum "$STATE_DIR/desktop-layout/manifest.json" | awk '{print $1}')" == "$live_manifest_hash" ]] \
  || fail 'live tmux invocation changed raw desktop manifest'
[[ "$(sha256sum "$live_native_path" | awk '{print $1}')" == "$live_native_hash" ]] \
  || fail 'live tmux invocation changed raw native session'
[[ "$(sha256sum "$STATE_DIR/desktop-layout/.bundle-activation.json" | awk '{print $1}')" == "$live_receipt_hash" ]] \
  || fail 'live tmux invocation changed desktop receipt'
[[ ! -e "$STATE_DIR/desktop-layout/.no-desktop-receipt.json" ]] || fail 'live tmux invocation wrote a no-desktop receipt'
[[ ! -e "$TEST_RESTORE_LAUNCH_MARKER" ]] || fail 'tmux restore launched on a live server'
"$REAL_TMUX" -L "$SOCKET" kill-window -t bootstrap:live-one
"$REAL_TMUX" -L "$SOCKET" kill-window -t bootstrap:live-two
layout_fail="$WORK/tmux_resurrect_fail.txt"
layout_file "$layout_fail"
printf 'pane\tmain\t8\t1\t:* \t0\ttitle\t:%s\t1\tbash\t:bash\n' "$WORK/cwd" >>"$layout_fail"
"$CLI" commit --layout "$layout_fail" --assistant "$new_sidecar" --desktop-manifest "$good_manifest" --id desktop-fail >/dev/null
bundle_fail="$HOME_DIR/.tmux/resurrect/transactions/desktop-fail"
fail_layout_name="$(jq -r '.components.layout.file' "$bundle_fail/bundle.json")"
fail_desktop_hash="$(jq -r '.components.desktop.sha256' "$bundle_fail/bundle.json")"
activation_component_count="$(jq -r '(.components.desktop.native_count + 1) + ([.components | keys[] | select(. == "layout" or . == "assistant")] | length)' "$bundle_fail/bundle.json")"
[[ "$activation_component_count" =~ ^[1-9][0-9]*$ ]] || fail 'desktop activation component count is invalid'

assert_bundle_repaired() {
  bash "$SYSTEMD_RESTORE"
  [[ "$(sha256sum "$HOME_DIR/.tmux/resurrect/$fail_layout_name" | awk '{print $1}')" == "$(jq -r '.components.layout.sha256' "$bundle_fail/bundle.json")" ]] \
    || fail 'subsequent activation did not repair the raw tmux layout'
  [[ "$(sha256sum "$HOME_DIR/.tmux/resurrect/assistant-sessions.json" | awk '{print $1}')" == "$(jq -r '.components.assistant.sha256' "$bundle_fail/bundle.json")" ]] \
    || fail 'subsequent activation did not repair the raw assistant sidecar'
  [[ "$(sha256sum "$STATE_DIR/desktop-layout/manifest.json" | awk '{print $1}')" == "$fail_desktop_hash" ]] \
    || fail 'subsequent activation did not repair the raw desktop manifest'
  while IFS= read -r native_row; do
    native_file="$(jq -r '.file' <<<"$native_row")"
    native_hash="$(jq -r '.sha256' <<<"$native_row")"
    native_activation="$(jq -r '.activation_path' <<<"$native_row")"
    [[ -f "$native_activation" && "$(sha256sum "$native_activation" | awk '{print $1}')" == "$native_hash" ]] \
      || fail 'subsequent activation did not repair a raw native session'
    [[ "$native_activation" == "$STATE_DIR/desktop-layout/kitty-sessions/$native_file" ]] \
      || fail 'subsequent activation used an unexpected native-session path'
  done < <(jq -c '.components.desktop.native_sessions[]?' "$bundle_fail/bundle.json")
  [[ "$(jq -r '.components.desktop.activation_path' "$bundle_fail/bundle.json")" == "$STATE_DIR/desktop-layout/manifest.json" ]] \
    || fail 'bundle declared an unexpected desktop manifest activation path'
  jq -e --arg bundle_id desktop-fail --arg manifest "$STATE_DIR/desktop-layout/manifest.json" --arg sha256 "$fail_desktop_hash" '
    .status == "activated" and .bundle_id == $bundle_id and .manifest == {path:$manifest, sha256:$sha256}
  ' "$STATE_DIR/desktop-layout/.bundle-activation.json" >/dev/null \
    || fail 'subsequent activation did not write the desktop receipt last'
  [[ "$(readlink "$HOME_DIR/.tmux/resurrect/last")" == "$fail_layout_name" ]] \
    || fail 'subsequent activation did not repair the tmux last pointer'
  assert_no_activation_artifacts
}

stale_dest="$HOME_DIR/.tmux/resurrect/$fail_layout_name"
stale_tmp="${stale_dest}.tmp.stale"
stale_plan="$HOME_DIR/.tmux/resurrect/.bundle-activation-plan.stale"
stale_receipt_tmp="$STATE_DIR/desktop-layout/.bundle-activation.json.tmp.stale"
printf 'stale activation temporary\n' >"$stale_tmp"
printf '%s\t%s\n' "$stale_tmp" "$stale_dest" >"$stale_plan"
printf 'stale receipt temporary\n' >"$stale_receipt_tmp"
ln -s "$fail_layout_name" "$HOME_DIR/.tmux/resurrect/.last.tmp.stale"
rm -f "$TEST_RESTORE_LAUNCH_MARKER"
if env TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_STAGE=1 bash "$SYSTEMD_RESTORE" >/dev/null 2>&1; then
  fail 'injected post-stage activation failure did not fail systemd restore'
fi
[[ ! -e "$TEST_RESTORE_LAUNCH_MARKER" ]] || fail 'tmux restore launched after post-stage failure'
assert_no_activation_artifacts
assert_bundle_repaired

for component_index in $(seq 1 "$activation_component_count"); do
  rm -f "$TEST_RESTORE_LAUNCH_MARKER"
  : >"$TEST_SYNC_LOG"
  if env TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_COMPONENT="$component_index" bash "$SYSTEMD_RESTORE" >/dev/null 2>&1; then
    fail "injected component-$component_index activation failure did not fail systemd restore"
  fi
  [[ ! -e "$STATE_DIR/desktop-layout/.bundle-activation.json" && ! -e "$STATE_DIR/desktop-layout/.no-desktop-receipt.json" ]] \
    || fail "component-$component_index interruption left a desktop receipt"
  [[ ! -e "$TEST_RESTORE_LAUNCH_MARKER" ]] || fail "tmux restore launched after component-$component_index failure"
  if (( component_index == 1 )); then
    state_sync_line="$(grep -nFx -- "-f $STATE_DIR/desktop-layout" "$TEST_SYNC_LOG" | head -1 | cut -d: -f1)"
    raw_sync_line="$(grep -nFx -- "-f $HOME_DIR/.tmux/resurrect/$fail_layout_name" "$TEST_SYNC_LOG" | head -1 | cut -d: -f1)"
    [[ "$state_sync_line" =~ ^[0-9]+$ && "$raw_sync_line" =~ ^[0-9]+$ && "$state_sync_line" -lt "$raw_sync_line" ]] \
      || fail 'receipt removal was not fsynced before the first raw component commit'
    if "$DESKTOP_RESTORE" --dry-run >"$WORK/missing-receipt-restore.out" 2>&1; then
      fail 'desktop restore accepted raw files without an activation receipt'
    fi
    grep -q 'transaction state exists but no bundled desktop activation receipt exists' "$WORK/missing-receipt-restore.out" \
      || fail 'desktop restore did not explain the missing activation receipt'
  fi
  assert_no_activation_artifacts
  assert_bundle_repaired
done

rm -f "$TEST_RESTORE_LAUNCH_MARKER"
if env TMUX_RESURRECT_ACTIVATION_FAIL_AFTER_LAST=1 bash "$SYSTEMD_RESTORE" >/dev/null 2>&1; then
  fail 'injected post-last activation failure did not fail systemd restore'
fi
[[ ! -e "$STATE_DIR/desktop-layout/.bundle-activation.json" && ! -e "$STATE_DIR/desktop-layout/.no-desktop-receipt.json" ]] \
  || fail 'post-last interruption left a desktop receipt'
[[ ! -e "$TEST_RESTORE_LAUNCH_MARKER" ]] || fail 'tmux restore launched after post-last failure'
assert_no_activation_artifacts
assert_bundle_repaired

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

traversal_bundle="$("$CLI" commit --layout "$layout" --assistant "$new_sidecar" --desktop-manifest "$good_manifest" --id desktop-native-traversal)"
traversal_path="$STATE_DIR/desktop-layout/kitty-sessions/../escaped.kitty-session"
chmod -R u+w "$traversal_bundle"
for traversal_metadata in "$traversal_bundle/bundle.json" "$HOME_DIR/.tmux/resurrect/transactions/last-good.json"; do
  jq --arg path "$traversal_path" '.components.desktop.native_sessions[0].activation_path = $path' "$traversal_metadata" >"${traversal_metadata}.tmp"
  mv "${traversal_metadata}.tmp" "$traversal_metadata"
done
"$CLI" resolve >/dev/null || fail 'resolver rejected the malicious activation path before activation validation'
rm -f "$TEST_RESTORE_LAUNCH_MARKER"
if bash "$SYSTEMD_RESTORE" >/dev/null 2>&1; then
  fail 'traversal activation path was accepted'
fi
[[ ! -e "$STATE_DIR/desktop-layout/escaped.kitty-session" ]] \
  || fail 'traversal activation path wrote outside kitty-sessions'
[[ ! -e "$TEST_RESTORE_LAUNCH_MARKER" ]] || fail 'tmux restore launched after traversal-path rejection'

printf 'PASS: transaction bundle preserves live tmux state, fails closed and repairs interrupted activation, activates native sessions, and rejects unsafe desktop identity paths\n'
