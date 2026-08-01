#!/usr/bin/env bash
# Outside-container orchestrator for the kdotool/KWin-Wayland resize harness.
# Sibling to ../tmux-restore-test/run.sh — same conventions (privileged
# systemd-as-PID-1 container, dotfiles bind-mounted read-only), but there is
# no "reboot" phase here: this harness reproduces a live-session race
# (rapid successive kitty spawns, each stealing focus from the last, racing
# a kdotool-driven resize) rather than crash recovery.
#
# Usage:
#   ./run.sh [--rebuild] [--keep] [--scenario burst|single] [--count N]
#
#   --rebuild   Force docker image rebuild
#   --keep      Don't auto-remove the container after run (debugging)
#   --scenario  burst  (default): desktop-layout-restore's real loop shape —
#               spawn N kitty windows back-to-back, each immediately
#               resized/moved via kdotool, no per-window settle wait. This
#               is the scenario that reliably reproduces the bug (see
#               README.md): rows 1-2 of any burst >= 3 windows get their
#               resize silently reverted by a KWin deactivation-configure
#               race and are LEFT AT DEFAULT SIZE PERMANENTLY.
#               single: one window at a time, --runs iterations, each in
#               isolation (no other window spawns to steal focus). Used to
#               confirm the bug needs multi-window contention — a single
#               window in isolation only shows brief (self-correcting)
#               resize latency, not the permanent-stuck-size failure.
#   --count N   burst: window count (default 6). single: iteration count
#               (default 5).
#   --mode M    single scenario only: cold|settled (default cold).
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SELF_DIR/../../.." && pwd)"
IMAGE_TAG="kwin-wayland-test:latest"
CONTAINER_NAME="kwin-wayland-test"

REBUILD=0
KEEP=0
SCENARIO="burst"
COUNT=""
MODE="cold"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) REBUILD=1; shift ;;
    --keep) KEEP=1; shift ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    --count) COUNT="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo pipefail/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

case "$SCENARIO" in
  burst) COUNT="${COUNT:-6}" ;;
  single) COUNT="${COUNT:-5}" ;;
  *) echo "unknown scenario: $SCENARIO (expected burst|single)"; exit 1 ;;
esac

cd "$SELF_DIR"

if (( REBUILD )) || ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
  echo ">>> building image"
  docker build -t "$IMAGE_TAG" .
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo ">>> removing leftover container"
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

cleanup() {
  if (( ! KEEP )); then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  else
    echo ">>> --keep: container '$CONTAINER_NAME' left running for inspection"
    echo "    docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 $CONTAINER_NAME bash"
  fi
}
trap cleanup EXIT

user_exec() {
  docker exec -u tester \
    -e XDG_RUNTIME_DIR=/run/user/1000 \
    -e HOME=/home/tester \
    "$@"
}

echo ""
echo ">>> phase 1: start container"
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  --cgroupns=host \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v "$DOTFILES_DIR:/workspace:ro" \
  "$IMAGE_TAG" >/dev/null

for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
    break
  fi
  sleep 0.5
done
docker exec "$CONTAINER_NAME" loginctl enable-linger tester >/dev/null
sleep 1

echo ">>> phase 2: start headless KWin (virtual backend)"
user_exec "$CONTAINER_NAME" bash /opt/harness/start-kwin.sh

echo ""
if [[ "$SCENARIO" == "burst" ]]; then
  echo ">>> phase 3: burst scenario ($COUNT windows, desktop-layout-restore loop shape)"
  set +e
  user_exec -e SETTLE_SECONDS=8 "$CONTAINER_NAME" bash /opt/harness/repro-burst.sh main "$COUNT"
  RC=$?
  set -e
  echo ""
  echo "===================="
  if (( RC == 0 )); then
    echo "SCENARIO 'burst' ($COUNT windows): PASS (no window left at wrong size)"
  else
    echo "SCENARIO 'burst' ($COUNT windows): FAIL (>=1 window permanently stuck at default size — see rows above)"
  fi
  echo "===================="
  exit "$RC"
else
  echo ">>> phase 3: single-window repro runs (mode=$MODE, count=$COUNT)"
  PASS=0
  FAIL=0
  for i in $(seq 1 "$COUNT"); do
    echo "--- run $i/$COUNT ---"
    if user_exec "$CONTAINER_NAME" bash /opt/harness/repro-cold-resize.sh "run$i" --mode "$MODE"; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""
  echo "===================="
  echo "mode=$MODE  PASS=$PASS FAIL=$FAIL / $COUNT"
  echo "===================="
  if (( FAIL > 0 )); then
    exit 1
  fi
  exit 0
fi
