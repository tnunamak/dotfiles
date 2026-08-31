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

enable_line='systemctl --user enable tmux-restore.service desktop-layout-restore.service desktop-layout-snapshot.timer tmux-resurrect-periodic-save.timer 2>/dev/null || true'
grep -qF "$enable_line" "$SETUP" || fail 'setup.sh does not enable the periodic save timer'
grep -q '^WantedBy=timers.target$' "$TIMER" || fail 'periodic save timer is not enableable under timers.target'
! rg -q 'systemctl --user enable .*tmux-resurrect-periodic-save\.service' "$SETUP" \
  || fail 'setup.sh must enable the timer, not its oneshot service'

reload_line=$(rg -n '^[[:space:]]*systemctl --user daemon-reload$' "$SETUP" | head -1 | cut -d: -f1)
enable_line_number=$(rg -nF "$enable_line" "$SETUP" | head -1 | cut -d: -f1)
[[ -n "$reload_line" && -n "$enable_line_number" && "$reload_line" -lt "$enable_line_number" ]] \
  || fail 'setup.sh must reload user units before enabling the periodic timer'

printf 'PASS: setup enables the stowed periodic tmux save timer reproducibly\n'
