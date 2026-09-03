#!/usr/bin/env bash
# Exercise the updates picker with fake external commands.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATES="$ROOT/bin/.local/bin/updates"
WORK="$(mktemp -d "$HOME/.tmp/updates-picker-test.XXXXXX")"
TEST_HOME="$WORK/home"
TEST_BIN="$WORK/bin"
FZF_LOG="$WORK/fzf-args"
NALA_LOG="$WORK/nala-args"
FZF_FIXTURE="$ROOT/tests/fixtures/updates-picker/fzf"
NALA_FIXTURE="$ROOT/tests/fixtures/updates-picker/nala"
mkdir -p "$TEST_HOME/.cache/shell-status" "$TEST_BIN"
trap 'rm -rf "$WORK"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

printf 'first\ttrue\nsecond\ttrue\nnala\tnala upgrade\n' \
  >"$TEST_HOME/.cache/shell-status/commands"

for command_name in sudo shell-status-refresh; do
  ln -s /usr/bin/true "$TEST_BIN/$command_name"
done
ln -s "$FZF_FIXTURE" "$TEST_BIN/fzf"
ln -s "$NALA_FIXTURE" "$TEST_BIN/nala"

run_picker() {
  : >"$FZF_LOG"
  : >"$NALA_LOG"
  FZF_TEST_LOG="$FZF_LOG" NALA_TEST_LOG="$NALA_LOG" \
    HOME="$TEST_HOME" PATH="$TEST_BIN:/usr/bin:/bin" \
    "$UPDATES" --apply "$@" >/dev/null
}

run_picker
grep -qFx -- '--layout=reverse' "$FZF_LOG" \
  || fail 'normal picker does not start at the top'
grep -qFx -- 'upgrade' "$NALA_LOG" \
  || fail 'normal picker unexpectedly auto-confirms nala'

run_picker --yes
grep -qFx -- '--layout=reverse' "$FZF_LOG" \
  || fail '--yes picker does not start at the top'
grep -qFx -- 'upgrade --assume-yes' "$NALA_LOG" \
  || fail '--yes does not auto-confirm nala'

run_picker --all
[[ ! -s "$FZF_LOG" ]] \
  || fail '--all unexpectedly opens the picker'
grep -qFx -- 'upgrade' "$NALA_LOG" \
  || fail '--all unexpectedly auto-confirms nala'

run_picker --all --yes
[[ ! -s "$FZF_LOG" ]] \
  || fail 'combined --all --yes unexpectedly opens the picker'
grep -qFx -- 'upgrade --assume-yes' "$NALA_LOG" \
  || fail 'combined --all --yes does not auto-confirm nala'

echo 'PASS: picker starts at top; --all skips it independently of --yes'
