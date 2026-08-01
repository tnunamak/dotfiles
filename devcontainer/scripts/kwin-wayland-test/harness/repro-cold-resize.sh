#!/usr/bin/env bash
# Runs INSIDE the container as the test user (KWin virtual session already
# running, DBUS_SESSION_BUS_ADDRESS sourced from $STATE_DIR/dbus_addr).
#
# Mimics desktop-layout-restore's exact sequence for one manifest row:
#   spawn kitty -> discover its window id via kdotool search (poll loop) ->
#   kdotool windowsize -> kdotool windowmove -> (script moves on to the next
#   row immediately, no settle wait).
#
# Then measures, WITHOUT any extra artificial delay, whether the window's
# rendered content (kitty's own committed Wayland buffer size, captured via
# WAYLAND_DEBUG=1 trace) matches the requested geometry by the time the
# script would naturally have moved on — i.e. right after windowmove returns.
set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.local/state/kwin-test}"
source "$STATE_DIR/env"
export DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY

RUN_ID="${1:?usage: repro-cold-resize.sh RUN_ID [--mode cold|settled]}"
MODE="${2:---mode}"; MODE="${3:-cold}"
OUT_DIR="$STATE_DIR/runs/$RUN_ID"
mkdir -p "$OUT_DIR"
SOCK="$OUT_DIR/kitty.sock"
TRACE="$OUT_DIR/wayland-trace.log"
rm -f "$SOCK" "$TRACE"

TARGET_W=1300
TARGET_H=900
TARGET_X=100
TARGET_Y=100

# --- Discover the new window via before/after diff + getwindowpid
# confirmation — the SAME pattern desktop-layout-restore actually uses
# (bin/.local/bin/desktop-layout-restore ~line 113-ish), not `kdotool
# search --pid` as a filter. That matters: --pid search proved unreliable
# in manual testing here (it returned a stale, already-dead kitty's window
# across multiple fresh spawns), which is presumably exactly why the real
# script uses the before/after-diff dance instead of trusting --pid search.
mapfile -t before < <(kdotool search --class kitty 2>/dev/null || true)
declare -A before_set=()
for w in "${before[@]}"; do before_set["$w"]=1; done

# --- Spawn kitty exactly as desktop-layout-restore does (relevant flags):
#   --single-instance=no --directory CWD ... --listen-on unix:SOCKET
# WAYLAND_DEBUG=1 gives us the ground truth of what buffer kitty actually
# committed, independent of what kdotool/KWin BELIEVE the geometry is.
WAYLAND_DEBUG=1 kitty --single-instance=no --directory "$HOME" \
  -o allow_remote_control=socket-only --listen-on "unix:$SOCK" >"$TRACE" 2>&1 &
KITTY_PID=$!

WIN=""
for _ in $(seq 1 100); do
  mapfile -t after < <(kdotool search --class kitty 2>/dev/null || true)
  for candidate in "${after[@]}"; do
    [[ -n "${before_set[$candidate]:-}" ]] && continue
    [[ "$(kdotool getwindowpid "$candidate" 2>/dev/null || true)" == "$KITTY_PID" ]] || continue
    WIN="$candidate"
    break 2
  done
  sleep 0.05
done
if [[ -z "$WIN" ]]; then
  echo "FAIL run=$RUN_ID reason=window_not_found" | tee "$OUT_DIR/result"
  kill "$KITTY_PID" 2>/dev/null || true
  exit 1
fi

if [[ "$MODE" == "settled" ]]; then
  # Negative-control timing variant: let the window fully settle (its
  # post-map activation configure has already round-tripped) before issuing
  # the resize/move. This isolates whether the bug is inherent to
  # kdotool/KWin resize, or specific to resizing during the spawn race.
  sleep 1
fi

# --- The exact desktop-layout-restore call pair, no artificial settle wait
# in between (matches production: script moves to windowsize then
# windowmove back-to-back). ---
kdotool windowsize "$WIN" "$TARGET_W" "$TARGET_H"
kdotool windowmove "$WIN" "$TARGET_X" "$TARGET_Y"

# Snapshot state RIGHT AWAY — this is what a caller who "moves on" would see.
kwin_geom_immediate="$(kdotool getwindowgeometry "$WIN" 2>&1 | tr '\n' ' ')"

# Give the Wayland round-trip a bounded moment to land (some latency is
# inherent to any IPC-driven resize; we're checking whether it's bounded
# and reliable, not literally instantaneous).
sleep 2
kwin_geom_settled="$(kdotool getwindowgeometry "$WIN" 2>&1 | tr '\n' ' ')"

# Ground truth: what buffer size did kitty's Wayland client actually commit
# as its MAIN surface (wl_surface#34 in kitty's own numbering is not stable
# across runs, so match by wl_shm_pool.create_buffer calls whose dimensions
# equal content-area == TARGET_W x (TARGET_H - titlebar~24px), OR simply
# grep the last configure() the client acked and the last buffer geometry
# kitty allocated matching it).
last_configure="$(grep -oE 'xdg_toplevel#[0-9]+\.configure\([0-9]+, [0-9]+' "$TRACE" | tail -1 || true)"
committed_target_size=0
if grep -qE "create_buffer\(new id wl_buffer#[0-9]+, 0, $TARGET_W, $((TARGET_H - 24))" "$TRACE"; then
  committed_target_size=1
fi

kitty_ls_cols_lines=""
for _ in $(seq 1 20); do
  kitty_ls_cols_lines="$(kitten @ --to "unix:$SOCK" ls 2>/dev/null | jq -er '[.[0].tabs[]?.windows[]? | {columns, lines}][0] | "\(.columns)x\(.lines)"' 2>/dev/null || true)"
  [[ -n "$kitty_ls_cols_lines" ]] && break
  sleep 0.1
done

{
  echo "run=$RUN_ID mode=$MODE window=$WIN"
  echo "target=${TARGET_W}x${TARGET_H}"
  echo "kwin_geometry_immediately_after_calls: $kwin_geom_immediate"
  echo "kwin_geometry_after_2s_settle: $kwin_geom_settled"
  echo "last_xdg_toplevel_configure_seen: ${last_configure:-NONE}"
  echo "kitty_committed_target_sized_buffer: $committed_target_size"
  echo "kitten_ls_self_reported_cells: ${kitty_ls_cols_lines:-UNKNOWN}"
} | tee "$OUT_DIR/result"

kill "$KITTY_PID" 2>/dev/null || true
wait "$KITTY_PID" 2>/dev/null || true

# Pass/fail: the geometry kdotool reports IMMEDIATELY after the calls
# (i.e. what a script deciding "did this work" right away would see) must
# already reflect the target size. This is the property desktop-layout-
# restore silently assumes (it never re-checks or waits after windowsize).
if [[ "$kwin_geom_immediate" == *"${TARGET_W}x${TARGET_H}"* ]]; then
  echo "PASS run=$RUN_ID: kdotool geometry reflected target size immediately"
  exit 0
else
  echo "FAIL run=$RUN_ID: kdotool geometry did NOT reflect target size immediately (stale read) — settled=$kwin_geom_settled"
  exit 1
fi
