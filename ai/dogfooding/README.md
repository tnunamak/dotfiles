# Dogfooding feedback (v1)

Captures friction when roster tools (see `roster.yaml`) hit errors, so the agent
gets nudged to log an honest entry to the tool's ledger. Event-gated, rate-limited,
agent-writes-prose. Design + rationale (incl. the independent review that scoped it):
`ai/research/feedback-systems/dogfooding-feedback-build-simpler-v1-not-generalized-system.md`.

## Pieces (all stow-managed)

- `roster.yaml` — the tools to watch + per-tool matchers, friction patterns, redaction.
  A tool with a `feedback:` block (maintainer + ledger) reports to that maintainer (e.g.
  devspecs → Brennan); a tool **without** one is a private keep/drop/tweak signal. That
  presence/absence is the only provenance the system needs — no `owner`/`intent` labels
  (they'd be the same distinction wearing extra names). Add a tool only once you've
  observed a real command shape + friction pattern; don't pre-stub unverified tools.
- `bin/.local/bin/dogfood-feedback-detect` — Claude **PostToolUse** hook. On a roster-tool
  Bash call that hits friction (stderr error pattern / interrupted), appends a **redacted**
  candidate event to the state dir. Never writes a ledger. Fail-silent.
- `bin/.local/bin/dogfood-feedback-nudge` — Claude **SessionStart** hook. Surfaces ≤1 pending
  candidate per day as a factual note; the agent decides whether to log. Fail-silent.
- Wired in `claude/.claude/settings.json` (PostToolUse + SessionStart). **Claude only** —
  Codex has no hooks (instruction-only); Gemini not wired until its PostToolUse payload is
  empirically verified.

## State

`~/.local/state/agent-dogfood-feedback/` (0700): `events.jsonl` (0600, flock'd),
`.last-nudge` (daily-cap marker). Nothing here is committed.

## Kill switch

```bash
touch ~/.local/state/agent-dogfood-feedback/OFF     # disable detector + nudge entirely
rm    ~/.local/state/agent-dogfood-feedback/OFF     # re-enable
```
Both hooks check for `OFF` first and exit immediately if present. A bad global hook is
worse than missed feedback — this is the escape hatch.

## Trial

This is a 2-week experiment. Keep it only if it surfaces friction the AGENTS.md instruction
would have missed; otherwise delete the two hook entries from settings.json and the scripts.

## Tests

`bin/.local/bin/dogfood-feedback-test` and `bin/.local/bin/dogfood-feedback-nudge-test`
(run against a temp state dir; safe to run anytime).
