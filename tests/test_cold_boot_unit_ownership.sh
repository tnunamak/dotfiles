#!/usr/bin/env bash
# Keep boot-only assumptions declarative and independently inspectable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT/setup.sh"
RESTORE_UNIT="$ROOT/tmux/.config/systemd/user/desktop-layout-restore.service"

# The user manager has a deliberately minimal PATH. kdotool is Cargo-managed.
grep -Fxq 'Environment="PATH=%h/.cargo/bin:/usr/local/bin:/usr/bin:/bin"' "$RESTORE_UNIT"
# Starting the graphical target is part of this unit's contract: PATH alone
# cannot make kdotool useful before Plasma has exported its display session.
grep -Fxq 'Wants=graphical-session.target tmux.service tmux-restore.service' "$RESTORE_UNIT"

# The distro-owned ydotool.service is the single owner. Retire only the
# legacy custom ydotoold.service enablement, never the packaged service.
grep -Fxq '  systemctl --user disable ydotoold.service 2>/dev/null || true' "$SETUP"
if rg -n 'systemctl --user disable( --now)? ydotool\.service' "$SETUP"; then
  echo 'setup must not disable or stop the packaged ydotool.service' >&2
  exit 1
fi
if rg -n 'systemctl --user disable --now ydotoold\.service' "$SETUP"; then
  echo 'setup must not stop the legacy ydotoold.service during installation' >&2
  exit 1
fi

echo 'PASS: cold-boot unit ownership is explicit'
