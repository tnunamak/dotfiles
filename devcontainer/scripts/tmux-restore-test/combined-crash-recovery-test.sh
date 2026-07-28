#!/usr/bin/env bash
# Combined crash-recovery test: proves tmux/Codex session resurrection and
# shell/.shell_config's Infisical secrets retry DON'T interfere with each
# other under a real SIGKILL+reboot, in the same boot window.
#
# Each half is already proven correct in isolation:
#   - devcontainer/scripts/tmux-restore-test/run.sh (tmux-resurrect scenarios)
#   - devcontainer/scripts/tmux-restore-test/patch8-retirement-test.sh
#   - tests/test_shell_config_infisical_retry_survives_crash_cascade.sh
# What none of those prove: does tmux-restore.service's boot-time work (which
# can take real wall-clock time — the systemd-restore.log has shown minutes
# in production) affect how soon a shell sources shell/.shell_config and
# starts retrying Infisical, or vice versa? This test runs both real
# mechanisms together through one SIGKILL+reboot cycle and checks both
# succeed.
#
# Real container, real systemd, real SIGKILL on PID 1 (a clean `docker stop`
# would let tmux save cleanly and defeat the crash simulation — see README).
set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SELF_DIR/../../.." && pwd)"
IMAGE_TAG="tmux-restore-test:latest"
CONTAINER_NAME="combined-crash-recovery-test"
KEEP=0
INFISICAL_FAIL_COUNT="${INFISICAL_FAIL_COUNT:-3}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --infisical-fail-count) INFISICAL_FAIL_COUNT="$2"; shift 2 ;;
    -h|--help) sed -n '2,/^set -euo pipefail/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

cd "$SELF_DIR"

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

echo ">>> building image if needed"
docker build -q -t "$IMAGE_TAG" . >/dev/null

echo ">>> starting container"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
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
  docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded" && break
  sleep 0.5
done
docker exec "$CONTAINER_NAME" loginctl enable-linger tester
for _ in $(seq 1 30); do
  user_exec "$CONTAINER_NAME" systemctl --user is-system-running 2>/dev/null | grep -qE "running|degraded" && break
  sleep 0.5
done

echo ">>> installing dotfiles (tmux + shell packages, patches applied)"
user_exec "$CONTAINER_NAME" bash /workspace/devcontainer/scripts/tmux-restore-test/harness/install-dotfiles.sh

echo ">>> stowing shell + zsh packages so shell/.shell_config is sourced by real zsh startup"
# shell/.shell_config is a shared file SOURCED BY zsh/.zshrc ([[ -f ~/.shell_config ]] && . ~/.shell_config)
# — stowing "shell" alone drops the file in place but installs no .zshrc to
# source it, so a first attempt at this test silently never ran it at all.
user_exec "$CONTAINER_NAME" bash -c 'cd /workspace && stow --target="$HOME" --no-folding shell zsh'

