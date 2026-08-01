#!/usr/bin/env bash
# Same loop shape as repro-burst.sh, but using the FIXED per-row call —
# resize_and_verify() — instead of the bare windowsize/windowmove pair.
# Proves the fix closes the cold-KWin-session burst race that
# repro-burst.sh reproduces 100% of the time against the unfixed pair (see
# README.md "Finding 1").
#
# resize_and_verify() is extracted LIVE from the real
# bin/.local/bin/desktop-layout-restore (bind-mounted read-only at
# /workspace) rather than hand-copied here, so this test can never drift
# from the actual production fix.
set -euo pipefail

STATE_DIR="${STATE_DIR:-$HOME/.local/state/kwin-test}"
source "$STATE_DIR/env"
export DBUS_SESSION_BUS_ADDRESS WAYLAND_DISPLAY

RUN_ID="${1:?usage: repro-burst-fixed.sh RUN_ID WINDOW_COUNT}"
COUNT="${2:-5}"
OUT_DIR="$STATE_DIR/burst-fixed-runs/$RUN_ID"
mkdir -p "$OUT_DIR"

declare -a WIN_IDS=()
declare -a TARGET_W=()
declare -a TARGET_H=()
declare -a KITTY_PIDS=()

REAL_SCRIPT="/workspace/bin/.local/bin/desktop-layout-restore"
[[ -r "$REAL_SCRIPT" ]] || { echo "[burst-fixed] ERROR: $REAL_SCRIPT not readable" >&2; exit 1; }
source <(sed -n '/^resize_and_verify() {/,/^}/p' "$REAL_SCRIPT")
[[ "$(type -t resize_and_verify)" == "function" ]] || { echo "[burst-fixed] ERROR: could not extract resize_and_verify() from $REAL_SCRIPT" >&2; exit 1; }
log() { printf '[burst-fixed] %s\n' "$*" >&2; }

echo "[burst-fixed] spawning $COUNT windows back-to-back (desktop-layout-restore loop shape, WITH fix)"
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
    echo "[burst-fixed] row $i: FAILED to identify window (pid=$kpid)"
    continue
  fi

  # Exact call from the fixed desktop-layout-restore, immediately move to next row.
  kdotool set_desktop_for_window "$win" current_desktop
  resize_and_verify "$win" "$w" "$h" "$x" "$y" || true
  echo "[burst-fixed] row $i: window=$win target=${w}x${h}"
done

SETTLE_SECONDS="${SETTLE_SECONDS:-3}"
echo "[burst-fixed] all rows dispatched; waiting ${SETTLE_SECONDS}s for compositor to settle"
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

echo "[burst-fixed] run=$RUN_ID fail_count=$fail_count / $COUNT"
if (( fail_count > 0 )); then
  exit 1
fi
exit 0
