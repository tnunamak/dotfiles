#!/usr/bin/env bash
# End-to-end reproduction of desktop-layout-restore's actual loop shape:
# for each manifest row, spawn a kitty window, discover it (before/after
# diff + getwindowpid, same as the real script), call windowsize +
# windowmove, and move on to the NEXT row immediately — no per-row wait,
# no verification. This is closer to the real incident than a single
# isolated resize: multiple windows spawn back-to-back while the compositor
# is still working through earlier windows' configure backlog.
#
# After the whole burst, we independently query each window's FINAL
# geometry (a fixed settle wait) and diff against target — proxying "did
# this window end up wrong" without the script's own blindness to it.
set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.local/state/kwin-test}"
source "$STATE_DIR/env"
export DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY

RUN_ID="${1:?usage: repro-burst.sh RUN_ID WINDOW_COUNT}"
COUNT="${2:-5}"
OUT_DIR="$STATE_DIR/burst-runs/$RUN_ID"
mkdir -p "$OUT_DIR"

declare -a WIN_IDS=()
declare -a TARGET_W=()
declare -a TARGET_H=()
declare -a KITTY_PIDS=()

echo "[burst] spawning $COUNT windows back-to-back (desktop-layout-restore loop shape)"
for i in $(seq 1 "$COUNT"); do
  w=$(( 600 + i * 80 ))
  h=$(( 400 + i * 50 ))
  x=$(( i * 60 ))
  y=$(( i * 40 ))
  TARGET_W[i]=$w
  TARGET_H[i]=$h

  mapfile -t before < <(kdotool search --class kitty 2>/dev/null || true)
  declare -A before_set=()
  for cw in "${before[@]}"; do before_set["$cw"]=1; done

  WAYLAND_DEBUG=1 kitty --single-instance=no --directory "$HOME" \
    -o allow_remote_control=socket-only --listen-on "unix:$OUT_DIR/k$i.sock" \
    >"$OUT_DIR/kitty-$i.log" 2>&1 &
  kpid=$!
  KITTY_PIDS[i]=$kpid

  win=""
  for _ in $(seq 1 100); do
    mapfile -t after < <(kdotool search --class kitty 2>/dev/null || true)
    for candidate in "${after[@]}"; do
      [[ -n "${before_set[$candidate]:-}" ]] && continue
      [[ "$(kdotool getwindowpid "$candidate" 2>/dev/null || true)" == "$kpid" ]] || continue
      win="$candidate"
      break 2
    done
    sleep 0.05
  done
  unset before_set
  WIN_IDS[i]="$win"

  if [[ -z "$win" ]]; then
    echo "[burst] row $i: FAILED to identify window (pid=$kpid)"
    continue
  fi

  # Exact call pair from desktop-layout-restore, immediately move to next row.
  kdotool set_desktop_for_window "$win" current_desktop
  kdotool windowsize "$win" "$w" "$h"
  kdotool windowmove "$win" "$x" "$y"
  echo "[burst] row $i: window=$win target=${w}x${h}"
done

SETTLE_SECONDS="${SETTLE_SECONDS:-3}"
echo "[burst] all rows dispatched; waiting ${SETTLE_SECONDS}s for compositor to settle"
sleep "$SETTLE_SECONDS"

echo "" > "$OUT_DIR/summary"
fail_count=0
for i in $(seq 1 "$COUNT"); do
  win="${WIN_IDS[i]:-}"
  [[ -z "$win" ]] && { echo "row=$i window=MISSING" >> "$OUT_DIR/summary"; fail_count=$((fail_count+1)); continue; }
  geom="$(kdotool getwindowgeometry "$win" 2>&1 | tr '\n' ' ')"
  expect="${TARGET_W[i]}x${TARGET_H[i]}"
  ok="NO"
  [[ "$geom" == *"$expect"* ]] && ok="YES"
  echo "row=$i window=$win target=$expect final_geometry=[$geom] matches=$ok" >> "$OUT_DIR/summary"
  [[ "$ok" == "NO" ]] && fail_count=$((fail_count+1))
done

cat "$OUT_DIR/summary"

for pid in "${KITTY_PIDS[@]:-}"; do
  [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
done

echo "[burst] run=$RUN_ID fail_count=$fail_count / $COUNT"
if (( fail_count > 0 )); then
  exit 1
fi
exit 0
