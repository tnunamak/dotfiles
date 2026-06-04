# Primitive Rubric

A steering primitive is not a slogan. It is a compact intervention that changes
the agent's behavior around a live object.

## Promotion Criteria

Promote a phrase or method only when it has:

- at least two positive examples;
- at least one counterexample;
- a named live object;
- observable uptake;
- some later evidence, acceptance, or repair signal;
- a clear scope where it should not apply.

## Primitive Families

### Stop Rule / Human-In-Loop Boundary

Good shape:

`Stop only for a real human-in-loop decision. Name the decision; otherwise keep going and document provisional RI choices.`

Look for:

- premature returns;
- false blockedness;
- "why are you returning?";
- "what are you waiting for?";
- decisions the agent can make as owner;
- decisions the user must ratify.

Counterexamples:

- continuing through true standards decisions;
- arbitrary tranche-count stop rules;
- using "keep going" to avoid necessary uncertainty disclosure.

### Object Continuity / State Ledger

Good shape:

`State the live objects before work: state, evidence file/commit, owner gate, next action.`

Look for:

- worker lane state;
- report review state;
- branch/worktree status;
- OpenSpec closeout;
- active docket items;
- "tracking" without next action.

Counterexamples:

- wall-of-text status lists;
- "reviewed" meaning summary-read;
- worker reports living only in chat;
- stale closed items re-entering the backlog.

### Expected-State / Live-Evidence Reconciliation

Good shape:

`Reconcile this pasted state against the expected target; do not claim closure until they match or you name the gap.`

Look for:

- pasted UI state;
- live platform errors;
- run timelines;
- screenshots;
- external agent feedback;
- counts or status labels contradicting the claim.

Counterexamples:

- overfitting to one client;
- explaining around evidence instead of changing the acceptance target;
- treating accurate-but-slow behavior as SLVP.

### Confidence + Evidence + Scope

Good shape:

`Confidence for which object and scope? If below 95%, raise it with evidence; if above, state the residual risk.`

Look for:

- confidence downgrades;
- SLVP ideal questions;
- split confidence by subsystem;
- acceptance gates;
- false "closed" language.

Counterexamples:

- confidence detached from a plan object;
- confidence as a general motivational phrase;
- tranche closure framed as end-to-end closure.

### Delegation Authority / Worker Contract

Good shape:

`Worker contract: authority, scope, stop condition, report path, and owner merge gate.`

Look for:

- ABD reminders;
- "right-hand worker";
- read-only vs read/write confusion;
- Claude/tmux/session state;
- Codex doing expensive local work after claiming delegation.

Counterexamples:

- worker fragmentation;
- stale branches;
- hidden workers;
- Codex as message bus instead of owner/coordinator.
