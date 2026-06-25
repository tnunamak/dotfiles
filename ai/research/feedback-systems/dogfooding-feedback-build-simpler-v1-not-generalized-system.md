---
title: "Build a simpler hardened v1 dogfooding-feedback detector, not the generalized system; let a 2-week trial decide sufficiency"
date: 2026-06-25
topic: feedback-systems
tags: [feedback, dogfooding, decision, code-review, posttooluse, roster]
status: settled
sources: [codex-arch-review-2026-06-25, codex-rebuttal-2026-06-25, posttooluse-schema-entry, event-gated-entry]
---

## CLAIMS

- An independent gpt-5.5 (xhigh) review of the dogfooding-feedback design concluded: keep the research-corpus architecture, but build a SIMPLER hardened v1 of the feedback hook rather than the full generalized system. [codex-arch-review-2026-06-25]
- "Add a tool = add a name to a watchlist" does NOT hold: without an exit code (PostToolUse gives none), failure detection needs per-tool or per-family matchers; the generic part is the pipeline/state machine, the tool-specific part is invocation matching + high-signal error regexes. [codex-arch-review-2026-06-25, posttooluse-schema-entry]
- The roster should live in a small config file (e.g. ai/dogfooding/roster.yaml) with per-tool fields (kind, command_match, friction_patterns, ledger, cooldown_days, redact_patterns, active), NOT as a big always-on AGENTS.md block. [codex-arch-review-2026-06-25]
- Stop is the wrong nudge surface (capture-only per the hook-mechanics entry, and fires when interruption is most annoying); use SessionStart, ≤1 nudge per session/day after dedup+cooldown. [codex-arch-review-2026-06-25]
- A global Bash PostToolUse hook sees every command across all concurrent agents, so it MUST: redact secrets/URLs/tokens (store normalized signatures + small redacted snippets, not raw stderr), use flock/atomic append for state, run with a short timeout and fail silently, and have a kill switch. [codex-arch-review-2026-06-25]
- Drop from v1: "notable clean success" auto-detection (not machine-detectable from generic stderr) and the "haven't used X in 30 days" staleness nudge (abandonment != failure). Leave success to the agent instruction. [codex-arch-review-2026-06-25]
- The detector must record CANDIDATE events only and never write ledger prose; the agent writes the ledger entry (judgment/quality a script cannot produce). [codex-arch-review-2026-06-25]
- The reviewer's initial "do not build it; instruction-only already works" conclusion was WITHDRAWN: it rested on the local inbox/devspecs-feedback.md ledger, which is weak self-referential n-of-1 evidence from the same session's improvised trial and must not override independent prior art (ESM event-contingent sampling; OTel tail sampling). Sufficiency of instruction-only is UNKNOWN until tested. [codex-rebuttal-2026-06-25, event-gated-entry]
- Agreed resolution across the user, the orchestrator, and the independent reviewer: build the simple event-gated hook, run a 2-week trial, keep it only if it produces ledger entries the AGENTS instruction would have missed. [codex-rebuttal-2026-06-25]

## SOURCES

**codex-arch-review-2026-06-25**
URL: local — ~/.tmp/archrev4-corpus-feedback-review.md (Codex gpt-5.5 xhigh review via waspflow lane archrev4, 2026-06-25)
Accessed: 2026-06-25
Quote: "Build a simpler variant, not the design as written... build only this v1: roster.yaml; a Claude-only Bash PostToolUse detector that records candidate friction events and never writes the ledger; a SessionStart nudge ≤1 per session/day; keep Codex instruction-only; fixture tests; trial for two weeks."

**codex-rebuttal-2026-06-25**
URL: local — ~/.tmp/reviewer-rebuttal.txt (headless follow-up to the same session, 2026-06-25)
Accessed: 2026-06-25
Quote: "my ledger-based argument was too strong... self-referential n-of-1 signal from the same local trial. It should not dominate independent prior art... build the simple event-gated hook, not the full generalized system, and let the trial decide whether it earns its keep."

**posttooluse-schema-entry**
URL: ai/research/agentic-context-design/claude-posttooluse-hook-wire-schema-bash.md
Accessed: 2026-06-25
Quote: PostToolUse for Bash gives tool_response.{stdout,stderr,interrupted} but no exit_code/is_error — failure must be inferred.

**event-gated-entry**
URL: ai/research/feedback-systems/event-gated-feedback-beats-cadence-for-tool-dogfooding.md
Accessed: 2026-06-25
Quote: Event-contingent sampling reliably catches rare friction events; cadence does not. The prior-art basis the build decision rests on.

## SYNTHESIS

This supersedes the build-scope implied by [[event-gated-feedback-beats-cadence-for-tool-dogfooding]]
(policy unchanged; the MECHANISM is narrowed). v1 to build:
1. ai/dogfooding/roster.yaml — devspecs first (kind: cli; command_match for `ds`/`devspecs`
   incl. wrapped `rtk ds`; friction_patterns like `^Error:`, `no such column`; ledger path;
   cooldown_days; redact_patterns; active flag).
2. Claude-only Bash PostToolUse detector (bin/.local/bin/, stow-managed) → appends candidate
   events to ~/.local/state/agent-dogfood-feedback/events.jsonl (0600, flock/atomic). Triggers
   only on roster CLI invocation + (interrupted | long-interrupted duration | retry signature |
   high-signal stderr). NEVER writes the ledger. Short timeout, fail silent, kill switch.
3. SessionStart nudge: surface ≤1 pending candidate per session/day after dedup+cooldown,
   "log only if you have enough context." No Stop nudge.
4. Codex stays instruction-only; do NOT wire Gemini until its PostToolUse-equivalent payload is
   empirically captured (same discipline that corrected the Claude .d.ts).
5. Fixture tests: success-with-stderr, Cobra error, schema error, interrupted-long, repeated
   retry, wrapped `rtk ds`, secret redaction.
6. Two-week trial; keep only if it surfaces friction the instruction would have missed; else delete.
Also recommended (cheap, independent of the hook): a corpus validator (links/frontmatter/
sections/slug-coverage) and preserving redacted empirical hook fixtures next to their entries.
Separately: the existing ledger already supports a maintainer digest for Brennan — send that.
