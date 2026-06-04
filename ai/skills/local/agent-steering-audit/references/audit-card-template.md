# Audit Card Template

Use one card per candidate window or strand.

```markdown
## [Window Or Strand Name]

Window: `[start] -> [end]`

Classification: [clean/mostly-clean flying | high-output/high-friction | mixed | stop-condition repair | coordination leak | live-evidence firefight | low-signal/control]

Runner-up classification:

- If classification is ambiguous, name the alternate label and why it lost.

Phase label:

- [implementation | live validation | standards/design | merge gate | delegation management | prose/spec cleanup | other]

Target object:

- What object should have stayed live? Examples: worker lane, OpenSpec change,
  UI target state, acceptance gate, live run, source connection, worker report,
  active docket item, stop rule.

User steering act:

- Quote or paraphrase the steering that matters.

Agent uptake:

- What did the agent claim to do?
- Did it change the operating mode, or only acknowledge the words?

Evidence:

- Direct session evidence.
- Repo evidence if checked.
- Runtime/live/user-visible evidence if available.

Observed / inferred / judgment:

- Observed:
- Inferred:
- Judgment call:

Later repair or acceptance:

- Did the user accept, continue, correct, paste contradictory evidence, or ask
  for a different framing?

Primitive or counterexample:

- Candidate reusable primitive.
- Counterexample or failure mode that prevents overgeneralization.

Residual uncertainty:

- What would need another check before calling this true?
```

## Classification Notes

- Use `clean/mostly-clean flying` only when output is high and steering burden
  is low after setup.
- Use `high-output/high-friction` when the agent shipped useful work but the
  user repeatedly repaired scope, evidence, priority, or operating mode.
- Use `stop-condition repair` when the main steering act repaired premature
  return, false blockedness, or the human-in-loop boundary.
- Use `coordination leak` when workers, reports, branches, lanes, or active
  docket state failed to stay live.
- Use `live-evidence firefight` when external platform/UI/run evidence changed
  the acceptance target.
- Use `mixed` when no single class dominates.

For high-leverage cards, ask a second reviewer or subagent to classify the same
window independently. Preserve disagreements instead of smoothing them away.
