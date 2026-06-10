---
name: agent-steering-audit
description: "Audit long-running AI-agent sessions to understand how human steering effort converts into outcomes. Use this skill whenever the user asks about steering drift, forgotten instructions, compaction loss, delegation/ABD failures, agent 'flying' windows, maximizing steering value, reducing steering delta, or packaging lessons from a Codex/Claude/Gemini session. This skill is intentionally judgment-oriented: it uses scripts only to locate candidate windows and evidence, then requires contrastive audit cards, counterexamples, and outcome checks before turning observations into advice."
---

# Agent Steering Audit

Use this skill to audit a long-running agent session without pretending the
semantic work can be fully automated.

The goal is not to build a system or a score. The goal is to preserve the value
of human steering by finding:

- what the human actually tried to steer;
- what object should have stayed live;
- where agent output was useful but steering burden stayed high;
- where a small steering act unlocked real execution;
- which prompting primitives survived counterexamples.

## Non-Goals

Do not turn this audit into:

- a global agent-quality ranking;
- a numeric steering score;
- a claim that classifications are ground truth;
- an automated closure detector;
- a replacement for reading representative windows;
- a tool that treats useful output as proof that steering burden was low.

## Core Stance

- Treat scripts as locators, not judges.
- Treat agent final messages as evidence pointers, not closure.
- Separate evidence from inference.
- Prefer contrastive windows over hand-picked anecdotes.
- Do not promote a primitive unless it has at least one counterexample.
- Mark causal claims as provisional unless they are backed by contrastive
  examples and later evidence.
- Keep the user's stated goal in view: maximize steering value, not create an
  automagical evaluator.

## When You Start

1. Identify the session log or corpus.
2. Make a local work area under `tmp/workstreams/`.
3. If the session is large, use the bundled scripts before reading raw logs.
4. Produce artifacts on disk. Return only the read order and key conclusions.

If the user asks for a broad autonomous audit, define a goal up front and work
in tranches. Avoid returning after the first plausible synthesis.

## Mechanical Helpers

Bundled scripts live in `scripts/`.

Set the skill path once before running helper commands:

```bash
STEERING_AUDIT_SKILL_DIR=${STEERING_AUDIT_SKILL_DIR:-/home/tnunamak/code/dotfiles/ai/skills/local/agent-steering-audit}
```

If the skill is installed somewhere else, set `STEERING_AUDIT_SKILL_DIR` to that
directory.

Build a user-message corpus:

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/build-user-message-corpus.py \
  --session /path/to/session.jsonl \
  --out tmp/workstreams/agent-steering-audit-user-message-corpus.txt \
  --stats tmp/workstreams/agent-steering-audit-user-message-corpus.stats.json
```

Build a corpus with bounded agent context:

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/build-user-message-corpus.py \
  --session /path/to/session.jsonl \
  --include-agent-context \
  --out tmp/workstreams/agent-steering-audit-user-agent-context-corpus.txt \
  --stats tmp/workstreams/agent-steering-audit-user-agent-context-corpus.stats.json
```

Extract primitive/window candidates:

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/steering_spikes.py \
  --session /path/to/session.jsonl \
  > tmp/workstreams/agent-steering-audit-spikes.json
```

Dump a candidate window:

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/steering_spikes.py \
  --session /path/to/session.jsonl \
  --dump-window 2026-04-18T18:00:00Z 2026-04-19T00:00:00Z \
  > tmp/workstreams/window-dump-2026-04-18T18Z.md
```

Select contrastive windows:

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/select_steering_windows.py \
  --spikes tmp/workstreams/agent-steering-audit-spikes.json \
  --target 24 \
  > tmp/workstreams/agent-steering-audit-window-manifest.md
```

## Audit Workflow

### 1. Build The Artifact Map

Create an index file with:

- corpus/session facts;
- read order;
- temporary tools used;
- current best understanding;
- caveats and residual risks.

Use `references/artifact-read-order.md` as the structure.
Use `references/runbook.md` when you need a concise end-to-end command and
artifact sequence.

### 2. Run Candidate Extraction

Use the scripts to find:

- repeated steering primitives;
- high-output windows;
- high-friction windows;
- coordination-pressure windows;
- stop-condition repair windows;
- dispatch/noisy-resolution candidates.

Do not trust counts as semantic truth. Use them to choose what to read.

### 3. Write Contrastive Audit Cards

For each selected window, write a card using
`references/audit-card-template.md`.

Every card should name:

- target strand/object;
- phase label;
- user steering act;
- agent claimed operating mode;
- actual next actions;
- evidence outside final messages where available;
- later repair or acceptance;
- classification;
- reusable primitive or counterexample.

Prefer a small labeled set over a giant summary. Include clean windows, noisy
windows, and controls.

For ambiguous cards, record the runner-up classification and why it lost. For a
high-value audit, double-label a few windows or have a sidecar reviewer critique
the cards.

### 4. Red-Team The Synthesis

Before treating a finding as advice, ask:

- Is this causal claim stronger than the evidence?
- Are regex primitives false-positive heavy?
- Is correction density just task difficulty?
- Did we verify any outcomes outside agent final messages?
- Did we sample clean dispatch turns, not only noisy ones?
- Did we classify "proceed" as acceptance, impatience, baton-pass, or repair?

Use cautious causal language. Prefer `associated with`, `followed by`, or
`plausibly contributed to` unless the evidence supports `caused`.

### 5. Verify A Small Outcome Sample

For 5-10 resolution-tagged claims, verify what can be checked:

- commits exist;
- files changed;
- tests or generated artifacts exist;
- live timelines or screenshots are available;
- later user repair contradicts the claim.

If live credentials or owner auth are unavailable, say so.

If fewer than five claims can be verified outside agent final messages, downgrade
the rollup to exploratory and avoid durable prompting recommendations.

### 6. Produce The Rollup

The rollup should answer:

- What labels appeared across the calibration set?
- Which primitives survived contrast?
- Which hypotheses became less plausible?
- What should be measured next?
- How do we know whether the audit is going in the right direction?

Use `references/primitive-rubric.md` and
`references/repeatability-rubric.md`.

Each substantive conclusion should tag what is observed, what is inferred, and
what remains a judgment call.

## Useful Classifications

Use these as working labels, not fixed taxonomy:

- `clean/mostly-clean flying`
- `high-output/high-friction`
- `mixed`
- `stop-condition repair`
- `coordination leak`
- `live-evidence firefight`
- `low-signal/control`

## Surviving Primitive Families

These were useful in the first PDPP audit, but must be retested elsewhere:

- stop rule / human-in-loop boundary;
- object continuity / state ledger;
- expected-state or live-evidence reconciliation;
- confidence + evidence + scope;
- delegation authority / worker contract.

For concrete PDPP examples, see `references/teaching-examples.md`.

## Output Shape

Write artifacts to `tmp/workstreams/` unless the user asks for a durable tracked
artifact.

Recommended final response:

- path to the index;
- path to the rollup;
- 3-6 strongest conclusions;
- what is mechanical, semi-mechanical, and judgment-heavy;
- what should happen next.

Do not paste long logs or full corpora into chat.
