# "Why is there so much red on data-connect PRs?" — the answer

You asked this at 19:07 on 2026-09-10 and never got an answer before the crash.
Verified directly against GitHub on 2026-09-10 ~20:40.

## Short version

6 of 9 open PRs are red, but there are only **three** root causes, and at least
two of them are **CI-infrastructure bugs, not defects in your PRs**. The red is
mostly not telling you what it looks like it's telling you.

| PR | failing check(s) | root cause |
|---|---|---|
| 97 | mutate changed production files (client) | **cause A** — mutation gate self-fails on no mutants |
| 57 | mutate changed production files (reference-implementation) | **cause A** |
| 96 | reference-implementation gate, test reference implementation | cause B — Node 24 migration (expected; that IS the PR) |
| 56 | reference-implementation gate, test reference implementation | cause B |
| 94 | Check data-connectors' recorded pin | cause C — connector pin drift |
| 64 | Check data-connectors' recorded pin | cause C |
| 99, 95, 59 | — | green |

## Cause A — the mutation gate fails when there is nothing to mutate (CI bug)

This is the most misleading red. On PR #97 ("repoint human-facing links away from
the archived vana-com org" — a **docs-only** change), run 34539894760 failed with:

```
Instrumented 1 source file(s) with 0 mutant(s)
receipt ... cohort=client killed=0 survived=0 inconclusive=0 valid_denominator=0 stryker_exit=0
  - no mutant trials were recorded, so this attempt produced no evidence
This step fails so the absence of evidence is visible without opening the artifact.
##[error]Process completed with exit code 1.
```

So: Stryker ran, found **0 mutants** (nothing meaningful to mutate), and the
workflow deliberately **fails on absence of evidence**. Note the contradiction in
the workflow's own code — an earlier step says:

```
if [[ "${APPLICABILITY}" != "applicable" ]]; then
  echo "No production source in this cohort changed in this revision, so no mutation"
  echo "evidence exists for it. This is not a pass and not a failure."
  exit 0
fi
```

…but `APPLICABILITY` was computed as `applicable` for a docs-only PR, so that
escape hatch never fired. The gate has two notions of "nothing to do" and they
disagree: the applicability pre-check says "not applicable → neutral pass", while
the receipt check says "0 mutants → fail". **The applicability detector is
over-inclusive** (it flagged a docs PR as touching production client source).

There is also an upstream trigger for this: the same run logged

```
[resolve-connectors] ERROR: Bundled connectors drift detected. Missing: <~80 files>
  ... chatgpt-pdpp, github-pdpp, heb, instagram, linkedin, oura, shopify,
      spotify, wholefoods, youtube ... | mismatched: (none)
```

Every bundled connector asset is reported **missing** (not mismatched). That is the
signature of a resolve/vendor step that didn't populate, not of 80 individually
deleted files — and it is very likely why instrumentation found nothing to mutate.
This connects to the vendoring/unvendoring question you raised on PR #98
("didn't we decide not to do vendoring?") and to today's `unvendor-0910` and
`revendor-89-0910` lanes.

**Fix direction (needs your call):** make the mutation gate neutral-pass when
`valid_denominator == 0` AND the diff touches no production source, OR fix the
applicability detector so docs-only diffs resolve to `not applicable`. Do NOT
simply delete the fail-on-no-evidence behavior — it exists on purpose to stop
silent zero-coverage passes, and that intent is sound.

## Cause B — reference-implementation suite (#96, #56)

#96 IS the Node 22→24 toolchain migration, so a failing RI suite there is the
expected signal of real migration work, not rot. #56 is a draft adding
provenance/CIMD oracles. These two reds are "work in progress", i.e. honest.
Today's `node24-0910` and `b2-main-ci-0910` lanes were on this.

## Cause C — "Check data-connectors' recorded pin" (#94, #64)

Both fail the same cross-repo pin check. You already had `pinfix-0910` and
`pin-normalize-0910` lanes on exactly this today, and one of your own session
prompts called it URGENT. This is a single cross-repo pin-consistency fix that
would clear two PRs at once.

## Why your mental model diverged

You said "i thought you were getting all reds fixed". The reds were being worked —
there were lanes for cause B and cause C running today. What nobody surfaced is
that **cause A is a CI bug that no amount of PR-side work will fix**, so those two
PRs would have stayed red no matter how many fix lanes ran. That is the gap
between what you were seeing and what you were told.

## Recommended order

1. **Cause C** (pin check) — one fix, clears #94 + #64. Lanes already exist.
2. **Cause A** (mutation gate) — one workflow fix, clears #97 + #57, and stops a
   whole class of future false reds. Highest leverage per unit of work.
3. **Cause B** — genuine in-progress work; leave red until the underlying
   migration/oracle work lands.

## Confidence

- Cause A: **high** — read the failing run log directly, quoted above.
- Cause C: **high** — check name identical on both PRs.
- Cause B: **medium-high** — inferred from PR intent + check names; I did not read
  those two run logs line by line.
- The connectors-drift → 0-mutants causal link is **inferred, not proven**; both
  appear in the same run but I did not isolate the dependency.
