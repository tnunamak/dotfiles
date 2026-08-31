#!/usr/bin/env bash
# Validate the systemd timer and its local save helper without loading a real
# tmux server or changing the live user manager.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/tmux/.config/tmux/scripts/tmux-resurrect-periodic-save"
SERVICE="$ROOT/tmux/.config/systemd/user/tmux-resurrect-periodic-save.service"
TIMER="$ROOT/tmux/.config/systemd/user/tmux-resurrect-periodic-save.timer"
RESTORE="$ROOT/tmux/.config/systemd/user/tmux-restore.service"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-periodic-save.XXXXXX")"
HOME_DIR="$WORK/home"
BIN_DIR="$WORK/bin"

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Model the documented systemd.unit contract relevant to this unit: Requisite
# does not start a dependency and, with After, blocks save until both existing
# units are active. We use a model rather than a user-manager integration test
# because starting a user unit would alter the developer's live tmux manager.
start_is_permitted_after_restore() {
  local tmux_state=$1 restore_state=$2
  local requisite after
  requisite=$(sed -n 's/^Requisite=//p' "$SERVICE")
  after=$(sed -n 's/^After=//p' "$SERVICE")
  if [[ " $requisite " == *' tmux.service '* && " $requisite " == *' tmux-restore.service '* \
    && " $after " == *' tmux.service '* && " $after " == *' tmux-restore.service '* \
    && ( "$tmux_state" != active || "$restore_state" != active ) ]]; then
    return 1
  fi
}

mkdir -p "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts" "$BIN_DIR"
cat >"$BIN_DIR/tmux" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == -N ]] && shift
[[ "${1:-}" == has-session ]] && [[ "${TEST_TMUX_PRESENT:-1}" == 1 ]]
EOF
cat >"$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/save.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'save %s\n' "$*" >>"$TEST_SAVE_RUNS"
EOF
chmod +x "$BIN_DIR/tmux" "$HOME_DIR/.tmux/plugins/tmux-resurrect/scripts/save.sh"

HOME="$HOME_DIR" PATH="$BIN_DIR:/usr/bin:/bin" TEST_SAVE_RUNS="$WORK/runs" "$HELPER"
[[ "$(wc -l <"$WORK/runs")" == 1 ]] || fail 'helper did not invoke one quiet save'
grep -q '^save quiet$' "$WORK/runs" || fail 'helper did not use resurrect quiet save contract'

mkdir -p "$HOME_DIR/.tmux/resurrect"
exec 9>"$HOME_DIR/.tmux/resurrect/periodic-save.lock"
flock -n 9
HOME="$HOME_DIR" PATH="$BIN_DIR:/usr/bin:/bin" TEST_SAVE_RUNS="$WORK/runs" "$HELPER"
exec 9>&-
[[ "$(wc -l <"$WORK/runs")" == 1 ]] || fail 'helper ran despite periodic-trigger lock'

HOME="$HOME_DIR" PATH="$BIN_DIR:/usr/bin:/bin" TEST_SAVE_RUNS="$WORK/runs" TEST_TMUX_PRESENT=0 "$HELPER"
[[ "$(wc -l <"$WORK/runs")" == 1 ]] || fail 'helper saved without a default-socket tmux server'

stage_service="$WORK/tmux-resurrect-periodic-save.service"
stage_restore="$WORK/tmux-restore.service"
stage_tmux="$WORK/tmux.service"
mkdir -p "$HOME_DIR/.config/tmux/scripts"
ln -s "$HELPER" "$HOME_DIR/.config/tmux/scripts/tmux-resurrect-periodic-save"
sed "s|%h|$HOME_DIR|g" "$SERVICE" >"$stage_service"
# Requisite makes the verifier resolve both prerequisite unit names. Stage
# minimal local definitions so this stays isolated from the real user manager.
cp "$RESTORE" "$stage_restore"
cat >"$stage_tmux" <<'EOF'
[Service]
Type=simple
ExecStart=/usr/bin/sleep infinity
EOF
systemd-analyze verify "$stage_tmux" "$stage_restore" "$stage_service" "$TIMER" >/dev/null \
  || fail 'systemd units did not verify'
grep -q '^WantedBy=timers.target$' "$TIMER" || fail 'timer is not installable under timers.target'
# Requisite does not pull in tmux or restore. Together with After it refuses
# save if either is inactive or restore failed. RemainAfterExit keeps a
# successful restore active so normal five-minute triggers do not replay it.
# The monotonic schedule does not create an offline calendar catch-up save.
grep -q '^Requisite=tmux.service tmux-restore.service$' "$SERVICE" || fail 'periodic save does not require an active restore'
! grep -qE '^(Wants|Requires)=' "$SERVICE" || fail 'periodic save must not start tmux or restore'
grep -q '^After=tmux.service tmux-restore.service$' "$SERVICE" || fail 'periodic save is not ordered after restore'
start_is_permitted_after_restore active active || fail 'model blocked save after successful restore'
! start_is_permitted_after_restore inactive active || fail 'model started a deliberately stopped tmux'
! start_is_permitted_after_restore active failed || fail 'model allowed save after failed restore'
grep -q '^RemainAfterExit=yes$' "$RESTORE" || fail 'restore completion is not durable for periodic ordering'
grep -q '^OnBootSec=5min$' "$TIMER" || fail 'timer does not wait five minutes after boot'
grep -q '^OnUnitActiveSec=5min$' "$TIMER" || fail 'timer does not repeat every five minutes'
! grep -q '^Persistent=' "$TIMER" || fail 'monotonic timer must not request calendar catch-up'

printf 'PASS: periodic tmux save helper is locked, server-scoped, and installable\n'
