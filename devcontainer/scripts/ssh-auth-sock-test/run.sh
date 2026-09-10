#!/usr/bin/env bash
# Does our SSH_AUTH_SOCK config win the election on a COLD-STARTED user manager?
#
# Runs two cells:
#   baseline  — stock distro units, no config. Expect gcr to win. If this does
#               NOT show gcr, the harness is not reproducing the host and the
#               fixed cell proves nothing.
#   fixed     — environment.d pin + gcr-ssh-agent.socket.d drop-in. Expect
#               openssh_agent.
#
# Usage: bash run.sh [--keep]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/../../.." && pwd)"
IMAGE_TAG="ssh-auth-sock-test:latest"
KEEP=0
[[ "${1:-}" == "--keep" ]] && KEEP=1

ENV_CONF="$DOTFILES/shell/.config/environment.d/10-ssh-auth-sock.conf"
GCR_DROPIN="$DOTFILES/shell/.config/systemd/user/gcr-ssh-agent.socket.d/10-no-ssh-auth-sock.conf"

for f in "$ENV_CONF" "$GCR_DROPIN"; do
  [[ -f "$f" ]] || { echo "missing config under test: $f" >&2; exit 1; }
done

echo ">>> build image"
docker build -q -t "$IMAGE_TAG" "$SCRIPT_DIR" >/dev/null

# Start a container, optionally install our config BEFORE the user manager
# ever starts, then read the elected SSH_AUTH_SOCK. Echoes the value.
run_cell() {
  local cell="$1" install_config="$2"
  local name="ssh-auth-sock-test-$cell"

  docker rm -f "$name" >/dev/null 2>&1 || true
  # NEVER add --privileged here. It grants the container /dev/dri and the
  # VTs, and a systemd-as-PID-1 image then spawns gettys onto the host's
  # consoles and takes DRM master from the running compositor. That is not
  # hypothetical: on 2026-09-10 this harness ran with --privileged on a live
  # Plasma session, KWin lost the GPU, a container getty ("<container-id>
  # login:") was painted onto VT1, and recovering it cost a reboot.
  #
  # systemd needs only cgroup write access plus SYS_ADMIN/SYS_RESOURCE.
  # Verified: with these flags the container reaches `systemctl
  # is-system-running = running`, reproduces the gcr-wins baseline, and has
  # NO /dev/dri and NO /dev/tty1 at all.
  docker run -d --name "$name" \
    --cgroupns=host \
    --tmpfs /tmp --tmpfs /run --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --cap-add SYS_ADMIN --cap-add SYS_RESOURCE \
    --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
    -v "$DOTFILES:/dotfiles:ro" \
    "$IMAGE_TAG" >/dev/null

  # Fail loudly rather than silently testing a container that can reach the
  # host's GPU/consoles, in case someone reintroduces --privileged above.
  if docker exec "$name" test -e /dev/dri 2>/dev/null ||
     docker exec "$name" test -e /dev/tty1 2>/dev/null; then
    echo "REFUSING: container can see /dev/dri or /dev/tty1 — do not run this on a live desktop" >&2
    docker rm -f "$name" >/dev/null 2>&1 || true
    exit 1
  fi

  for _ in $(seq 1 30); do
    docker exec "$name" systemctl is-system-running 2>/dev/null \
      | grep -qE "running|degraded" && break
    sleep 0.5
  done

  # Install BEFORE linger starts user@1000.service — the generator only runs
  # at user-manager start, so installing afterwards would not test the
  # ordering we care about.
  if [[ "$install_config" == "yes" ]]; then
    docker exec "$name" install -d -o tester -g tester \
      /home/tester/.config/environment.d \
      /home/tester/.config/systemd/user/gcr-ssh-agent.socket.d
    docker exec "$name" install -o tester -g tester -m 0644 \
      /dotfiles/shell/.config/environment.d/10-ssh-auth-sock.conf \
      /home/tester/.config/environment.d/10-ssh-auth-sock.conf
    docker exec "$name" install -o tester -g tester -m 0644 \
      /dotfiles/shell/.config/systemd/user/gcr-ssh-agent.socket.d/10-no-ssh-auth-sock.conf \
      /home/tester/.config/systemd/user/gcr-ssh-agent.socket.d/10-no-ssh-auth-sock.conf
  fi

  # Cold-start the user manager. This is the step the live host cannot redo.
  docker exec "$name" loginctl enable-linger tester >/dev/null 2>&1 || true
  for _ in $(seq 1 60); do
    docker exec -u tester -e XDG_RUNTIME_DIR=/run/user/1000 "$name" \
      systemctl --user is-system-running 2>/dev/null \
      | grep -qE "running|degraded|starting" && break
    sleep 0.5
  done

  # Activate the sockets in the distro's declared order. gcr-ssh-agent.socket
  # is After=ssh-agent.socket precisely so its ExecStartPost lands last and
  # wins; starting both in one command lets systemd pick an order and makes
  # the baseline racy (measured 2/4 either way). Serialize to reproduce login.
  docker exec -u tester -e XDG_RUNTIME_DIR=/run/user/1000 "$name" \
    systemctl --user start ssh-agent.socket >/dev/null 2>&1 || true
  sleep 0.5
  docker exec -u tester -e XDG_RUNTIME_DIR=/run/user/1000 "$name" \
    systemctl --user start gcr-ssh-agent.socket >/dev/null 2>&1 || true
  sleep 1

  local out
  out="$(docker exec -u tester -e XDG_RUNTIME_DIR=/run/user/1000 "$name" \
    systemctl --user show-environment 2>/dev/null | grep '^SSH_AUTH_SOCK=' || true)"

  if (( KEEP )); then
    echo "    (kept: docker exec -it -u tester -e XDG_RUNTIME_DIR=/run/user/1000 $name bash)" >&2
  else
    docker rm -f "$name" >/dev/null 2>&1 || true
  fi
  echo "${out#SSH_AUTH_SOCK=}"
}

echo ">>> cell: baseline (stock units, no config)"
baseline="$(run_cell baseline no)"
echo "    SSH_AUTH_SOCK=${baseline:-<unset>}"

echo ">>> cell: fixed (environment.d pin + gcr drop-in)"
fixed="$(run_cell fixed yes)"
echo "    SSH_AUTH_SOCK=${fixed:-<unset>}"

echo ""
rc=0

# Discriminating check: if gcr does not win the baseline, this harness is not
# reproducing the contention we are fixing, and the fixed cell is meaningless.
case "$baseline" in
  *gcr*) echo "PASS baseline: gcr wins by default (contention reproduced)" ;;
  *) echo "INCONCLUSIVE baseline: expected gcr, got '${baseline:-<unset>}'"
     echo "  the fixed cell below does not prove anything without this"
     rc=1 ;;
esac

case "$fixed" in
  */openssh_agent) echo "PASS fixed: openssh_agent wins the cold-start election" ;;
  *) echo "FAIL fixed: expected .../openssh_agent, got '${fixed:-<unset>}'"
     rc=1 ;;
esac

exit "$rc"
