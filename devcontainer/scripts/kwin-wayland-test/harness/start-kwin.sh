#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Starts a headless KWin Wayland
# session (virtual backend) under its own D-Bus session bus, matching the
# kwin-mcp pattern: `dbus-run-session kwin_wayland --virtual`.
#
# Writes the resulting WAYLAND_DISPLAY / DBUS_SESSION_BUS_ADDRESS to
# $STATE_DIR/env so later exec'd commands (kdotool, kitty) can source them.
set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.local/state/kwin-test}"
mkdir -p "$STATE_DIR"
LOG="$STATE_DIR/kwin.log"
ENV_FILE="$STATE_DIR/env"

SCREEN_WIDTH="${SCREEN_WIDTH:-1920}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-1080}"

echo "[start-kwin] HOME=$HOME UID=$(id -u) XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-unset}"

# dbus-run-session gives kwin_wayland its own private session bus (kwin-mcp's
# isolation pattern) so we don't depend on a full systemd --user dbus setup
# for the compositor itself, only for outer plumbing (XDG_RUNTIME_DIR perms).
#
# setsid + full fd detachment: this script is normally invoked via a plain
# (non-detached) `docker exec`, whose process group dies when the exec
# session ends. Without setsid + closed stdio, kwin_wayland would be killed
# the moment this script's `docker exec` call returns.
rm -f "$ENV_FILE"
setsid bash -c '
  dbus-run-session -- bash -c "
    echo DBUS_SESSION_BUS_ADDRESS=\$DBUS_SESSION_BUS_ADDRESS > \"'"$ENV_FILE"'\"
    exec kwin_wayland --virtual --width '"$SCREEN_WIDTH"' --height '"$SCREEN_HEIGHT"' --no-lockscreen --no-global-shortcuts
  "
' > "$LOG" 2>&1 < /dev/null &
disown
KWIN_PID=$!
echo "$KWIN_PID" > "$STATE_DIR/kwin.pid"

# Wait for kwin to announce its WAYLAND_DISPLAY. It logs
# "Connection to the Wayland server established" but the most reliable
# signal is env_file appearing + a socket showing up in XDG_RUNTIME_DIR.
for _ in $(seq 1 100); do
  if [[ -s "$ENV_FILE" ]]; then
    # kwin_wayland writes its chosen socket name into the log via
    # "Using Wayland display <name>"; also check for wayland-N sockets.
    sock="$(grep -oE 'wayland-[0-9]+' "$LOG" | head -1 || true)"
    if [[ -n "$sock" && -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$sock" ]]; then
      echo "WAYLAND_DISPLAY=$sock" >> "$ENV_FILE"
      echo "[start-kwin] ready: $sock"
      exit 0
    fi
  fi
  if ! kill -0 "$KWIN_PID" 2>/dev/null; then
    echo "[start-kwin] ERROR: kwin_wayland exited early" >&2
    cat "$LOG" >&2
    exit 1
  fi
  sleep 0.2
done

echo "[start-kwin] ERROR: timed out waiting for wayland socket" >&2
cat "$LOG" >&2
exit 1
