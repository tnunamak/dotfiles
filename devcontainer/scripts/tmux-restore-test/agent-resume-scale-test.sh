#!/usr/bin/env bash
# Standalone scale test for bin/.local/bin/tmux-agent-resume, run in the same
# Docker+systemd-as-PID-1 image as run.sh (see README). Not a crash-recovery
# scenario — no SIGKILL/reboot — this exercises the tool's JSON handling at
# fleet sizes that don't fit in a real terminal fleet for routine testing.
#
# Root cause this guards: five `jq --argjson "$var"` call sites in
# tmux-agent-resume built shell command-lines from full sidecar JSON. Silent
# below ~150 entries, "Argument list too long" above it. First hit in
# production 2026-07-24 at 169 entries — attend-boot-restore (the real
# boot-time agent-resume trigger) had been silently non-functional at that
# scale for an unknown period beforehand. See CLAUDE.md "2026-07-24" section
# and commits 45a18ba / b287acf.
#
# Usage:
#   bash agent-resume-scale-test.sh                  # default: 200 entries / 30 windows
#   bash agent-resume-scale-test.sh --entries 500
#   bash agent-resume-scale-test.sh --keep            # leave container running after
#   bash agent-resume-scale-test.sh --fixture         # use the real 169-entry
#                                                      # capture that crashed
#                                                      # production 2026-07-24
#                                                      # instead of synthetic
#                                                      # data (recommended —
#                                                      # see harness/agent-
#                                                      # resume-scale-populate.sh)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_TAG="tmux-restore-test:latest"
CONTAINER_NAME="agent-resume-scale-test"
ENTRY_COUNT=200
WINDOW_COUNT=30
KEEP=0
USE_REAL_FIXTURE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --entries) ENTRY_COUNT="$2"; shift 2 ;;
    --windows) WINDOW_COUNT="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --fixture) USE_REAL_FIXTURE=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

cleanup() {
  if [[ "$KEEP" -eq 1 ]]; then
    echo ""
    echo ">>> --keep set; container left running:"
    echo "    docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 -e HOME=/home/tester $CONTAINER_NAME zsh"
    echo "    docker rm -f $CONTAINER_NAME   # when done"
  else
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

user_exec() {
  docker exec -u tester \
    -e XDG_RUNTIME_DIR=/run/user/1000 \
    -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    -e HOME=/home/tester \
    "$@"
}

echo ">>> building image if needed"
docker build -q -t "$IMAGE_TAG" . >/dev/null

echo ">>> starting container (entries=$ENTRY_COUNT windows=$WINDOW_COUNT)"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  --cgroupns=host \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v "$(cd .. && cd .. && cd .. && pwd)":/workspace:ro \
  "$IMAGE_TAG" >/dev/null

for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
    break
  fi
  sleep 0.5
done

docker exec "$CONTAINER_NAME" loginctl enable-linger tester
for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" systemctl --user -M "tester@" is-system-running 2>/dev/null | grep -qE "running|degraded"; then
    break
  fi
  sleep 0.5
done

echo ">>> populating $ENTRY_COUNT-entry sidecar + $WINDOW_COUNT tmux windows"
user_exec -e ENTRY_COUNT="$ENTRY_COUNT" -e WINDOW_COUNT="$WINDOW_COUNT" -e USE_REAL_FIXTURE="$USE_REAL_FIXTURE" \
  "$CONTAINER_NAME" bash /workspace/devcontainer/scripts/tmux-restore-test/harness/agent-resume-scale-populate.sh

echo ">>> running assertions"
if user_exec -e ENTRY_COUNT="$ENTRY_COUNT" -e WINDOW_COUNT="$WINDOW_COUNT" \
  "$CONTAINER_NAME" bash /workspace/devcontainer/scripts/tmux-restore-test/harness/agent-resume-scale-assert.sh; then
  echo ""
  echo ">>> RESULT: PASS"
  exit 0
else
  echo ""
  echo ">>> RESULT: FAIL"
  exit 1
fi
