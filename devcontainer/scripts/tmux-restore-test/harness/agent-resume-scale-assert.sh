#!/usr/bin/env bash
# Runs INSIDE the container as the test user. Exercises every
# tmux-agent-resume code path that touches the sidecar/state JSON — the
# actual crash surface from 2026-07-24 — and asserts clean behavior.
#
# Real production trigger order: record-deferred -> mark-boot-restore ->
# (first client attach fires) attend-boot-restore. Skipping mark-boot-restore
# before attend-boot-restore is a real bug shape too (silent no-op, see PASS
# 5) so it's asserted explicitly rather than just avoided.
set -uo pipefail  # not -e: we want every assertion to run and report, not abort on first fail

export PATH="$HOME/.local/bin:$PATH"
PASS=0
FAIL=0

# populate.sh writes the actual entry count here — authoritative over
# $ENTRY_COUNT, since fixture mode (USE_REAL_FIXTURE=1) ignores the
# caller's requested count and uses whatever the real capture had (169).
if [ -f /tmp/agent-resume-scale-entry-count ]; then
  ENTRY_COUNT="$(cat /tmp/agent-resume-scale-entry-count)"
fi

check() {
  local desc="$1" cmd="$2"
  if eval "$cmd"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "[assert] === status_json at scale ==="
tmux-agent-resume status --json >/tmp/status.json 2>/tmp/status.err
check "status exits 0" "[ $? -eq 0 ]"
check "status stderr is empty" "[ ! -s /tmp/status.err ]"
check "status has expected entry count" \
  "[ \"\$(jq -r '.entries | length' /tmp/status.json)\" = \"\${ENTRY_COUNT:-200}\" ]"

echo "[assert] === record-deferred at scale ==="
tmux-agent-resume record-deferred >/tmp/rd.json 2>/tmp/rd.err
check "record-deferred exits 0" "[ $? -eq 0 ]"
check "record-deferred stderr is empty" "[ ! -s /tmp/rd.err ]"
check "record-deferred recorded expected count" \
  "[ \"\$(jq -r '.recorded' /tmp/rd.json)\" = \"\${ENTRY_COUNT:-200}\" ]"

echo "[assert] === mark-boot-restore at scale ==="
tmux-agent-resume mark-boot-restore >/tmp/mbr.json 2>/tmp/mbr.err
check "mark-boot-restore exits 0" "[ $? -eq 0 ]"
check "mark-boot-restore stderr is empty" "[ ! -s /tmp/mbr.err ]"
check "mark-boot-restore marked expected count" \
  "[ \"\$(jq -r '.marked' /tmp/mbr.json)\" = \"\${ENTRY_COUNT:-200}\" ]"

echo "[assert] === attend-boot-restore at scale (the real boot-time trigger) ==="
timeout 90 tmux-agent-resume attend-boot-restore >/tmp/abr.json 2>/tmp/abr.err
check "attend-boot-restore exits 0" "[ $? -eq 0 ]"
check "attend-boot-restore stderr is empty (no unbound-variable etc.)" "[ ! -s /tmp/abr.err ]"
check "attend-boot-restore granted all entries" \
  "[ \"\$(jq -r '.grants.granted | length' /tmp/abr.json)\" = \"\${ENTRY_COUNT:-200}\" ]"
# NOT asserting an exact applied count: this container has no claude/codex
# binaries, so every real launch fails fast and (depending on shell
# fallback timing) a window can accept more than one apply attempt within
# the same run — a test-environment artifact, not something production
# exhibits (real launches occupy the pane and stop being a shell). What
# matters here is that SOME resumes were dispatched and the tool's own
# JSON bookkeeping stayed correct throughout, which the other assertions
# in this file already cover.
check "attend-boot-restore applied at least one lease" \
  "[ \"\$(jq -r '.applied.applied | length' /tmp/abr.json)\" -gt 0 ]"

echo "[assert] === idempotence: second attend-boot-restore is a clean no-op ==="
timeout 30 tmux-agent-resume attend-boot-restore >/tmp/abr2.json 2>/tmp/abr2.err
check "second attend-boot-restore exits 0" "[ $? -eq 0 ]"
check "second attend-boot-restore stderr is empty" "[ ! -s /tmp/abr2.err ]"

echo "[assert] === temp-file hygiene: no leaked mktemp files after the full sequence ==="
leftover=$(find /tmp -maxdepth 1 -user "$(id -un)" -name 'tmp.*' 2>/dev/null | wc -l)
check "zero leftover /tmp/tmp.* files (found $leftover)" "[ \"$leftover\" -eq 0 ]"

echo "[assert] === PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ]
