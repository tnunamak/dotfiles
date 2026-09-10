#!/usr/bin/env bash
# Proves bin/.local/bin/model-policy-check actually catches drift between
# ai/AGENTS.md rule 1 and the minnows model-choice-policy pack, and passes
# once they agree again.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/bin/.local/bin/model-policy-check"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/model-policy-check-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

AGENTS_FIXTURE="$TEST_ROOT/AGENTS.md"
cat >"$AGENTS_FIXTURE" <<'EOF'
1. Use Codex `gpt-6-astra`: medium effort by default, never xhigh/max by default.
EOF

drifted_pack() {
  cat >"$TEST_ROOT/drifted.json" <<'EOF'
{
  "generated_at": "2026-09-01",
  "operating_points": [
    {"id": "review.audit", "expands_to": {"provider": "codex", "model": "gpt-5.6-sol", "effort": "xhigh"}},
    {"id": "implement.standard", "expands_to": {"provider": "claude", "model": "claude-sonnet-5", "effort": "medium"}}
  ]
}
EOF
}

matching_pack() {
  cat >"$TEST_ROOT/matching.json" <<'EOF'
{
  "generated_at": "2026-09-08",
  "operating_points": [
    {"id": "review.audit", "expands_to": {"provider": "codex", "model": "gpt-6-astra", "effort": "high"}},
    {"id": "implement.standard", "expands_to": {"provider": "claude", "model": "claude-sonnet-5", "effort": "medium"}}
  ]
}
EOF
}

drifted_pack
if AGENTS_MD="$AGENTS_FIXTURE" WASPFLOW_OPS_POLICY="$TEST_ROOT/drifted.json" "$SCRIPT" >"$TEST_ROOT/out.log" 2>&1; then
  fail "expected non-zero exit against a drifted pack, got 0:\n$(cat "$TEST_ROOT/out.log")"
fi
grep -q "gpt-5.6-sol" "$TEST_ROOT/out.log" || fail "drift failure output didn't name the offending model"
grep -q "xhigh" "$TEST_ROOT/out.log" || fail "drift failure output didn't flag the forbidden effort"
echo "ok - drifted pack fails with a clear message"

matching_pack
if ! AGENTS_MD="$AGENTS_FIXTURE" WASPFLOW_OPS_POLICY="$TEST_ROOT/matching.json" "$SCRIPT" >"$TEST_ROOT/out2.log" 2>&1; then
  fail "expected zero exit against a matching pack, got non-zero:\n$(cat "$TEST_ROOT/out2.log")"
fi
echo "ok - matching pack passes"

echo "PASS: model-policy-check catches drift and passes when policies agree"
