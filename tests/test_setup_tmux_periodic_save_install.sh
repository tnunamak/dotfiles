#!/usr/bin/env bash
# Keep the periodic snapshot timer reproducible from a clean setup run.  This
# is intentionally static: invoking setup would install packages and alter the
# caller's user systemd manager.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT/setup.sh"
TIMER="$ROOT/tmux/.config/systemd/user/tmux-resurrect-periodic-save.timer"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

WATCHDOG_TIMER="$ROOT/tmux/.config/systemd/user/tmux-save-watchdog.timer"

# A bare `enable` only arms a timer for the NEXT user-manager lifecycle. That is
# indistinguishable from "working" until an unplanned reboot, and it is exactly
# how tmux state stopped being saved for ten days (timer enabled 2026-08-31
# without --now; it did not start until the 2026-09-10 reboot). Require --now.
enable_line='systemctl --user enable --now tmux-resurrect-periodic-save.timer 2>/dev/null || true'
grep -qF "$enable_line" "$SETUP" || fail 'setup.sh must enable --now the periodic save timer'
grep -q '^WantedBy=timers.target$' "$TIMER" || fail 'periodic save timer is not enableable under timers.target'
! rg -q 'systemctl --user enable .*tmux-resurrect-periodic-save\.service' "$SETUP" \
  || fail 'setup.sh must enable the timer, not its oneshot service'

# Guard the regression directly: the periodic timer must never be armed by a
# bare `enable` that lacks --now.
! rg -q 'systemctl --user enable (?!--now)[^|]*tmux-resurrect-periodic-save\.timer' --pcre2 "$SETUP" \
  || fail 'setup.sh enables the periodic save timer without --now'

# The freshness watchdog is what makes a future save outage visible at all, so
# it must be installed the same way.
watchdog_line='systemctl --user enable --now tmux-save-watchdog.timer 2>/dev/null || true'
grep -qF "$watchdog_line" "$SETUP" || fail 'setup.sh must enable --now the save-freshness watchdog timer'
grep -q '^WantedBy=timers.target$' "$WATCHDOG_TIMER" || fail 'watchdog timer is not enableable under timers.target'
! rg -q 'systemctl --user enable .*tmux-save-watchdog\.service' "$SETUP" \
  || fail 'setup.sh must enable the watchdog timer, not its oneshot service'

reload_line=$(rg -n '^[[:space:]]*systemctl --user daemon-reload$' "$SETUP" | head -1 | cut -d: -f1)
enable_line_number=$(rg -nF "$enable_line" "$SETUP" | head -1 | cut -d: -f1)
[[ -n "$reload_line" && -n "$enable_line_number" && "$reload_line" -lt "$enable_line_number" ]] \
  || fail 'setup.sh must reload user units before enabling the periodic timer'

printf 'PASS: setup starts the stowed periodic save and watchdog timers reproducibly\n'
