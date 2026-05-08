#!/usr/bin/env bash
# Outside-container orchestrator for tmux-local-attach-main scenarios.
# Mirrors run.sh but skips the reboot/restore cycle — these scenarios test
# the kitty-attach script's behavior against a hand-built tmux state.
#
# Usage:
#   ./kitty-attach-run.sh [--rebuild] [--keep] [--attach-script PATH] [--scenario NAME]
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SELF_DIR/../../.." && pwd)"
IMAGE_TAG="tmux-restore-test:latest"
CONTAINER_NAME="tmux-restore-test"

REBUILD=0
KEEP=0
ATTACH_SCRIPT=""
SCENARIO="kitty-attach-clean-boot"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) REBUILD=1; shift ;;
    --keep) KEEP=1; shift ;;
    --attach-script) ATTACH_SCRIPT="$2"; shift 2 ;;
    --scenario) SCENARIO="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo pipefail/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

cd "$SELF_DIR"

# Build image if missing or --rebuild
if (( REBUILD )) || ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
  echo ">>> building image"
  docker build -t "$IMAGE_TAG" .
fi

# Tear down any leftover container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo ">>> removing leftover container"
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

DOTFILES_MOUNT=(-v "$DOTFILES_DIR:/workspace:ro")

cleanup() {
  if (( ! KEEP )); then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  else
    echo ">>> --keep: container '$CONTAINER_NAME' left running for inspection"
    echo "    docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 $CONTAINER_NAME zsh"
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

wait_for_user_systemd() {
  local last_state=""
  for _ in $(seq 1 60); do
    last_state=$(user_exec "$CONTAINER_NAME" systemctl --user is-system-running 2>/dev/null || true)
    case "$last_state" in
      running|degraded|starting) return 0 ;;
    esac
    sleep 0.5
  done
  echo "WARN: user systemd settled at state: $last_state (continuing anyway)"
  return 0
}

echo ""
echo ">>> phase 1: start container ($SCENARIO)"
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  --cgroupns=host \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  "${DOTFILES_MOUNT[@]}" \
  "$IMAGE_TAG" >/dev/null

# Wait for system systemd
for _ in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded"; then
    break
  fi
  sleep 0.5
done

docker exec "$CONTAINER_NAME" loginctl enable-linger tester
sleep 1
wait_for_user_systemd

echo ">>> install dotfiles"
INSTALL_VARS=()
if [[ -n "$ATTACH_SCRIPT" ]]; then
  # Translate host path to container path. We bind-mount /workspace already,
  # so use the corresponding /workspace/... path if it's inside dotfiles.
  abs_src="$(cd "$(dirname "$ATTACH_SCRIPT")" && pwd)/$(basename "$ATTACH_SCRIPT")"
  if [[ "$abs_src" == "$DOTFILES_DIR/"* ]]; then
    rel="${abs_src#$DOTFILES_DIR/}"
    INSTALL_VARS+=(-e "ATTACH_SCRIPT_SRC=/workspace/$rel")
    echo ">>> using attach script: /workspace/$rel"
  else
    echo "ERROR: --attach-script must live under $DOTFILES_DIR" >&2
    exit 1
  fi
fi
user_exec "${INSTALL_VARS[@]}" "$CONTAINER_NAME" bash /opt/harness/install-dotfiles.sh

echo ">>> start tmux.service"
user_exec "$CONTAINER_NAME" systemctl --user start tmux.service
sleep 1

echo ""
echo ">>> phase 2: populate state ($SCENARIO)"
user_exec -e "ATTACH_SCENARIO=$SCENARIO" "$CONTAINER_NAME" bash /opt/harness/kitty-attach-populate.sh

echo ""
echo ">>> phase 3: invoke tmux-local-attach-main"
user_exec -e "ATTACH_SCENARIO=$SCENARIO" "$CONTAINER_NAME" bash /opt/harness/kitty-attach-test.sh

echo ""
echo ">>> phase 4: assertions"
user_exec -e "ATTACH_SCENARIO=$SCENARIO" "$CONTAINER_NAME" bash /opt/harness/kitty-attach-assert.sh
exit_code=$?

echo ""
echo "===================="
if [[ "$exit_code" == "0" ]]; then
  echo "SCENARIO '$SCENARIO': PASS"
else
  echo "SCENARIO '$SCENARIO': FAIL"
fi
echo "===================="
exit "$exit_code"
