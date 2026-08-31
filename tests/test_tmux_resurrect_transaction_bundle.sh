#!/usr/bin/env bash
# Pure-file regression checks for tmux resurrect transaction bundles.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/tmux/.config/tmux/scripts/resurrect-transaction-bundle"
WORK="$(mktemp -d "${HOME}/.tmp/tmux-resurrect-bundle.XXXXXX")"
trap 'chmod -R u+w "$WORK" >/dev/null 2>&1 || true; rm -rf "$WORK"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

layout_file() {
  local path="$1" count="$2" i
  : >"$path"
  for ((i = 0; i < count; i++)); do
    printf 'pane\tmain:%s.0\t/home/tnunamak\t1\tbash\n' "$i" >>"$path"
  done
}

assistant_file() {
  local path="$1" count="$2" i
  printf '{"sessions":[' >"$path"
  for ((i = 0; i < count; i++)); do
    (( i > 0 )) && printf ',' >>"$path"
    printf '{"pane":"main:%s.0","tool":"codex","session_id":"session-%s"}' "$i" "$i" >>"$path"
  done
  printf ']}\n' >>"$path"
}

export HOME="$WORK/home"
export TMUX_RESURRECT_DIR="$HOME/.tmux/resurrect"
export TMUX_RESURRECT_BUNDLE_NOW_ISO="2026-08-30T21:00:00Z"
mkdir -p "$TMUX_RESURRECT_DIR"

layout191="$WORK/tmux_resurrect_20260830T162912.txt"
assistant110="$WORK/assistant-sessions-20260830T162912.json"
layout_file "$layout191" 191
assistant_file "$assistant110" 110

bundle_path="$("$CLI" commit --layout "$layout191" --assistant "$assistant110" --provenance "test clean baseline" --id clean-191-110)"
[[ -d "$bundle_path" ]] || fail 'bundle directory was not created'
[[ -f "$TMUX_RESURRECT_DIR/transactions/last-good.json" ]] || fail 'last-good pointer missing'
[[ "$(jq -r '.components.layout.count' "$bundle_path/bundle.json")" == 191 ]] || fail 'layout count not recorded'
[[ "$(jq -r '.components.assistant.count' "$bundle_path/bundle.json")" == 110 ]] || fail 'assistant count not recorded'
[[ ! -w "$bundle_path/bundle.json" ]] || fail 'bundle manifest should be immutable'

resolved="$("$CLI" resolve)"
[[ "$(jq -r '.id' <<<"$resolved")" == clean-191-110 ]] || fail 'resolve did not return clean bundle'
[[ "$(jq -r '.components.layout.count' <<<"$resolved")" == 191 ]] || fail 'resolve did not preserve layout count'

# Normal periodic saves keep the legacy 20% floor, so 191 -> 59 is accepted.
layout59="$WORK/tmux_resurrect_20260830T163320.txt"
layout_file "$layout59" 59
periodic_bundle_path="$("$CLI" commit --layout "$layout59" --assistant "$assistant110" --provenance "test periodic shrink" --id periodic-59)"
[[ -d "$periodic_bundle_path" ]] || fail 'periodic 191 -> 59 bundle was not created'
[[ "$(jq -r '.id' "$TMUX_RESURRECT_DIR/transactions/last-good.json")" == periodic-59 ]] \
  || fail 'periodic accepted layout did not advance last-good'

# Reproduce the incident's stop-time layout failure: tmux-service-stop exports
# an 80% floor, so 191 -> 59 must be rejected.
export TMUX_RESURRECT_SAVE_MIN_PCT=80
bundle_path="$("$CLI" commit --layout "$layout191" --assistant "$assistant110" --provenance "test clean baseline again" --id clean-191-110-stop)"
reject_log="$WORK/reject-layout.log"
if "$CLI" commit --layout "$layout59" --assistant "$assistant110" --provenance "test degraded stop save" --id degraded-59 >"$reject_log" 2>&1; then
  fail '191 -> 59 layout cliff was accepted'
fi
grep -q 'layout count cliff rejected: previous=191 candidate=59' "$reject_log" \
  || fail 'layout cliff rejection reason missing'
[[ "$(jq -r '.id' "$TMUX_RESURRECT_DIR/transactions/last-good.json")" == clean-191-110-stop ]] \
  || fail 'rejected layout cliff advanced last-good'

# Reproduce mixed generations: layout remains clean, assistant sidecar has the
# independently rejected 110 -> 4 collapse.
assistant4="$WORK/assistant-sessions-20260830T163320.json"
assistant_file "$assistant4" 4
mixed_reject_log="$WORK/reject-mixed.log"
if "$CLI" commit --layout "$layout191" --assistant "$assistant4" --provenance "test mixed sidecar" --id mixed-191-4 >"$mixed_reject_log" 2>&1; then
  fail 'mixed clean layout and collapsed assistant sidecar was accepted'
fi
grep -q 'assistant count cliff rejected: previous=110 candidate=4' "$mixed_reject_log" \
  || fail 'assistant cliff rejection reason missing'

# A committed bundle resolves fail-closed if any component is missing or mixed
# with another generation after commit.
chmod -R u+w "$bundle_path"
assistant_component="$(jq -r '.components.assistant.file' "$bundle_path/bundle.json")"
assistant_file "$bundle_path/$assistant_component" 109
corrupt_log="$WORK/corrupt.log"
if "$CLI" resolve >"$corrupt_log" 2>&1; then
  fail 'corrupt mixed-generation bundle resolved successfully'
fi
grep -q 'component hash mismatch for assistant' "$corrupt_log" \
  || fail 'corruption rejection reason missing'

bundle_path="$("$CLI" commit --layout "$layout191" --assistant "$assistant110" --provenance "test clean baseline 2" --id clean-191-110-b)"
chmod -R u+w "$bundle_path"
layout_component="$(jq -r '.components.layout.file' "$bundle_path/bundle.json")"
rm -f "$bundle_path/$layout_component"
missing_log="$WORK/missing.log"
if "$CLI" resolve >"$missing_log" 2>&1; then
  fail 'bundle with missing layout component resolved successfully'
fi
grep -q 'component missing for layout' "$missing_log" \
  || fail 'missing-component rejection reason missing'

printf 'PASS: tmux resurrect transaction bundles reject cliffs and corrupt mixed components\n'
