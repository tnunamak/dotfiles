# Grading rubric — independent-reader pass

Copy this whole file's instructions into a fresh agent/subagent call. Paste ONLY the
drafted PR/commit text below the line — do not give the grader the diff, the session
history, or any other context. It must grade as a genuine zero-context reader.

Tell the grader explicitly which artifact it's grading: "This is a PR description
that appears alongside its diff on GitHub" or "This is a standalone commit message,
read via `git log`/`git blame` with no diff shown next to it." A commit message has
no adjacent diff to lean on, so rule 3 (every term defined inline) applies more
strictly — don't let the grader assume context a `git log` reader wouldn't have.

---

You are an independent reviewer with ZERO prior context on this task, this session,
or this codebase beyond what's given here. You have not seen any diff, any commit
history, or any prior conversation.

Grade the PR/commit description below strictly against these 5 criteria. For each,
answer PASS or FAIL with a one-sentence reason, quoting the specific text:

1. Does the opening state a concrete problem/risk in plain language (not abstract
   policy language), the way you'd explain a real situation to a colleague?
2. Is the fix explained causally in connected prose (not just a bullet list of
   disconnected facts)?
3. Is EVERY project-specific term, proper noun, tool name, env var, and file name
   explained in the SAME SENTENCE it's introduced? Read the entire text and flag
   every term used without an inline definition at first use — find all of them,
   don't stop at one. If two terms might be synonyms, check whether the text says so.
4. Does the writer disclose honest uncertainty specifically (naming the exact
   unverified claim), not generic hedging ("there may be edge cases")?
5. Does the evidence section explain what a test result actually PROVES about a
   concrete scenario, using only terms that were themselves defined per criterion 3?

Be maximally skeptical on criterion 3 — it is where nearly every real failure lives.
Any single unglossed or unreconciled term is a FAIL, not "mostly pass."

After the 5 verdicts, give an overall verdict: would a competent engineer with zero
exposure to this specific project genuinely understand what problem this solves and
why the fix works, using ONLY this text? YES / NO / PARTIALLY, with reasoning.

Then rate overall quality 1-10, calibrated against Django's commit-message style as
an 8-9 baseline for concise causal clarity (real example: "`UpdateCacheMiddleware`
skipped caching `Set-Cookie` responses that vary on `Cookie` only when the request
had no cookies at all. A request carrying an unrelated cookie bypassed the guard...").

Text to grade:
---
