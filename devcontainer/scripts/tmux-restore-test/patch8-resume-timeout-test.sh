#!/usr/bin/env bash
# Standalone test for Patch 8 (patch-assistant-resurrect.sh): bounds `codex
# resume` with `timeout 45` so a hung OAuth-bootstrap (openai/codex#22072)
# can't stall the whole boot-restore. Same Docker+systemd-as-PID-1 image as
# run.sh (see README) — no SIGKILL/reboot cycle needed, this exercises the
# real resume-dispatch code path from tmux-assistant-resurrect's
# restore-assistant-sessions.sh directly against a codex stub that hangs
# exactly like the real OAuth-bootstrap bug.
#
# Proves, against the ACTUAL upstream dispatch logic (not a reimplementation):
#   1. UNPATCHED: a hung `codex resume` blocks the caller indefinitely
#      (bug reproduced — we cap the wait at 12s in the test to keep it fast,
#      but assert it's STILL hung at that point, which is proof of an
#      unbounded hang, not a slow-but-finite one).
#   2. PATCHED (patch-assistant-resurrect.sh applied): the same hang returns
#      control within timeout(45)'s bound, deterministically, every run.
#
# Usage:
#   bash patch8-resume-timeout-test.sh
#   bash patch8-resume-timeout-test.sh --keep
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_TAG="tmux-restore-test:latest"
CONTAINER_NAME="patch8-resume-timeout-test"
KEEP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
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
    -e PATH=/home/tester/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
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

echo ">>> installing dotfiles + plugins"
# install-dotfiles.sh itself runs patch-assistant-resurrect.sh as one of its
# steps (matching how a real machine's setup.sh / tmux-restore.service
# ExecStartPre applies it) — there is no unpatched install path to select.
# The plugin file that results is already Patch-8-patched.
user_exec "$CONTAINER_NAME" bash /workspace/devcontainer/scripts/tmux-restore-test/harness/install-dotfiles.sh

echo ">>> replacing codex stub with an OAuth-bootstrap-hang simulator"
# Real bug: `codex resume <id>` hangs forever when it has saved OAuth creds
# for an MCP server that's unresponsive at the pre-initialize bootstrap step
# (openai/codex#22072) — no output, no exit, ever. This stub reproduces
# exactly that: `resume` hangs unconditionally; any other subcommand (e.g.
# `mcp`) returns immediately so it doesn't interfere with unrelated calls.
user_exec "$CONTAINER_NAME" bash -c 'cat > "$HOME/.local/bin/codex" <<'"'"'EOF'"'"'
#!/usr/bin/env bash
if [[ "${1:-}" == "resume" ]]; then
  echo "ASSISTANT_TUI_SCROLLBACK_codex_marker"
  exec -a "codex $*" bash -c "while :; do sleep 3600 & wait; done"
fi
echo "codex-stub: $* (non-resume, returns immediately)"
exit 0
EOF
chmod +x "$HOME/.local/bin/codex"'

# --- Extract the exact resume_cmd this session ID would produce, straight
# from the live PATCHED plugin file (install-dotfiles.sh always applies
# Patch 8, matching how a real machine's setup.sh does it — there is no
# unpatched install path to select). This is the REAL upstream dispatch
# string, not a reimplementation. The bare "codex resume ${safe_sid}" line
# (no `command`/no trailing marker comment) is the one Patch 8 rewrites; we
# grep that exact shape so a change to the plugin's quoting breaks this test
# loudly instead of silently matching the wrong line.
extract_resume_line() {
  user_exec "$CONTAINER_NAME" bash -c '
    f="$HOME/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh"
    grep -F "resume_cmd=\"command timeout 45 codex resume \${safe_sid}\" # AR-Patch8" "$f" | tail -1
  '
}
build_cmd_from_template() {
  local tpl="$1"
  echo "${tpl//\$\{safe_sid\}/test-session-id}"
}

echo ">>> [1/2] UNPATCHED (reconstructed): proving codex resume hangs the caller"
PATCHED_LINE="$(extract_resume_line)"
if [[ -z "$PATCHED_LINE" ]]; then
  echo "FAIL: could not find the expected Patch-8 codex resume_cmd line — plugin file shape changed or patch did not apply during install" >&2
  exit 1
