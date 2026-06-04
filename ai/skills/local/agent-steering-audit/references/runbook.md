# Agent Steering Audit Runbook

This runbook is intentionally not a one-button script. The mechanical steps
create locators. The audit value comes from the manual gates.

## Inputs

- A session JSONL path.
- A work directory, usually `tmp/workstreams/`.
- The user's audit question, for example:
  - "Where did my steering stop affecting behavior?"
  - "Find delegation leaks."
  - "Compare high-output windows with actual steering burden."

Set the session path explicitly before running commands:

```bash
STEERING_AUDIT_SKILL_DIR=${STEERING_AUDIT_SKILL_DIR:-/home/tnunamak/code/dotfiles/ai/skills/local/agent-steering-audit}
SESSION=/absolute/path/to/session.jsonl
test -f "$SESSION"
```

## Step 1: Corpus

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/build-user-message-corpus.py \
  --session "$SESSION" \
  --include-agent-context \
  --out tmp/workstreams/agent-steering-audit-user-agent-context-corpus.txt \
  --stats tmp/workstreams/agent-steering-audit-user-agent-context-corpus.stats.json
```

Manual gate:

- Confirm the corpus uses actual user messages, not injected role-user runtime
  artifacts.
- Tag pasted reports or external evidence separately from direct steering.

## Step 2: Candidate Extraction

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/steering_spikes.py \
  --session "$SESSION" \
  > tmp/workstreams/agent-steering-audit-spikes.json
```

Manual gate:

- Treat primitive counts as locators.
- Look for false positives before trusting any count.

## Step 3: Window Manifest

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/select_steering_windows.py \
  --spikes tmp/workstreams/agent-steering-audit-spikes.json \
  --target 24 \
  > tmp/workstreams/agent-steering-audit-window-manifest.md
```

Manual gate:

- Check that the selected set includes contrast classes and controls.
- Add or replace windows if the user's question needs a specific strand.

## Step 4: Window Dumps

```bash
python3 "$STEERING_AUDIT_SKILL_DIR"/scripts/steering_spikes.py \
  --session "$SESSION" \
  --dump-window START END \
  > tmp/workstreams/window-dump-START.md
```

Manual gate:

- Do not read dumps as episodes by default.
- Identify the object that should have stayed live.

## Step 5: Audit Cards

Use `audit-card-template.md`.

Manual gate:

- Name the live object.
- Classify the window.
- Record the runner-up classification when ambiguous.
- Mark observed facts, inferences, and judgment calls separately.
- Include one primitive or counterexample.
- Mark what evidence is missing.

## Step 6: Outcome Verification

For selected resolution claims:

```bash
git show --stat --oneline COMMIT
git log --since=... --until=... --oneline --all
```

If a runtime tool exists, query timelines or logs. If owner auth is missing,
record that as a limit rather than inferring success.

Manual gate:

- Separate reported outcome, repo evidence, runtime evidence, human acceptance,
  and residual risk.
- If fewer than five claims can be verified outside final messages, mark the
  rollup exploratory and avoid durable prompting advice.

## Step 7: Rollup

Produce:

- classification counts;
- surviving primitives;
- weakened hypotheses;
- next controls;
- answer to "are we going in the right direction?"

Manual gate:

- If the rollup contains a recommendation, it needs a counterexample.
- If it contains a causal claim, weaken or test it.
- Prefer "associated with", "followed by", or "plausibly contributed to" unless
  the evidence can support "caused".
