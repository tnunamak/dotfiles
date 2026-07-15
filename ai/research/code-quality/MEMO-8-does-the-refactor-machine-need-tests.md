# Memo 8: does the autonomous refactor machine need tests to verify behavior-preservation — or is independent agent cross-check a sufficient oracle?

Neutral framing requested. The owner wants you to consider this independently, without being steered toward a
conclusion. Below is the situation, the two positions as they actually came up in conversation, the facts we
have, and the open question. Please reason from first principles; disagree with any of it.

## Context

We are building an autonomous machine that decomplects/refactors a codebase (the PDPP reference
implementation) while preserving behavior. Prior memos (6, 7) established: scrutiny proportional to residual
risk; a portfolio of tiers; a hard maker≠checker rule (a different model judges the change, the maker never
self-grades); and a falsification result showing most complexity mass lives in code that isn't cheaply
mechanizable. This memo is a narrower, more fundamental question that surfaced while running the machine by
hand: **what is the machine's oracle for "behavior was preserved"?**

## What the machine currently does

Each refactor is gated by: (1) the compiler (tsc = 0), (2) the EXISTING test suite for the touched code must
stay green, (3) an independent different-model checker (codex) reads the diff and rules behavior-preserving +
genuine-decomplect-not-relocation. In practice, gate (2) — existing tests — has been treated as the primary
behavior oracle. Consequence: the machine can only confidently touch code that already has a test directly
asserting that function's output. Where tests are thin or only cover the code path indirectly (an integration
test that runs through the function but doesn't assert its output), the machine skips — "no direct test, can't
prove preservation." A large fraction of the skips in our hand-runs were exactly this: not "the code is
dangerous," but "nothing directly pins this function's behavior."

## The facts about the test suite (measured, not assumed)

- 820 test files, 3,906 test cases, ~21,492 assertions (~5.5 assertions/case).
- Essentially NO mocking (0–2 files) — tests run against real code and a real Postgres instance.
- More test-code than source-code by line count.
- Some skipped tests exist (one file has 39 `.skip`s) — a known skip-mask risk; not yet audited whether those
  are legitimately environment-gated or silently-disabled coverage. We have previously shipped one real
  regression that was masked by a skipped/gated test.

So the suite is substantial and behavior-focused (not obvious slop), but coverage is uneven and the machine's
dependence on it creates the "no direct test → can't touch" bottleneck.

## The owner's challenge (the reason for this memo)

The owner, a senior engineer, pointed out: "As a senior engineer I don't always have lots of tests, and when I
refactor I'm usually not doing it based on tests — I'm doing it based on skill/understanding. I assumed the
machine wouldn't be dependent on tests to work well." And then: "Aren't the smart agents in the machine able to
notice the things tests would notice? They'll be wrong sometimes, but that can be corrected too, right?"

This reframes the design question. Two positions, stated as neutrally as we can:

### Position A — tests (or a test-like oracle) are the machine's necessary seatbelt
A human senior refactors on understanding and skips tests because their self-assessment of "I preserved
behavior" is reliable. An LLM agent's self-assessment is demonstrably NOT reliable in the same way — in our own
runs, a maker agent was confident a change was a clean decomplect and an independent model caught it was
actually a disguised relocation; another agent misread a function's complexity by an order of magnitude. So the
machine needs an EXTERNAL check because it lacks the trustworthy judgment that lets a human skip verification.
That external check need not be pre-existing tests specifically — it could be equivalence proof, or
differential execution (run old vs. new on real/generated inputs and diff outputs) — but SOME external oracle
is required; the agent's own "I understand this, it's fine" cannot be the gate. This is just the maker≠checker
principle applied to the oracle.

### Position B — independent agent cross-check IS a sufficient oracle; tests are a bonus, not a gate
Smart agents can notice what tests notice, and often MORE — a test only catches a bug if someone happened to
pick the triggering input, whereas an agent reading the logic can see "this changed `||` to `??`, which differs
when the value is 0" without needing an example. Agents will sometimes be wrong, but wrong-and-corrected is how
a good human team already works: someone makes a change, someone else reviews, misses get caught in a later
pass. If the machine has genuinely independent agents cross-checking each other (maker ≠ checker, and maybe
several checkers with different lenses), that cross-check REPLACES the test as the behavior oracle. Existing
tests become cheap bonus signal ("free extra confirmation when present"), not a hard requirement. This removes
the "no direct test → can't touch" bottleneck entirely and matches how experienced engineers actually work:
judgment first, independent review as the backstop, tests optional.

## The open question for you

Is Position B sound? Specifically:

1. **Is independent multi-agent cross-check a sufficient behavior-preservation oracle to refactor WITHOUT
   relying on pre-existing tests** — or does it merely relocate the trust problem (the checkers are the same
   kind of fallible reasoner as the maker, so a blind spot shared across models survives cross-check)?

2. **If agent-judgment is the primary oracle, what is the cheapest test-INDEPENDENT backstop for the cases it
   misses** — equivalence/AST proof for mechanical changes, differential execution (old-vs-new output diffing,
   with its own traps around side effects, nondeterminism, and input selection), property-based checks, or
   something else? And where is each sound vs. unsound?

3. **Where does "wrong but correctable" break down?** A wrong refactor caught in the next review is cheap; a
   wrong refactor to an auth/billing/persistence path that ships before anyone re-derives it is not. Does the
   correctability argument hold uniformly, or only for changes whose mistakes are cheap and locally reversible —
   implying scrutiny must still scale with the cost-of-being-wrong even in a test-free, cross-check-based design?

4. **Given the actual suite** (3,906 real, low-mock, real-DB tests, unevenly distributed, some skips): what is
   the RIGHT role for these tests in the machine — hard gate, bonus signal, or oracle-of-last-resort — and does
   the answer change by risk tier?

5. **The deepest version:** a human senior refactors safely on understanding alone. Is the gap between that and
   the machine (a) a temporary reliability gap that better/independent agents close, so Position B is the right
   target design; or (b) a structural fact about non-human reasoners that means SOME external oracle
   (test, proof, or differential run) is permanently required, so Position A is correct and the only question is
   which oracle is cheapest per risk tier?

We genuinely do not know which position is right and want your independent read. If the answer is "it depends,"
we want the axis it depends on, sharply stated.
