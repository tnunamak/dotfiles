---
name: bet-the-company-hardening
description: "Run an evidence-led hardening engagement for an existing project when the user asks to make it bettable, production-ready, launch-ready, highly reliable, or to find and fix the risks that could make a company-level commitment unsafe. Use for hardening audits, security/reliability/operability hardening, release-readiness, pre-launch hardening, and adversarial validation. This is a task profile for `engineering-loop`: read that skill first, then use this profile to assess → bettable-hardening → excellence audit → release without confusing those bars."
---

# Bet-the-Company Hardening

Use this skill to reduce an evidenced reliability, security, integrity, operability, or release risk in an **existing** project. Preserve observable project behavior unless the owner explicitly authorizes its change. Do not call a product hard because its tests are green or a worker says it is done.

Read **`engineering-loop` first**. It supplies the loop machinery, independent checker rule, and universal evidence contract. This profile supplies the hardening-specific bars, evidence, and failure modes. Do not create a second orchestration system.

## Read the playbook at the right time

Read [`references/playbook.md`](references/playbook.md) before assessment; read its phase section before entering each later phase. Read its delegation, red-team, trap, and report sections whenever delegating, interpreting a failure, or issuing a confidence/release claim. It contains the candidate cards, checklists, and exact report contract; keep this file as the control plane.

## Non-negotiable rules

1. Start from implementation, state transitions, raw Git/release state, and real user journeys. Issue lists, dashboards, curated lists, and status summaries are leads, not truth.
2. Protect a named invariant. For a fleet or workflow tool, start with: never silently claim submitted, succeeded, recovered, or released when that did not happen; adapt the invariant to the project.
3. Treat unit/integration tests as necessary evidence, not proof of an interactive or distributed journey. Exercise the valuable journey against real boundaries and assert an observable effect.
4. Separate maker from judge. The maker may propose and implement; a different-model checker at least as capable as the maker reads the actual diff and evidence, reruns the oracle, and writes a `PASS`, `REVISE`, or `REJECT` evidence artifact. Prefer a different lineage. If no separate capable checker is available, stop blocked rather than self-grade. Independently reproduce every red-team finding before fixing or reporting it.
5. Keep behavior stable. A discovered behavior change, public-surface change, deployment, destructive probe, live-data action, or policy decision is an owner gate.
6. Report a scoped numeric confidence with named residual gaps and the evidence that justifies the estimate. It is decision-support judgment, not a percentage derived from test counts. Revise it up or down only when new evidence opens or closes a named gap; never average worker confidence. This profile adds that register to `engineering-loop`; structural gates remain the source of truth.
7. Stop honestly: return a verified non-finding, a blocked decision, or a `release-ready` verdict when the gate is not met. Do not turn an easy cleanup or compensating recovery feature into a fake hardening win.

## Four phases and their gates

### 1. Assess

Map the revision, valuable journeys, trust/state boundaries, current checks, release path, no-go zones, and baseline failures. Rank risks by impact, likelihood, evidence quality, detectability, and boundedness. Establish the starting confidence and residual-gap register.

**Exit only when:** the assessment packet records raw baseline commands/results and identifies either a bettable target or a verified reason none is safe to pursue.

### 2. Bettable hardening

Select one bounded wager: observed failure/abuse path, protected invariant, deterministic oracle, live journey, limited blast radius, rollback, and owner authority. Fix the causal mechanism; reject stale-by-construction lists and recovery features that merely conceal the root cause. Add regression coverage for confirmed defects, including failure paths and command/contract exit status.

**Bettable gate:** deterministic checks pass; the failure path is blocked or handled honestly; the intended path still works; a real live journey proves the claim beyond tests; applicable mixed/concurrent/soak evidence passes; independent red-team findings are reproduced and resolved or named as residuals. This gate says the defined company-critical invariant is safe enough to bet on. It does **not** say every surface is excellent.

### 3. Excellence audit

Audit the complete affected command/API/config/recovery surface, not just seams found while building. Use an independent, capable auditor in a clean worktree. Test malformed input, corrupted or incompatible state, concurrency, interrupted work, error quality, observability, documentation, and result laundering. Verify each real finding separately; false positives are evidence about the test, not defects.

**Excellence gate:** the independent audit passes with evidence; no known affected surface silently lies, corrupts, leaks raw internal errors, or laundered an unknown state into success; all remaining imperfections are explicitly classified as intentional tradeoffs or owner-gated work. Excellence is a separate claim from bettable and may remain blocked after the bettable gate passes.

### 4. Release

Distinguish `release-ready` from `released`. Follow the project’s authorized release path. Then identify the exact published artifact (tag, digest, package version, image, or installer), check it out or install it cleanly, and run its release gate plus a realistic install/use health check. Compare raw Git, remote, release, and artifact state; never infer release from a successful pipeline or a status summary.

**Release gate:** exact artifact, publication state, gate output, install/journey result, rollback path, authorization, and residuals are recorded. Post-artifact commits need an explicit release-policy explanation.

## Delegation and cost discipline

Before fanning out, use `clawmeter` or equivalent current provider-usage/cost/headroom evidence **when available**. Use GPT-5.6 only: Terra for bounded making/writing, Luna for mechanical/light checks, and Sol for synthesis and judged/final gates. Never fall back to GPT-5.5, 5.4, or 5.3. If GPT-5.6 is unavailable, stop blocked rather than silently substituting a model. Never assume a provider or quota tool exists.

Delegate only bounded work: one failure class, explicit scope, time/cost cap, isolated worktree, exact commands, artifacts to preserve, and a report contract. Waspflow-style lanes/worktrees are useful when available; otherwise create equivalent isolated worktrees or directories and collect the same evidence. A worker report is a hypothesis until independently reproduced.

## Evidence packet and stop condition

Return or store only where the project already keeps records; do not invent a reporting subsystem. The compact packet contains:

| Artifact | Required contents |
| --- | --- |
| Assessment | revision/environment; journey and surface map; baseline commands/results; ranked risks; no-go/owner gates; confidence and named residuals |
| Bet record | observed scenario; invariant; chosen causal control; deterministic oracle; live journey; blast radius; rollback; before/after evidence |
| Excellence verdict | diff/stat; surface checklist; independent audit and reproductions; positive/negative proof; `PASS`/`REVISE`/`REJECT` |
| Release decision | exact artifact and raw publication state; gate/install results; authorization; rollback; residuals; `release-ready` or `released` |

The verifiable stop condition is: every gate required by the requested acceptance bar has passed with this packet. `bettable-not-excellent` is valid when only the bettable bar was requested or excellence remains explicitly open; `release-ready` means the requested pre-release gates passed but publication is unauthorized or incomplete. Otherwise state the smallest missing proof or owner decision. Do not manufacture a confidence number to make the stop condition look true.
