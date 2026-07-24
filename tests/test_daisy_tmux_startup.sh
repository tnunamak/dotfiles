#!/usr/bin/env bash
# Isolated tmux regression test for Daisy's post-restore ownership handoff.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAIM="$ROOT/daisy-systemd/.local/bin/daisy-tmux-window-claim"
START="$ROOT/daisy-systemd/.local/bin/daisy-tmux-resilient-start"
DROP_IN="$ROOT/daisy-systemd/.config/systemd/user/daisy.service.d/20-tmux-restore.conf"
TMUX_BIN="$(command -v tmux)"
SOCKET="test-daisy-tmux-startup-$$"
WORK="$(mktemp -d "${HOME}/.tmp/daisy-tmux-startup.XXXXXX")"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
tmux_test() { "$TMUX_BIN" -L "$SOCKET" "$@"; }

cleanup() {
  tmux_test kill-session -t '=main' >/dev/null 2>&1 || true
  tmux_test kill-session -t '=stale' >/dev/null 2>&1 || true
  tmux_test kill-session -t '=appearing' >/dev/null 2>&1 || true
  rm -rf "$WORK"
}
trap cleanup EXIT

[[ -x "$CLAIM" && -x "$START" ]] || fail 'Daisy tmux helpers must be executable'
grep -qx 'After=tmux-restore.service' "$DROP_IN" || fail 'Daisy must start after tmux restore'
grep -qx 'Wants=tmux-restore.service' "$DROP_IN" || fail 'Daisy must pull in tmux restore'
! rg -q 'daisy\.service' "$ROOT/tmux/.config/systemd/user/tmux-restore.service" \
  || fail 'tmux restore must not order after Daisy (would form a cycle)'

# Restore state with two identically named Daisy windows.  The claim must keep
# the lowest restored index, mark it as owner, and preserve the other window
# under a non-conflicting diagnostic name.
tmux_test new-session -d -s main -n daisy 'exec bash'
tmux_test new-window -d -t '=main:1' -n work 'exec bash'
tmux_test new-window -d -t '=main:2' -n daisy 'exec bash'
DAISY_TMUX_BIN="$TMUX_BIN" DAISY_TMUX_SOCKET="$SOCKET" "$CLAIM" >/dev/null

rows="$(tmux_test list-windows -t '=main' -F $'#{window_index}\t#{window_name}\t#{@daisy_owner}')"
[[ "$(awk -F $'\t' '$2 == "daisy" { count++ } END { print count + 0 }' <<<"$rows")" == 1 ]] \
  || fail 'claim did not leave exactly one daisy window'
awk -F $'\t' '$1 == 0 && $2 == "daisy" && $3 == 1 { ok=1 } END { exit !ok }' <<<"$rows" \
  || fail 'claim did not assign the lowest duplicate index as Daisy owner'
awk -F $'\t' '$1 == 2 && $2 ~ /^daisy-restored-2-/ { ok=1 } END { exit !ok }' <<<"$rows" \
  || fail 'claim did not preserve the duplicate under a diagnostic name'

# A marker is only valid while its window is still named Daisy.  A stale owner
# marker on a user window must be cleared without renaming that window or
# stealing ownership from the real Daisy window.
tmux_test new-session -d -s stale -n work 'exec bash'
tmux_test set-window-option -t '=stale:0' @daisy_owner 1
tmux_test new-window -d -t '=stale:1' -n daisy 'exec bash'
DAISY_TMUX_BIN="$TMUX_BIN" DAISY_TMUX_SOCKET="$SOCKET" \
  DAISY_PARENT_TMUX_SESSION=stale "$CLAIM" >/dev/null

stale_rows="$(tmux_test list-windows -t '=stale' -F $'#{window_index}\t#{window_name}\t#{@daisy_owner}')"
awk -F $'\t' '$1 == 0 && $2 == "work" && $3 == "" { ok=1 } END { exit !ok }' <<<"$stale_rows" \
  || fail 'claim renamed the stale-marked work window or retained its marker'
awk -F $'\t' '$1 == 1 && $2 == "daisy" && $3 == 1 { ok=1 } END { exit !ok }' <<<"$stale_rows" \
  || fail 'claim did not assign ownership to the real Daisy window'

# A cold restore can make the parent session absent between service activation
# and layout creation.  The launcher retries that absence and starts only once
# the session exists, using the same isolated tmux socket.
(
  sleep 0.2
  tmux_test new-session -d -s appearing -n daisy 'exec bash'
) &
creator_pid=$!
DAISY_TMUX_BIN="$TMUX_BIN" DAISY_TMUX_SOCKET="$SOCKET" \
  DAISY_TMUX_CLAIM_COMMAND="$CLAIM" DAISY_PARENT_TMUX_SESSION=appearing \
  DAISY_TMUX_READY_ATTEMPTS=20 \
  DAISY_TMUX_READY_RETRY_DELAY=0.05 "$START" /usr/bin/touch "$WORK/started" \
  >/dev/null
wait "$creator_pid"
[[ -f "$WORK/started" ]] || fail 'launcher did not retry until the tmux session appeared'

printf 'PASS: Daisy tmux restore handoff is deterministic and retryable on isolated socket %s\n' "$SOCKET"