echo ">>> installing a crash-cascade infisical stub (fails $INFISICAL_FAIL_COUNT times, then succeeds)"
# Same simulation shape as test_shell_config_infisical_retry_survives_crash_cascade.sh,
# but installed as a real ~/.local/bin/infisical so it's picked up by the
# REAL shell/.shell_config sourced at REAL shell startup, not a copy.
user_exec "$CONTAINER_NAME" bash -c "cat > \$HOME/.local/bin/infisical <<'EOF'
#!/usr/bin/env bash
COUNTER_FILE=\"\$HOME/.infisical-test-counter\"
FAIL_COUNT=$INFISICAL_FAIL_COUNT
count=0
[[ -f \"\$COUNTER_FILE\" ]] && count=\"\$(cat \"\$COUNTER_FILE\")\"
count=\$((count + 1))
echo \"\$count\" > \"\$COUNTER_FILE\"
(( count <= FAIL_COUNT )) && exit 1
echo \"export INFISICAL_COMBINED_TEST_VAR=hydrated_after_\${count}_attempts\"
EOF
chmod +x \$HOME/.local/bin/infisical"
# Reset the counter so it re-triggers the cascade on THIS boot, not whatever
# ran during install (zsh's own startup may have sourced .shell_config once
# already as a side effect of stow/install steps).
user_exec "$CONTAINER_NAME" bash -c 'rm -f "$HOME/.infisical-test-counter"'

echo ">>> populating tmux state (a live claude session) before the crash"
user_exec "$CONTAINER_NAME" systemctl --user start tmux.service
user_exec -e SCENARIO=no-crash -e WINDOW_COUNT=4 -e SAVES_BEFORE=2 -e DELETE_LIVE_LAST=0 -e LAUNCH_ASSISTANTS=1 \
  "$CONTAINER_NAME" bash /workspace/devcontainer/scripts/tmux-restore-test/harness/populate-state.sh

echo ">>> simulating power loss (SIGKILL on PID 1)"
docker kill --signal=SIGKILL "$CONTAINER_NAME" >/dev/null
docker start "$CONTAINER_NAME" >/dev/null

for _ in $(seq 1 30); do
  docker exec "$CONTAINER_NAME" systemctl is-system-running 2>/dev/null | grep -qE "running|degraded" && break
  sleep 0.5
done
for _ in $(seq 1 30); do
  user_exec "$CONTAINER_NAME" systemctl --user is-system-running 2>/dev/null | grep -qE "running|degraded" && break
  sleep 0.5
done

echo ">>> waiting for tmux-restore.service to finish"
for _ in $(seq 1 60); do
  state="$(user_exec "$CONTAINER_NAME" systemctl --user is-active tmux-restore.service 2>/dev/null || true)"
  [[ "$state" != "activating" ]] && break
  sleep 0.5
done

# attend-boot-restore only fires on tmux's real client-attached hook — no
# docker exec in this test is a real tmux client, so nothing resumes the
# claude stub without this. Same trigger agent-resume-scale-assert.sh uses:
# invoking the CLI directly is exactly what the hook does under the hood.
echo ">>> triggering attend-boot-restore (simulates the first real client attach)"
user_exec "$CONTAINER_NAME" timeout 30 /home/tester/.local/bin/tmux-agent-resume attend-boot-restore >/tmp/combined-abr.json 2>&1 || true
cat /tmp/combined-abr.json

echo ">>> [1/2] checking tmux/assistant resurrection"
tmux_ok=1
# pane_current_command reports the real binary (setsid, wrapping the stub),
# not the stub's argv[0]-renamed name — check for the claude stub's own
# startup marker in captured pane content instead, same signal the existing
# pane-capture-skip scenario in run.sh uses to prove an assistant pane is
# genuinely running.
user_exec "$CONTAINER_NAME" bash -c '
  for pane in $(tmux list-panes -a -F "#{session_name}:#{window_index}" 2>/dev/null); do
    tmux capture-pane -t "$pane" -p 2>/dev/null | grep -q "ASSISTANT_TUI_SCROLLBACK_claude_marker" && exit 0
  done
  exit 1
' || tmux_ok=0
if (( tmux_ok )); then
  echo "    PASS: a restored pane is running the resumed claude stub (scrollback marker found) after real SIGKILL+reboot"
else
  echo "    FAIL: no assistant pane found after restore" >&2
fi

echo ">>> [2/2] checking a fresh interactive shell hydrates Infisical secrets"
# A real new login-style shell, same as a freshly-attached tmux pane would
# get: sources shell/.shell_config for real, races the same infisical stub,
# through the SAME boot window tmux-restore.service just ran in. NOTMUX=1 is
# required: a real pty here makes shell/.shell_config's own tmux auto-attach
# (`exec tmux-local-attach-main`) fire and block forever on a real
# `tmux attach-session` with no terminal on the other end to ever detach —
# a real interactive shell in the container hung this exact way on the first
# attempt at this test. NOTMUX=1 is the documented escape hatch in
# shell/.shell_config itself for exactly this "debugging tmux itself" case.
infisical_output="$(timeout 30 docker exec -u tester -e XDG_RUNTIME_DIR=/run/user/1000 \
  -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus -e HOME=/home/tester \
  -e TERM=xterm -e NOTMUX=1 "$CONTAINER_NAME" script -qec 'zsh -i -c "echo VAR=\$INFISICAL_COMBINED_TEST_VAR"' /dev/null 2>&1 || true)"
echo "    shell output: $infisical_output"
infisical_ok=0
[[ "$infisical_output" == *"VAR=hydrated_after_"* ]] && infisical_ok=1

if (( infisical_ok )); then
  echo "    PASS: fresh shell in the post-restore boot window recovered Infisical secrets despite the simulated crash cascade"
else
  echo "    FAIL: fresh shell did not hydrate INFISICAL_COMBINED_TEST_VAR" >&2
fi

echo ""
if (( tmux_ok )) && (( infisical_ok )); then
  echo "RESULT: PASS — tmux/assistant resurrection and Infisical secrets retry both succeed in the same real crash+reboot window"
  exit 0
else
  echo "RESULT: FAIL"
  exit 1
fi