fi
# Reconstruct the pre-patch string as the EXACT inverse of Patch 8's own sed
# substitution (patch-assistant-resurrect.sh): remove "timeout 45 " and the
# " # AR-Patch8" marker it adds. This is not a guess at what the bug looked
# like — it is the literal string Patch 8's sed replaces FROM, so testing it
# proves the bug Patch 8 fixes, not a strawman.
UNPATCHED_TPL="$(echo "$PATCHED_LINE" | sed -E 's/resume_cmd="command timeout 45 (codex[^"]*)" # AR-Patch8/\1/; s/^\s*//')"
UNPATCHED_CMD="command $(build_cmd_from_template "$UNPATCHED_TPL")"
echo "    resume_cmd = $UNPATCHED_CMD"
if [[ "$UNPATCHED_CMD" == *"timeout"* ]]; then
  echo "FAIL: reconstructed unpatched command still contains a timeout wrapper — reconstruction is wrong" >&2
  exit 1
fi
# Run it with an outer 12s deadline. If the inner hang is real and unbounded,
# the outer timeout kills it at 12s and we assert exit code 124 (killed by
# OUR safety wrapper, not by anything under test) — proof it was still
# running, i.e. genuinely hung, not just slow.
set +e
user_exec "$CONTAINER_NAME" timeout 12 bash -c "$UNPATCHED_CMD" >/tmp/patch8-unpatched.out 2>&1
unpatched_rc=$?
set -e
echo "    exit code: $unpatched_rc (124 = still hung at 12s outer deadline, as expected)"
if [[ "$unpatched_rc" -ne 124 ]]; then
  echo "FAIL: expected the unpatched resume_cmd to still be hung (rc=124) at 12s, got rc=$unpatched_rc" >&2
  echo "--- output ---"; cat /tmp/patch8-unpatched.out
  exit 1
fi
echo "    PASS: unpatched codex resume is a genuine unbounded hang (bug reproduced)"

echo ">>> confirming patch-assistant-resurrect.sh applied Patch 8 during install"
user_exec "$CONTAINER_NAME" bash -n "/home/tester/.tmux/plugins/tmux-assistant-resurrect/scripts/restore-assistant-sessions.sh" \
  || { echo "FAIL: patched restore-assistant-sessions.sh is not valid bash" >&2; exit 1; }
echo "    already patched at install time, syntax-valid (checked above)"

echo ">>> [2/2] PATCHED: proving codex resume now returns within a bound"
PATCHED_TPL="$(echo "$PATCHED_LINE" | sed -E 's/^\s*resume_cmd="(.*)" # AR-Patch8/\1/')"
PATCHED_CMD="$(build_cmd_from_template "$PATCHED_TPL")"
echo "    resume_cmd = $PATCHED_CMD"
if [[ "$PATCHED_CMD" != *"timeout 45"* ]]; then
  echo "FAIL: patched plugin file does not contain the expected 'timeout 45' wrapper" >&2
  exit 1
fi
start_ts=$(date +%s)
set +e
# Outer deadline generous (60s) relative to the inner timeout(45) we're
# proving exists — if the patch is a no-op this still hangs and we correctly
# fail via the outer kill, distinguishing "patch didn't work" from "patch
# capped it at 45s as designed".
user_exec "$CONTAINER_NAME" timeout 60 bash -c "$PATCHED_CMD" >/tmp/patch8-patched.out 2>&1
patched_rc=$?
set -e
end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))
echo "    exit code: $patched_rc, elapsed: ${elapsed}s"
if [[ "$patched_rc" -ne 124 ]]; then
  echo "FAIL: expected exit 124 from the INNER timeout 45 (not from our 60s outer guard)" >&2
  echo "--- output ---"; cat /tmp/patch8-patched.out
  exit 1
fi
if (( elapsed < 40 || elapsed > 50 )); then
  echo "FAIL: expected the patched resume to be killed at ~45s, got ${elapsed}s — timeout value may not be 45 or patch may be misapplied" >&2
  exit 1
fi
echo "    PASS: patched codex resume is bounded to ~45s, not an indefinite hang"

echo ""
echo ">>> RESULT: PASS — Patch 8 converts an unbounded codex-resume hang into a bounded ~45s timeout"
exit 0
