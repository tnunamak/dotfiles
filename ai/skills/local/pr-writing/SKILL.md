---
name: pr-writing
description: Write and gate PR descriptions and commit messages so a reader with zero session context can understand them. Use before opening a PR, writing a commit body, or drafting release/changelog prose, in any repo. Validated end-to-end against real PDP-Connect/pdpp diffs and cross-project research; a single draft plateaus around 7/10 on independent grading — the grade-then-revise loop in this skill is what closes the gap, not a longer prompt.
---

# PR and commit writing

The failure mode this fixes: PR descriptions read fine to the agent that wrote them
(full of accurate SHAs, gate names, verdicts, internal tool names) and are opaque to
anyone who wasn't in that session. The diff already shows *what* changed. The
description's only job is *why*, explained to someone who wasn't there — a future
teammate, a maintainer outside their specialty, another agent reviewing this one.

Root cause, confirmed against real repo history (PDP-Connect/pdpp): commit messages
drafted from a clean read of the diff are consistently good. PR bodies drafted at the
end of a long session are consistently bad, because by then the session's own
verification-pipeline vocabulary (verdicts, SHAs, gate names) has displaced the causal
explanation a reader actually needs. Research corpus behind these rules:
`~/code/dotfiles/ai/research/writing-craft/` and `~/code/dotfiles/ai/research/
information-design/` (curse of knowledge, Zinsser, the Linux-kernel/Django/Amazon-3M/
Chris-Beams convergence, and two 2026 studies quantifying agentic PR-description
misalignment).

## The five rules

1. **Open with one plain sentence stating the concrete risk or problem** — what could
   go wrong, and for whom — not a system property. "X could happen, causing Y" beats
   abstract policy language.
2. **Explain the fix causally, in prose.** The diff shows what changed; explain why it
   changes that way. Bullets are fine for genuinely parallel/independent items, never
   as a substitute for connected reasoning — bullets let a writer state conclusions
   without stating the logic that connects them (this is why Amazon and 3M
   independently banned bullet-point business writing).
3. **The Django rule** (the single highest-leverage rule; most failures are here): the
   moment you introduce a project-specific term, name, env var, tool, or file, explain
   what it DOES in the SAME SENTENCE. This covers everything, not just obvious
   jargon — proper nouns ("the reference implementation"), tool/gate names
   ("OpenSpec", "Ultracite", "CI"), env vars, and illustrative examples used to
   explain a category. If two terms might sound like synonyms, say explicitly whether
   they're the same thing. Never reuse a term a second time assuming the first
   definition landed.
4. **State uncertainty specifically, not generically.** "I have not traced every
   caller of X" beats "there may be edge cases." A diff-only read cannot support full
   confidence about runtime behavior in other callers — say so.
5. **Evidence proves a scenario, not a gate's status.** "This test deletes the
   connection mid-write and asserts zero rows land" beats "CI: pass". If a gate name
   appears, it needs rule 3's treatment too.

## The loop (do this, not a single draft)

Tested against two real diffs, three rounds each: a single draft against these five
rules plateaus around 7/10 on independent grading, and the specific gap moves each
time you patch the last one — the writer cannot fully see its own blind spots (this
matches the curse-of-knowledge finding: self-review is the *weakest* known fix, worse
than an independent reader). What converges is iteration:

1. Draft the PR/commit body against the five rules above.
2. Grade it — dispatch an independent pass with **zero context beyond the drafted
   text itself** (no diff, no session history) using `references/grading-rubric.md`.
   The grader must be a fresh agent/subagent call, not the same context that wrote
   the draft — a self-check by the writer is the failure mode this step exists to
   avoid.
3. If the grade is PARTIALLY or NO on the overall verdict, or any criterion FAILs:
   revise ONLY the flagged sentences. Do not regenerate the whole draft — targeted
   fixes converge; full rewrites reintroduce previously-fixed gaps at the same rate
   they fix new ones.
4. Regrade. Repeat up to 3 rounds total. Stop and ship at 3 rounds regardless of
   verdict — diminishing returns set in and a human reviewer closes the rest.

## When to skip the full loop

A one-line body (`Fixes #N`) is fine when the linked issue already carries full
context and the PR is small — real high-craft peer projects (Immich, Home Assistant)
do this from trusted contributors. Template compliance is not the bar; causal
reconstructability is. Don't force narrative onto a trivial change.

## Commit messages vs. PR bodies

Same five rules, same loop — a commit body has the identical audience problem (a
reader with zero session context). Two differences in practice, not in the rules:

- Draft the commit message from a clean read of the diff alone, close to when the fix
  is fresh, not at the end of a long session with pipeline bookkeeping loaded. This is
  already the stronger artifact when done this way — the risk is a long session
  polluting it, not the format itself.
- For a multi-commit PR, don't run the loop on every commit and the PR body
  separately if the PR body will restate the same causal story — grade the PR body
  (the artifact a reviewer actually reads first) and let individual commits stay
  terser if the PR body carries the full explanation.
- A standalone commit message (no PR, or a commit read via `git log`/`git blame`
  outside GitHub) has no diff visible next to it the way a GitHub PR body does —
  rule 3 has to work harder because there's no adjacent context to lean on. Tested:
  this pushes a commit body past typical length (~350 words to hit 7/10 on a
  moderately complex diff) to stay fully self-contained. That's expected, not a
  sign something's wrong — don't cut definitions to hit a shorter body.

## Not for code comments

This skill's rule 3 (define every term inline) is WRONG for comments — applied
literally it produces bloated, over-explained comments. Comments have a different
audience problem (repeated reading under time pressure, not one-time review) and a
different craft target (Ousterhout: comment what the code can't say about itself;
most code needs zero comments). Do not extend this skill's rules to comments without
separate testing — untested claim, not a verified one.
