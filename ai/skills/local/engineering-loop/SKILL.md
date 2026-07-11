---
name: engineering-loop
description: Run a high-agency, gated engineering loop for any substantial task (refactor, triage, migration, deploy). Use when a task is open-ended enough to warrant autonomous iteration rather than a single edit. Decides WHETHER to loop, aligns on target+bar+cost before committing, then runs maker→independent-checker→oracle until a VERIFIABLE stop-condition holds. The agent cannot self-declare done and cannot grade its own work. Task-specifics come from a plugged-in task profile; this skill is the task-agnostic machinery.
---

# Engineering Loop (general, task-agnostic)

The reusable machinery for running a substantial task as a gated loop. It knows NOTHING about any specific task — a **task profile** (a sibling skill, e.g. `refactor-loop`) fills the slots and brings its OWN methodology corpus. Grounded in:
- `ai/research/agentic-context-design/procedural-md-spec-as-agent-loop-control-flow.md` (loop engineering 2026; maker/checker; self-eval fails; verifiable stop-conditions)
- `ai/research/agentic-context-design/refactoring-loop-as-skill-plus-workflow-composition.md` (the A/B/Workflow decomposition; why enforcement is structural)

## The bar
**SLVP-ideal, applied to the work itself** — the best we can do given prior-art research, the best systems in the world, and our own observed failure modes. Not "good enough."

## The non-negotiable invariants (why this loop exists)
1. **Truth is the bottleneck.** Agent throughput is ~unlimited; the scarce thing is the owner's attention + the cost of knowing what's true. Make truth CHEAP: compact evidence packets, exact commands, real state (PR/live/deploy). **A worker's summary is a CLAIM to verify, never truth.** Worker completion ≠ owner completion.
2. **Cannot self-grade.** Every change is judged by a DIFFERENT-MODEL checker + a real tool oracle. Self-evaluation is empirically unreliable ("agents confidently praise their own mediocre work"). The checker must produce an EVIDENCE ARTIFACT (read the diff, run the oracle, verify the specific claims, write a verdict) — different-model-without-evidence is rubber-stamp theater.
3. **Cannot quit early.** The agent does not get to self-declare done. An outer done-check reopens "is this actually complete against the stated ideal?" Done is decided by the verifiable stop-condition, not the agent's fatigue.
4. **Ambition check.** Is the target commensurate with what the owner asked for, or merely SAFE? Safe-but-small when the ask was big is a FAILURE. (This is the failure mode that motivated the loop.)
5. **Fail-closed + honest.** Divergence / uncertainty / no-safe-target → STOP and surface the real choice. Never substitute an easy target and call it impactful. A verified non-finding ("nothing cleared the bar") is a first-class valid result — but only after the right measurement + adversarial check.
6. **Low burn.** Cheap recon before any commitment; fan out only when bounded; reserve expensive models for gates; stop/poll instead of foreground-burning; don't re-discover. Pace by headroom (clawmeter est); throttle if hot.
7. **Durable capture (HARD RULE).** Any prior-art research or new distilled methodology lands in `ai/research/` with sources+dates+conclusions — NOT only tmp/chat/skill. Preserve owner STEERING as structured memory: red lines, rejected interpretations, accepted vocabulary, decision logs. The loop must not ship mechanics while losing the reason they exist.
8. **Don't multiply surfaces.** Reuse COLLAPSES repeated machinery; it does not proliferate packages/loops/modes. No agent-invented vocabulary unless prior art supports it.

## The task profile must DECLARE (the universal evidence contract — Layer A's slots, the task fills them)
- **stop_condition** — VERIFIABLE ("X tests pass AND complexity < N AND a different-model checker confirms ideal-membership"), never subjective ("improve the code").
- **oracle** — the exact commands that decide pass/fail (test runner, linter, type-check). The real judge.
- **checker** — model/role of the independent checker + what evidence artifact it must produce. **The checker must be AT LEAST AS STRONG as the maker** (a weaker checker rubber-stamps). Use GPT-5.6 only: Terra for bounded making/writing, Sol for synthesis and judged checker/final gates, and Luna only for mechanical or light checks that do not decide acceptance. Never fall back to GPT-5.5, 5.4, or 5.3. Independence still requires a separate session that reads the diff and raw evidence rather than the maker's summary; use a different lineage only when it also satisfies the GPT-5.6 constraint.
- **acceptance_level** — code / journey / live-deploy / owner-retest. Internal construction criteria (tests, diff review) are NECESSARY, never the acceptance target unless behavior is intentionally unchanged.
- **discovery** — how to find + RANK + CLASSIFY targets (incl. inspecting hard/no-go areas enough to classify them: essential-complexity / protocol-sensitive / high-value-but-owner-gated — never exclude-then-conclude-nothing-exists).
- **memory** — the rejected-approaches ledger shape (each entry: approach · evidence · why · when-to-reconsider).
- **owner_gate** — what requires owner authorization (behavior changes, no-go, deploy, live data).
- **cleanup** — closeout: report path, branch/worktree fate, reaping, what's durable vs discarded.
- **fail_output** — the shape of the "one sharp question" / non-finding / blocked output.

## The loop (states; the agent reasons WITHIN a state, the gate controls transitions)

**S0 PREFLIGHT** — correct-lineage / fresh-from-main / live-revision check when the task depends on repo/deploy state. (A stale checkout poisons discovery.) → fail-closed if wrong.

**S1 RECON & DECIDE-TO-LOOP** — cheap measurement (the task's discovery, the REAL tools not proxies). Is a loop even warranted? Estimate scope + cost. High agency: DECLINE the expensive path if it won't pay; a tiny safe PR may not need a loop. Output: ranked targets + classification + a go/no-go-loop recommendation.

**S2 ALIGN** — surface target + bar + cost + the real forks (incl. "the most impactful target is owner-gated/no-go — authorize or take the safe-smaller win?"). Get owner go. Proceed on clear-cut; stop-and-align on expensive/risky/uncertain.

**S3 DERIVE GOAL** — if intent was loose, convert it to a concrete VERIFIABLE stop_condition (the planner). Planner proposes; it does NOT also judge.

**S4 MAKE** — maker subagent produces the change against the task profile + methodology.

**S5 CHECK (the gate)** — a DIFFERENT-MODEL checker reads the DIFF (not the maker's summary), runs the oracle, verifies the task's specific claims (e.g. caller counts, behavior-preservation, slop checklist), writes an evidence-artifact verdict. PASS / REVISE / REJECT.

**S6 DONE-CHECK (no lazy stop)** — reopen "is this actually complete against the stated ideal AND commensurate with the ask?" If the stop_condition is verifiably true AND the ambition check passes → S7. Else re-inject → S4 (with the rejection evidence), or escalate the design fork to the owner (one sharp question), or record a verified non-finding.

**S7 LAND / CLOSEOUT** — emit the truth-cheap result (PR + evidence packet, OR one sharp question, OR honest non-finding + map). Run cleanup. Append durable memory. NO confidence score — the outcome is structural.

## How to run it
The KNOWLEDGE is this skill + the task profile. The ENFORCEMENT is structural: spawn the maker and the different-model checker as separate subagents; the oracle is real commands whose pass/fail you cannot override; transitions are gated, not narrated. Use the Workflow harness (or `/goal`-style run-until-verified) so S4→S5→S6 actually iterates and the agent cannot talk past a gate. Reason freely inside a state; you may not skip a gate.
