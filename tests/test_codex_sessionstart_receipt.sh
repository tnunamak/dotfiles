#!/usr/bin/env bash
# Codex SessionStart hooks run under the native Codex process, while the tmux
# saver may serialize either the native process or the older Node launcher.
# The hook must write PID/start-tick receipts for both recognized Codex
# owner processes and no receipt for unrelated or outer Codex commands.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/codex/.codex/scripts/codex-sessionstart-receipt"
WORK="$(mktemp -d "${HOME}/.tmp/codex-sessionstart-receipt.XXXXXX")"
HOME_DIR="$WORK/home"
PROC_ROOT="$WORK/proc"

cleanup() { chmod -R u+w "$WORK" >/dev/null 2>&1 || true; rm -rf "$WORK"; }
trap cleanup EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

write_proc() {
  local pid="$1" ppid="$2" start_ticks="$3"
  shift 3
  mkdir -p "$PROC_ROOT/$pid"
  {
    printf '%s (proc%s) S %s' "$pid" "$pid" "$ppid"
    for _ in $(seq 1 17); do printf ' 0'; done
    printf ' %s 0\n' "$start_ticks"
  } >"$PROC_ROOT/$pid/stat"
  printf '%s\0' "$@" >"$PROC_ROOT/$pid/cmdline"
}

run_hook() {
  local start_pid="$1" payload="$2"
  CODEX_SESSION_RECEIPT_HOME="$HOME_DIR" \
    CODEX_SESSION_RECEIPT_PROC_ROOT="$PROC_ROOT" \
    CODEX_SESSION_RECEIPT_START_PID="$start_pid" \
    "$HOOK" <<<"$payload"
}

mkdir -p "$HOME_DIR/.codex" "$PROC_ROOT"

write_proc 101 1 111 /usr/bin/zsh
write_proc 102 101 222 /opt/codex/bin/codex resume direct-session
write_proc 103 102 233 /usr/bin/sh -c codex-sessionstart-receipt
run_hook 103 '{"session_id":"direct-session","source":"resume"}'
jq -s -e '
  length == 1 and
  .[0].tool == "codex" and
  .[0].pid == 102 and
  .[0].session == "direct-session" and
  .[0].session_id == "direct-session" and
  .[0].source == "resume" and
  .[0].start_ticks == "222"
' "$HOME_DIR/.codex/session-tags.jsonl" >/dev/null ||
  fail 'direct native Codex receipt did not bind pid/session/start_ticks'

: >"$HOME_DIR/.codex/session-tags.jsonl"
write_proc 201 1 211 /usr/bin/zsh
write_proc 202 201 222 node /opt/codex/bin/codex
write_proc 203 202 233 /opt/codex/bin/codex resume wrapped-session
write_proc 204 203 244 /usr/bin/sh -c codex-sessionstart-receipt
run_hook 204 '{"session_id":"wrapped-session","source":"startup"}'
jq -s -e '
  length == 2 and
  ([.[].pid] | sort) == [202,203] and
  all(.[]; .session == "wrapped-session" and .session_id == "wrapped-session") and
  (.[] | select(.pid == 202).start_ticks) == "222" and
  (.[] | select(.pid == 203).start_ticks) == "233"
' "$HOME_DIR/.codex/session-tags.jsonl" >/dev/null ||
  fail 'Node-wrapper Codex receipt did not cover both saver-visible and native PIDs'

: >"$HOME_DIR/.codex/session-tags.jsonl"
write_proc 401 1 411 /opt/codex/bin/codex resume outer-session
write_proc 402 401 422 /usr/bin/zsh
write_proc 403 402 433 /opt/codex/bin/codex resume inner-session
write_proc 404 403 444 /usr/bin/sh -c codex-sessionstart-receipt
run_hook 404 '{"session_id":"inner-session","source":"resume"}'
jq -s -e '
  length == 1 and
  .[0].pid == 403 and
  .[0].session == "inner-session"
' "$HOME_DIR/.codex/session-tags.jsonl" >/dev/null ||
  fail 'nested Codex receipt tagged an outer Codex ancestor'

: >"$HOME_DIR/.codex/session-tags.jsonl"
write_proc 301 1 311 /usr/bin/zsh
write_proc 302 301 322 /usr/bin/python3 /tmp/codex resume not-codex
run_hook 302 '{"session_id":"not-codex","source":"resume"}' 2>/dev/null
[[ ! -s "$HOME_DIR/.codex/session-tags.jsonl" ]] ||
  fail 'non-Codex /tmp/codex argv produced a receipt'

run_hook 302 '{"source":"resume"}' 2>/dev/null
[[ ! -s "$HOME_DIR/.codex/session-tags.jsonl" ]] ||
  fail 'malformed payload produced a receipt'

printf 'PASS: Codex SessionStart receipt binds exact Codex process identities\n'
