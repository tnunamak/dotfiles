#!/usr/bin/env bash
# Integration test for kitty 0.48 native sessions. It only closes test windows
# that were proven absent before spawn and recorded with their own socket/IDs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT="$ROOT/bin/.local/bin/desktop-layout-snapshot"
RESTORE="$ROOT/bin/.local/bin/desktop-layout-restore"
WORK="$(mktemp -d "$HOME/.tmp/desktop-layout-native-session.XXXXXX")"
CREATED="$WORK/created-set"
TEST_HOME="$WORK/home"
mkdir -p "$WORK/a" "$WORK/b" "$WORK/state" "$TEST_HOME"
: >"$CREATED"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# An incomplete or ambiguous created-set means no cleanup. Validate every ID
# against its private socket before sending any close request.
cleanup() {
  local kwin socket ids id tree
  [[ -s "$CREATED" ]] || return 0
  while IFS='|' read -r kwin socket ids; do
    [[ "$kwin" && -S "$socket" && "$ids" =~ ^[0-9]+(,[0-9]+)*$ ]] || {
      printf 'cleanup aborted: malformed created-set\n' >&2; return 0
    }
    tree="$(kitten @ --to "unix:$socket" ls 2>/dev/null)" || {
      printf 'cleanup aborted: unavailable private socket\n' >&2; return 0
    }
    for id in ${ids//,/ }; do
      jq -e --argjson id "$id" '[.[]|.tabs[]?.windows[]?.id] | index($id) != null' <<<"$tree" >/dev/null || {
        printf 'cleanup aborted: unproven inner kitty ID\n' >&2; return 0
      }
    done
  done <"$CREATED"
  while IFS='|' read -r _ socket ids; do
    for id in ${ids//,/ }; do
      kitten @ --to "unix:$socket" close-window --match "id:$id" || return 0
    done
  done <"$CREATED"
}
trap cleanup EXIT

SPAWNED_KWIN=""
spawn_test_instance() {
  local label="$1" cwd="$2" pre socket title pid kwin inner_ids second_inner
  pre="$WORK/pre-$label"; kdotool search --class kitty 2>/dev/null | sort -u >"$pre" || true
  title="desktop-layout-native-$label-$$"
  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" kitty --config NONE --override allow_remote_control=socket-only --single-instance=no --title "$title" \
    --listen-on 'unix:/tmp/kitty-{kitty_pid}' --directory "$cwd" sh -lc 'sleep 600' >"$WORK/$label.log" 2>&1 &
  pid=$!; socket="/tmp/kitty-$pid"; kwin=""
  for _ in $(seq 1 100); do
    while IFS= read -r candidate; do
      grep -Fxq -- "$candidate" "$pre" && continue
      [[ "$(kdotool getwindowpid "$candidate" 2>/dev/null || true)" == "$pid" ]] && { kwin="$candidate"; break 2; }
    done < <(kdotool search --class kitty 2>/dev/null | sort -u || true)
    sleep .1
  done
  [[ -n "$kwin" && -S "$socket" ]] || fail "could not prove new $label kitty window"
  inner_ids="$(kitten @ --to "unix:$socket" ls | jq -er 'if length == 1 then [.[0].tabs[]?.windows[]?.id] else empty end | if length == 1 then join(",") else empty end')" || fail "ambiguous $label inner kitty window"
  printf '%s|%s|%s\n' "$kwin" "$socket" "$inner_ids" >>"$CREATED"
  kitten @ --to "unix:$socket" set-tab-title --match "window_id:$inner_ids" "$title"
  second_inner="$(kitten @ --to "unix:$socket" launch --type tab --cwd "$WORK/b" sh -lc 'sleep 600')"
  [[ "$second_inner" =~ ^[0-9]+$ ]] || fail "could not create distinct-tab fixture"
  kitten @ --to "unix:$socket" set-tab-title --match "window_id:$second_inner" "$title"
  inner_ids="$(kitten @ --to "unix:$socket" ls | jq -er 'if length == 1 then [.[0].tabs[]?.windows[]?.id] else empty end | if length == 2 then join(",") else empty end')" || fail "ambiguous $label two-tab fixture"
  # Replace the just-recorded line with the complete, immediately-proven set.
  awk -F'|' -v kwin="$kwin" -v socket="$socket" -v ids="$inner_ids" 'BEGIN{OFS="|"} $1==kwin && $2==socket {$3=ids} {print}' "$CREATED" >"$CREATED.next"
  mv "$CREATED.next" "$CREATED"
  SPAWNED_KWIN="$kwin"
}

command -v kitty >/dev/null && command -v kitten >/dev/null && command -v jq >/dev/null && command -v kdotool >/dev/null || fail 'required tools unavailable'
[[ "$(kitty --version)" == 'kitty 0.48.'* ]] || fail 'requires kitty 0.48.x'

spawn_test_instance first "$WORK/a"; first="$SPAWNED_KWIN"
spawn_test_instance second "$WORK/a"; second="$SPAWNED_KWIN"
HOME="$TEST_HOME" DESKTOP_LAYOUT_TMUX_CLIENTS='' DESKTOP_LAYOUT_SCREEN_JSON='{"width":1920,"height":1080}' XDG_STATE_HOME="$WORK/state" "$SNAPSHOT"
manifest="$WORK/state/desktop-layout/manifest.json"
jq -e --arg first "$first" --arg second "$second" '
  ([.windows[] | select(.kwin_window_id == $first or .kwin_window_id == $second)]) as $rows |
  .version == 2 and ($rows | length == 2) and ($rows | all(.[]; (.native_session | type) == "string"))
' "$manifest" >/dev/null || fail 'snapshot did not produce two native-session rows'
jq --arg first "$first" --arg second "$second" '
  .windows |= map(select(.kwin_window_id == $first or .kwin_window_id == $second))
' "$manifest" >"$WORK/synthetic-manifest.json"

DESKTOP_LAYOUT_MANIFEST="$WORK/synthetic-manifest.json" \
DESKTOP_LAYOUT_CREATED_SET="$CREATED" \
DESKTOP_LAYOUT_TEST_SOCKET_DIR="$WORK/restore-sockets" \
DESKTOP_LAYOUT_WAIT_SECONDS=5 \
DESKTOP_LAYOUT_SCREEN='1920 1080' \
DESKTOP_LAYOUT_KITTY_CONFIG=NONE \
HOME="$TEST_HOME" \
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" \
"$RESTORE" --force

[[ "$(wc -l <"$CREATED")" -eq 4 ]] || fail 'restore did not record exactly two new created-set entries'
while IFS='|' read -r kwin socket ids; do
  [[ "$kwin" && -S "$socket" && "$ids" =~ ^[0-9]+(,[0-9]+)*$ ]] || fail 'malformed created-set entry'
  tree="$(kitten @ --to "unix:$socket" ls)"
  jq -e --arg a "$WORK/a" --arg b "$WORK/b" '
    [.[].tabs[]?.windows[]?] as $windows |
    ($windows | length) == 2 and any($windows[]; .cwd == $a) and any($windows[]; .cwd == $b) and
    all($windows[]; (.cmdline | type) == "array" and length > 0)
  ' <<<"$tree" >/dev/null || { jq '[.[].tabs[]?.windows[]? | {cwd,cmdline}]' <<<"$tree" >&2; fail 'restored native session lost cwd or command fidelity'; }
  [[ "$(kdotool get_desktop_for_window "$kwin")" =~ ^[0-9]+$ ]] || fail 'KWin placement did not resolve'
done <"$CREATED"

echo 'PASS: native session snapshot/restore preserved tabs, cwd, commands, and KWin placement'
