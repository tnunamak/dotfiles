---
name: instruction-compliance-enforcement
description: Measured instruction-following compliance rates in LLM agents; timing/placement effects; hook vs prompt enforcement; multi-turn degradation; sycophancy
source_session: 9f41c247-0f8f-467e-a00d-ce2b4f96aae4
---

# Instruction-Following Compliance in LLM Agents

## Key Findings Summary

### Baseline Compliance Rates (Benchmarked)

**Measured on agentic instruction-following benchmarks:**
- **AGENTIF** (real-world agent tasks, 1,723 word avg, ~12 constraints): best model 27.2% ISR (instruction success rate)
- **HANDBOOK.md** (policy documents, 20–124 pages, 82 tools): Claude Fable 5 at 36.2%, prior SOTA 21.9%
- **Process compliance** (targeted audit): 97% (audit trails), 0–4% (sequential file reading, PII masking)

Interpretation: instruction-following is task-dependent and dominantly influenced by whether RLHF training observed and rewarded that behavior. Compliance with process constraints is dramatically lower than compliance with formats/structures.

### Architectural Enforcement > Behavioral Compliance

**Two-tier system:**
- **Prompt-only (guidance): 70–90% ceiling** under default conditions; compliance degrades 39–112% worse in multi-turn (turns 1→3 drops from 88%→71% for state-of-art)
- **Hook-enforced (structural): 100%** because checks execute at framework level, outside LLM's reasoning chain

**Critical implication**: reminders and reframing cannot bridge the gap between 70–90% and 100%. They are different architectural tiers.

### Position/Timing Effects (Within Prompt-Only Regime)

**Measured improvements** (relative to baseline, all <100%):
- **Recency bias dominant**: end-of-prompt instructions outperform middle placement
- **System vs. user role**: user-role reminders (recent) > system-role reminders (early) in multi-turn
- **Decision-point timing critical**: reminders positioned immediately before decision-LLM-call show max impact
- **Frequency-induced fatigue**: reminders on every turn regress compliance (model learns to ignore)

**What does NOT work:**
- Relocating middle instructions to start/end cannot overcome 39% multi-turn degradation
- System-prompt placement (46.06% accuracy) beats user-prompt placement (35.76%), contradicting simple recency-wins narrative—likely reflects attention to role in architecture

### Multi-Turn Session Degradation

**Empirically measured:**
- 39–112% worse compliance (multi-turn vs. single-turn)
- Mistral-7B: 100%→45% recall by turn 50
- Leading models sustain ~18 reliable turns before significant drift
- Average 39% degradation when instructions are sharded across turns vs. given in full at turn 1

**Mitigation strategies:**
- Concatenating all information achieves 95.1% of single-turn baseline
- Sliding-window refreshes of core instructions help but don't eliminate decay

### Sycophancy and Conflicting Instructions

- Models align with mutually contradictory user claims (non-contradiction tests fail)
- RLHF directly exacerbates this (reward training doesn't observe behavioral fidelity, only text quality)
- Stronger in subjective domains; objective domains (math, code) show higher resistance

## Design Principles for Waspflow

1. **Use hooks for non-negotiable constraints**, not prompts. The 70–90% ceiling is not negotiable via reminding.
2. **Optimize reminder timing within prompt layer** (end-of-context, role:user, at decision point), but do not expect this to overcome architectural limits.
3. **Expect 39% degradation over multi-turn sessions** if relying on prompt-only guidance; mitigate with refresh strategies or architectural enforcement.
4. **Hook frequency should be low and targeted** (per decision point), not on every turn (creates noise).
5. **Position effects are real but secondary** to reward-signal alignment. Better formatting/placement cannot overcome missing training signal.

## Open Research Gaps

- **No empirical data on hook compliance degradation over long sessions.** All published research reports "100% enforcement" but doesn't measure whether hook-firing degrades or whether malformed hook-outputs are ignored by agents.
- **Sycophancy-hook interactions untested.** Could an agent with hook-enforced policy be sycophantly convinced to disable the hook? (Unlikely, but no proof.)
- **Optimal hook placement/frequency unknown.** Research exists on prompt-reminder timing; none on hook-firing patterns.

## Sources

- **The Compliance Gap** (Kwan Soo Shin, May 2026): audit-based compliance measurement; BS-Bench benchmark; RLHF-mismatch root cause
- **AGENTIF** (THU-KEG, 2025): agentic instruction-following benchmark; real-world task construction
- **HANDBOOK.md** (June 2026): long-context policy adherence; 65 company environments, 824 deterministic criteria
- **When Attention Closes** (2026): multi-turn degradation patterns; 39% & 112% worse performance; turn-specific decay curves
- **Position is Power** (May 2026): system vs. user prompt placement; 46.06% vs. 35.76% accuracy
- **LLM Position Bias: Primacy and Recency Effects** (IntuitionLabs): attention-weight distribution; U-shaped serial position curve
- **Agent Hooks / AgentSpec / Runtime Enforcement** (multiple 2025–2026): hook-enforced compliance; 100% success rates in practice; no degradation curves published

See `/home/tnunamak/.tmp/research-priorart/instruction-compliance.md` for detailed claims, URLs, and verbatim quotes.
