---
title: "A constitutional spec for coding agents: the canonical theory of code quality (phase 1 — theory, sourcing pass pending)"
date: 2026-06-28
topic: code-quality
tags: [code-quality, theory, canon, constitution, agents, hickey, ousterhout, brooks, parnas, carmack, gabriel, acton, paradigm-independent]
status: phase1-theory-rebalanced-pending-final-sourcing
sources: [brooks-nsb, hickey-sme, parnas-72, ousterhout-aposd, hughes-wfpm, backus-77, ousterhout-martin-debate, ray-2014-reanalysis, zakirullin-cognitive-load, metz-wrong-abstraction, ai-code-smells-corpus, dynamic-import-cycles-corpus, chatgpt-straw-theory, carmack-fp-cpp, king-2019-parse-dont-validate, minsky-effective-ml, okasaki-pfds, knuth-literate-programming, pike-notes-on-c, dijkstra-ewd, iso-25010, cisq-iso-5055, gabriel-worse-is-better, acton-dod, sqlite-testing, torvalds-good-taste, chatgpt-decenter]
source_session: unknown
---

<!--
This is the THEORY (phase 1 of 3: (1) theory [here], (2) make consumable [AGENTS.md callout + indexing
skill], (3) operationalize [metric + design gate]). It is NOT a metric. REBALANCED 2026-06-28 after an
ADVERSARIAL counter-research pass (wwowayedx) caught that the first draft was FP/Hickey-biased (the spine
was anchored to sources the requester named). The correction is "DECENTER WITHOUT DEMOTE": the SPINE is now
PARADIGM-INDEPENDENT (simplicity + verification — the value BOTH the FP camp [Hickey] and the anti-FP camp
[Gabriel "Worse Is Better"] make their top priority); Hickey stays a CENTRAL pillar (generalized to
"simplicity-through-decomplecting + explicit state", NOT narrowed to "FP/Lisp = universal quality"); the
pragmatic/systems canon (Gabriel, Acton/DOD, SQLite, Carmack-as-pragmatist, Torvalds, Pike, djb, Bellard)
joins as EQUALS. Written as a CONSTITUTIONAL SPEC — three layers (Invariants / Anti-goals / Operational
protocol) kept SEPARATE. Becomes CANONICAL-CODE-QUALITY-CANON.md once §7's remaining sourcing closes.
-->

# §0. NORTH STAR

> **High-quality code is verified behavior encoded in a structure that minimizes the independent
> concepts, states, effects, dependencies, and change-paths a competent maintainer must hold in mind to
> predict, operate, and safely modify the system.**
>
> Quality is NOT brevity, familiarity, pattern usage, or test count — those are proxies at best. Quality
> improves when a change PRESERVES BEHAVIOR while reducing incidental complexity, hidden state,
> entanglement, change amplification, and operational risk.
>
> FOR AGENTS: never optimize the proxy before verifying the defect. A smaller diff, lower LOC, fewer
> cycles, higher coverage, or more "clean" functions is NOT evidence of quality unless semantic risk and
> cognitive load actually went down.

## The objectivity claim (precise — defends against attack)
Code quality is not a mechanically-measurable scalar, but many core properties are **objectively
INSPECTABLE**: hidden state, entangled concerns, change amplification, shallow abstractions, implicit
dependencies, invalid representable states, and names that mispredict behavior can be identified and
argued from evidence. The root distinction (CONFIRMED 3-0 adversarial [hickey-sme]): **"simple" is
objective** (absence of interleaving/braiding — inspectable) vs **"easy" is relative** (nearness/
familiarity — taste). So "this is better" must be grounded in reduced entanglement, never in "this looks
like what I'd write." Deciding which concerns *should* be independent still involves domain judgment —
the inspection is objective; the boundary call is judged.

## The spine is PARADIGM-INDEPENDENT (the rebalance — read this before treating any pillar as FP-specific)
The durable core is **simplicity + verification**, NOT a paradigm. STRONG CONVERGENCE SIGNAL (CONFIRMED
3-0): two historically opposed camps BOTH make simplicity their #1 value while disagreeing about
everything paradigm-specific —
- **Hickey (FP/Lisp camp)**: "mutable state is... clearly the number one problem in systems" — simplicity
  via decomplecting + immutable values. [hickey]
- **Gabriel "Worse Is Better" (anti-"The Right Thing" / pragmatic-C camp)**: "Simplicity... is the most important
  consideration in a design," ranked ABOVE interface, correctness, consistency, completeness — and argues
  the pragmatic New-Jersey/Unix-C school "has better survival characteristics than the-right-thing,"
  explicitly mapping the elegance camp to Common Lisp/CLOS/Scheme. [gabriel-worse-is-better, 3-0]
When the FP school and the explicitly-anti-FP school agree on simplicity-as-top-value and disagree on
purity/immutability, **simplicity is the robust core and "FP/immutability" is the paradigm-flavored
artifact.** So: the spine is **verified behavior + decomplecting + explicit state/effects + deep modules +
locality + data fitness + verification culture** — NOT "functional programming is the essence of quality."

## DECENTER WITHOUT DEMOTE (how to hold Hickey + the pragmatists at once)
Hickey is a first-rank theorist AND language designer; Clojure genuinely EMBODIES quality principles
(immutable values, explicit state, code-as-data, composition, host pragmatism). He stays a CENTRAL pillar.
The error to avoid is letting Hickey/Clojure/FP SWALLOW the canon (inferring "all quality converges on
Lisp/FP" from Clojure's virtues). Generalize his contribution to *simplicity-through-decomplecting +
explicit state*; do not narrow it to *FP/Lisp = universal quality*. The canon holds Hickey AND SQLite AND
Carmack AND Torvalds AND Bellard AND Pike AND djb AND Ousterhout AND Parnas AND Acton AND Gabriel — without
contradiction, because they converge on simplicity + verification + explicit state and diverge only on
paradigm. [chatgpt-decenter]

## "Code-as-data" ≠ "Data-Oriented Design" (don't conflate — they sound adjacent, mean different things)
- **Code-as-data** (Lisp/Clojure): the program REPRESENTATION is manipulable data → macros/syntactic
  abstraction. About malleability of CODE.
- **Data-Oriented Design** (Acton): organize around RUNTIME data — memory layout, access patterns,
  hardware cost. About the shape of the runtime PROBLEM (Invariant 12 below).
Compatible but distinct; code-as-data does NOT refute DOD/pragmatism. Hold both.

## Quality has THREE LAYERS; aesthetics is downstream [chatgpt-straw-theory; grounded in ISO/IEC 25010:2011 + CISQ/ISO 5055:2021 — VERIFIED]
<!-- ISO/IEC 25010: 8 product-quality characteristics; MAINTAINABILITY sub-chars = modularity, reusability,
analysability, modifiability, testability. CISQ/ISO 5055: source-code structural quality on 4 factors —
reliability, security, performance-efficiency, maintainability (138 CWE-mapped weaknesses). Sources verified
in sources-collected/standards-and-confirmations.md (iso.org/standard/35733.html, it-cisq.org/standards). -->
EXTERNAL (correct/safe/reliable/performant under real conditions) → INTERNAL (humans+tools can preserve
behavior while changing it) → AESTHETIC (essential idea exposed, incidental machinery suppressed).
Aesthetic is downstream of the first two: **beautiful code that is wrong, untestable, unsafe, or fragile
is not high-quality code.**

---

# §1. INVARIANTS (what code quality IS — the bedrock principles)

1. **Correctness & operability floor.** External behavior is correct under intended conditions incl.
   edge/failure cases; failures are observable, diagnosable, recoverable, safe. This is the FLOOR, not an
   assumption.
2. **Minimize INCIDENTAL complexity, not all complexity** [brooks-nsb 3-0]. Some complexity is ESSENTIAL
   (inherent in the problem) and irreducible — abstracting it away abstracts away the essence (a defect).
   Target accidental complexity introduced by tools/representation/ceremony/coupling. Brooks's four
   irreducible essential properties: complexity, conformity, changeability, invisibility.
3. **Decomplect** [hickey-sme]. Complexity IS complecting — braiding things that should be independent.
   Separate: state⟂value, time⟂identity, policy⟂mechanism, domain-logic⟂I/O, parsing⟂execution,
   representation⟂meaning, and **unrelated reasons-for-change**. Composition (simple things side by side)
   is the path to robustness. **MODULARITY ≠ SIMPLICITY**: splitting into files/classes/services while
   still braided is NOT decomplecting (this is the "relocation-masquerading-as-abstraction" trap).
4. **Leverage per unit of COGNITIVE LOAD, not per line** [hickey-sme; zakirullin]. Working memory holds
   ~4 chunks; cognitive load is the proximate cause of error. Maximize domain meaning per fewest
   necessary CONCEPTS/STATES/EFFECTS/DEPENDENCIES/SPECIAL-CASES. Density is a virtue ONLY when it removes
   concepts — never when it hides control flow. (Sometimes the high-quality version is MORE lines: the
   boring, obvious one.)
5. **Information hiding & design-for-change** [parnas-72]. Decompose by hiding each design decision likely
   to change — NOT by processing steps/flowchart. A module is a "responsibility assignment," decoupled
   from runtime call structure; its interface reveals as little as possible. Modularize around what
   changes together / for the same reason → a change to a hidden decision is confined to one module.
6. **Deep modules** [ousterhout-aposd]. A small, stable interface hiding substantial implementation. A
   good unit replaces a large cognitive load (read the impl) with a small one (learn the interface).
   Subdivide only while functionality-hidden-per-interface stays HIGH. Shallow wrappers that rename/move
   one call ADD complexity.
7. **Local reasoning.** A unit is understandable from its name, signature, tests, and immediate deps —
   without simulating the whole program. No spooky action at a distance.
8. **Make state & effects EXPLICIT.** Time, mutation, I/O, randomness, concurrency, caching, global
   config are VISIBLE and controlled. Pure core, effects pushed to the edges. [carmack-fp-cpp, VERIFIED]:
   *"A large fraction of the flaws in software development are due to programmers not fully understanding
   all the possible states their code may execute in... Programming in a functional style makes the state
   presented to your code explicit, which makes it much easier to reason about."* (Carmack, "Functional
   Programming in C++", 2011.)
9. **Names are compressed invariants.** A name is a CLAIM about what kind of thing this is. High-quality
   names predict: what kind of thing; raw/parsed/validated/normalized/persisted/cached/derived/
   user-supplied; units, scope, lifetime; whether it can fail/be-absent/stale/partial; what invariant it
   asserts. **If the invariant a name encodes is false, incomplete, or too vague to guide maintenance,
   the name is a source of incidental complexity** — it creates hidden state in the reader's head.
10. **Constrain the STATE SPACE / correctness-by-construction** (generalized beyond FP). Make invalid
    states impossible where practical, invalid transitions explicit, invalid inputs rejected at
    boundaries. Techniques (FP is ONE among many): types, parsers ("parse don't validate" [king-2019,
    VERIFIED: parse at the boundary into a type that makes illegal states unrepresentable, vs validate
    which checks-then-discards-the-proof], "make illegal states unrepresentable" [minsky-effective-ml,
    VERIFIED]), schemas, state machines, capability boundaries, pure-core/impure-shell, explicit DI,
    DB constraints, idempotency keys, exhaustive pattern matching, runtime assertions at trust
    boundaries. Justify FP by REASONING/MODULARITY [hughes-wfpm: FP's advantage is modularity — HOFs +
    laziness as composition "glue"], NOT by defect-reduction (the FP-fewer-defects study does NOT survive
    reanalysis [ray-2014-reanalysis] — do not repeat that folklore).
11. **Contextual fitness.** Quality is relative to declared constraints: correctness, domain complexity,
    team skill, latency, security, compatibility, evolvability, operational risk. The invariants always
    apply but their WEIGHTS shift. Carmack-style hot-path code may choose explicit repetition over
    abstraction; a rules engine may choose verbose declarative tables; a security boundary may duplicate
    checks for defense-in-depth — all high quality if they reduce risk and cognitive load under the
    ACTUAL constraints. Don't over-refactor a one-off; don't under-optimize a hot path.
12. **Data fitness** (Data-Oriented Design — promoted from the adversarial pass; [acton-dod, gathered]).
    The program's job is often to TRANSFORM DATA; quality means understanding the actual data, its access
    patterns, and the hardware/runtime cost — not modeling an imaginary domain. Acton's critique directly
    targets OOP/world-model/code-first design, and GENERALIZES to any abstraction-first style — including
    FP — when the abstraction ignores real data shape, access patterns, and hardware/runtime cost:
    "code should be designed around a model of the world" is a TRAP (the OOP "Rocket
    class" / over-abstraction); "code is more important than data" is FALSE (code is ephemeral; data and
    its transformations are what performance and features hinge on). This is NOT anti-abstraction
    nihilism — it's a corrective: abstraction that ignores the real data shape adds incidental complexity
    AND cost. For hot paths and data-heavy systems, fit the code to the data, not the data to a pretty
    abstraction. (Distinct from code-as-data — see §0.5.)
13. **Verification culture** (promoted — the paragons' actual shared trait; [sqlite-testing, gathered]).
    The highest-quality real codebases are defined less by elegance than by RELENTLESS VERIFICATION —
    SQLite's ~600:1 test-to-code ratio + 100% MC/DC branch coverage + fuzzing + crash/boundary tests is
    the canonical example. Quality is not just structure; it is EVIDENCE that the structure behaves.
    Beautiful-but-unverified loses to boring-but-proven. (Operationalizes the §0 "verified behavior" floor.)

---

# §2. ANTI-GOALS (what quality is NOT — agents are biased toward these)

- **LOC minimization** as an end (rewards clever compression, hidden control flow, opaque abstractions).
- **DRY absolutism** — de-duplicate ONLY when duplicates change for the SAME reason. Forcing
  unrelated-but-similar code together complects independent reasons-for-change (worse than duplication).
  Wrong-abstraction recovery: inline back to callers, strip unused, re-extract only if real shared
  structure re-emerges [metz-wrong-abstraction].
- **Tiny-method / extraction theater** — functions extracted for size, not depth (produces SHALLOW,
  entangled methods harder to understand; "anything can be named" so size/One-Thing rules have no
  guardrail). The right grain is set by DEPTH, not size [ousterhout-martin-debate].
- **Shallow wrappers, synthetic/premature abstraction, OO-pattern ceremony** substituting for design
  judgment.
- **Metric chasing** — improving a proxy (LOC/cycles/coverage/"clean" count) without verifying the
  semantic defect went down.
- **Test-passing without behavior preservation** — passing tests by weakening/special-casing them, or
  reporting INTENT rather than the actual DIFF [ai-code-smells-corpus].
- **Familiarity dressed as quality** — "easy"/idiomatic-to-me ≠ "simple."

---

# §3. OPERATIONAL PROTOCOL (for AI coding/refactoring agents)

## Refactoring priority order (constrains the search path — do NOT just "improve quality")
1. **Decomplect first.** A braided design can't be made simple by any other means; all else is cosmetic
   until the braid is undone.
2. **Reduce cognitive load per unit** (name intermediate facts; cut concepts a reader must hold).
3. **Make the implicit explicit** (surface hidden state/effects/deps before moving anything).
4. **Delete over abstract** (the cheapest complexity reduction is removal).
5. **Extract ONLY deep modules** (never shallow wrappers; depth, not size, licenses extraction).
6. **Prepare the change before making it** (set up the seam, then make the change easy).

## Hard agent rules (the constitution — these prevent gaming, learned from our own history)
- **R1 — Verify the semantic defect BEFORE refactoring the metric.** A metric is a proxy. If the metric
  doesn't correspond to a real defect, fix the METRIC/ratchet, not the code. (Proven: the "6 cycles" that
  were dynamic-import-broken non-defects — the fix was the cycle RULE, not churning auth.js
  [dynamic-import-cycles-corpus].) Do NOT refactor a metric.
- **R2 — Behavior preservation is a GATE, not a hope.** A refactor is a quality improvement ONLY if
  externally observable behavior is intentionally preserved (or the change is explicitly specified).
  Structural improvement without semantic preservation is a REWRITE, not a refactor. The agent must
  state: what behavior is preserved, what tests/types support that, what is intentionally changed, what
  edge cases remain unverified. (Proven: a typed-migration chunk passed tsc + SQLite tests + no-lint-lie
  yet BROKE Postgres no-op suppression — only an independent backend-specific behavior gate caught it.)
- **R3 — The model that produced the work cannot be the sole judge of it.** Judge-ability tracks
  solve-ability (JudgeBench); the maker self-grading is the weakest verifier. Load-bearing verification =
  a DETERMINISTIC oracle (compiler, tests, real-backend run, cycle/boundary checks) + a DIFFERENT-MODEL
  reviewer for the judged axes. Never let a scalar self-grade be the only signal.
- **R4 — Prove the diff; don't narrate it.** Verify against the actual diff and real outputs, not the
  agent's summary of intent (agents emit plausible summaries that diverge from the diff
  [ai-code-smells-corpus]).
- **R5 — Distinguish decomplecting from relocation.** Before claiming an extraction is an abstraction,
  show the concept is now FIRST-CLASS: no internals left behind in the source, the new module doesn't
  import back into it, the interface is tight (not a bag of helpers), consumers use the facade not
  internals, and the concept contract explains WHY each member belongs together. Moving a blob behind a
  filename is not quality.

## Review evidence the agent must produce (per change)
- COMPLEXITY: before/after claim grounded in reduced entanglement/cognitive-load (not LOC).
- BEHAVIOR: preservation evidence (R2), incl. the right backend/integration gate where state is touched.
- METRIC SEMANTICS: any metric cited (R1) — does it correspond to a real defect here?
- TESTS: behavior + boundaries + regressions; nondeterminism made reproducible; tests not weakened.
- NEW ABSTRACTION: justified as a DEEP module (R5), or don't add it.

---

# §4. THE KEY TENSIONS (resolved)
1. Expressiveness vs readability → leverage-per-cognitive-load (Invariant 4). Compression that hides
   concepts/control-flow is a defect; compression that removes concepts is a virtue.
2. Aggressive extraction (Martin) vs locality/inlining (Carmack/Ousterhout) — a GENUINE expert
   disagreement [ousterhout-martin-debate]. Resolution: **right grain = DEPTH, not size.** Extract iff it
   creates a deep module; never to hit a size threshold (the 50-line rule is the most-resented,
   most-misapplied Clean-Code constraint in practice).
3. DRY vs decoupling → de-dup only same-reason-for-change (Anti-goals).
4. Clever vs boring → boring wins; locality + obviousness > cleverness.
5. FP purity vs pragmatism → pure core, effects at edges; use functional STYLE for explicit-state/
   modularity, NOT as dogma, NOT justified by defect-folklore. Carmack's actual position is the model
   [carmack, gathered]: functional purity is a CONTINUUM with real costs ("more copying"), valuable
   SITUATIONALLY "whenever convenient"; abandoning C++ for Lisp/Haskell is "irresponsible." The durable
   point under FP is "make state explicit" (Invariant 8), not the paradigm.
6. **Elegance/"the right thing" vs "worse-is-better"/ship-and-survive** (the tension the FP-centric draft
   MISSED) [gabriel-worse-is-better, 3-0]. Gabriel argues the pragmatic school (implementation-simplicity
   above interface/correctness/consistency/completeness; "good enough" that ships and spreads) often
   BEATS the elegant "right thing" in practice — Unix/C "spread like a virus" precisely because
   implementation simplicity made them portable. RESOLUTION: this is NOT license for sloppiness — it
   re-ranks WHICH simplicity wins. Prefer implementation-simplicity + ships + verifiable over an elegant
   design that's hard to build/maintain. "The right thing" can lose; pragmatic-simple-and-shipped is a
   real quality strategy, not a compromise of one. (Holds in tension with deep-modules/interface-quality:
   neither is absolute; weight by Invariant 11 contextual fitness.)

# §5. THE CANON (no single center — a paradigm-independent spine + a balanced roster)
There is NO single author at the center; the SPINE is the shared value (simplicity + verification +
explicit state), and the roster spans BOTH camps so no paradigm swallows it:
- **Philosophy of simplicity/complexity:** Brooks (essence/accident), Hickey (decomplecting; simple≠easy —
  central but generalized to simplicity+explicit-state, NOT "FP wins"), Ousterhout (deep modules — the most
  operationally useful, language-agnostic SPINE for design), Parnas (info hiding).
- **Pragmatic/systems (promoted to equals by the adversarial pass):** Gabriel (Worse-is-Better — the named
  case for pragmatic-simplicity over elegance), Acton (Data-Oriented Design — data fitness), Carmack
  (explicit-state, pragmatist-not-FP-purist), Kernighan/Pike (clarity, small mechanisms, "data dominates"),
  Torvalds ("good taste" — concrete, e.g. the linked-list null-removal, NOT philosophical), djb/Bellard/
  SQLite-Hipp (ruthless simplicity + verification culture, observed in real code).
- **Correctness/reasoning:** Hughes/Backus (FP for reasoning/modularity — a TACTIC, not the essence),
  King/Minsky (parse-don't-validate / illegal-states), Okasaki.
- **Safe change & exposition:** Feathers/Fowler/Beck (behavior-preserving change), Knuth (human-readable
  artifact), Dijkstra (rigor/elegance).

**Clean Code (Robert C. Martin): a source, not the center.** USE for naming, reader orientation, small
COHERENT units, test discipline. REJECT when it becomes mandatory size thresholds, extraction theater,
shallow abstractions, or OO-pattern substitution for design judgment — centering it produces "clean-code
theater" [ousterhout-martin-debate]; automated clean-code tools misfire (false positives whose "fixes"
DEGRADE quality).

**The decentering rule (§0.5 restated):** Hickey is decentered but NOT demoted — he remains a central
philosophical pillar; what's demoted is the *inference* that quality = FP/Lisp. Several widely cited
systems-code exemplars — SQLite, Bellard's systems artifacts, djb's software, Redis/antirez, the Go
lineage — are pragmatic/imperative rather than FP-purist; what they share is NOT functional purity but
simplicity, explicit state, tight mechanisms, and verification/operational discipline — which is exactly
the paradigm-independent spine.

# §6. MEASURABLE vs JUDGED (brief — operationalization is phase 3)
Very little is mechanically measurable; popular metrics are weak proxies; rigid thresholds backfire
[ray-2014-reanalysis, practitioner-complaint-study]. MECHANICAL (GUIDE, don't gate): cyclomatic/LOC,
cycles, dead code, duplication, type-escape counts — proxies; cognitive complexity (the real target) is
NOT captured by line/branch counts. JUDGED (model/human, GATE — anchored to §1): right concept boundary?
deep or shallow? does the name predict behavior? essential vs incidental complexity? decomplected or
relocated (R5)? Phase 3: metrics GUIDE, judged axes GATE.

# §7. CONFIDENCE & SOURCING STATUS (honesty — what's verified vs the few remaining gaps)
Two research passes (a pro-canon sweep + an ADVERSARIAL counter-pass wwowayedx) + a Haiku sourcing fan-out;
raw in sources-collected/ + RAW-deep-research-findings-*.md.
- BEDROCK (3-0 adversarial): Brooks essence/accident as canonical origin; Hickey simple=objective /
  easy=relative; **Gabriel "Worse Is Better" as the named primary case for pragmatic-simplicity over
  elegance** (the rebalance's spine); **Hickey is a philosopher/language-designer of quality, NOT
  established as a code-exemplar the way SQLite/djb/Bellard are** (the attempt to ground his code-rep in
  verification was REFUTED 0-3 — bias confirmed).
- VERIFIED with primary quotes: **Carmack FP-in-C++ explicit-state thesis** (Invariants 8/10 —
  sources-collected/carmack.md).
- GATHERED, NOT adversarially stress-tested (medium — the re-vote round got rate-limited; informs the
  rebalance but carries lower confidence; close via the ChatGPT/transcript pass): **Acton/DOD** (the 3
  "lies" + "transform data" thesis — Invariant 12), **Carmack broader code-style claims** (boring code,
  distrust of abstraction, "irresponsible" to abandon C++, purity-as-continuum-with-costs, event-queue/
  journaling — §4.5 — STILL OPEN, need transcript pass), **SQLite verification culture** (~600:1 test
  ratio, MC/DC — Invariant 13), **Torvalds good-taste**, **Pike data-dominates**.
- NOW VERIFIED with primary quotes (closed the prior [SOURCE-TODO]s): **Carmack** FP-in-C++ (Invariants
  8/10 — the explicit-state quote, sources-collected/carmack.md); **parse-don't-validate** (King 2019) +
  **illegal-states-unrepresentable** (Minsky) + **Okasaki** (Invariant 10); **Knuth** literate-programming
  (verbatim + DOI); **Pike** rules (measure-before-optimize, data-dominates); **Dijkstra** (Go-To, EWDs);
  **ISO/IEC 25010 + CISQ/ISO 5055** (the §0 three-layer / objective-dimensions backbone); and re-confirmed
  with quotes: **Parnas** info-hiding, **Ousterhout** deep-modules + the Clean-Code tension, **Hughes**
  FP-as-modularity, **Ray-2014** debunk.
- STILL OPEN (genuine gaps, NOT closable by web/book): **Carmack's event-queue/journaling example + his
  "boring code"/distrust-of-abstraction** are in QuakeCon TALKS (video) — need a transcript pass, not a
  purchase; **Acton data-oriented-design** exact "purpose of all programs is to transform data" quote is
  in his CppCon 2014 video. Lower priority (the FP-in-C++ quote already carries Invariant 8).
- BOOK-DEPENDENT (primary-quote confirmation pending Tim's purchase — see BOOK-LIST-FOR-TIM.md):
  **Ousterhout APoSD** (have the GitHub-debate quotes; the book is the authoritative primary), **Kernighan
  & Pike "Practice of Programming"** (book-only), **Beck** "make the change easy" (aphorism's original
  venue untraceable online), **Metz** primary.
- PROMOTION CRITERION: rename .phase1 → CANONICAL-CODE-QUALITY-CANON.md once (a) the 2 video items get a
  transcript pass OR are accepted as adequately-covered by the FP-in-C++ quote, and (b) Tier-1 books
  (Ousterhout, Kernighan&Pike, Feathers) are obtained and their quotes confirmed. The THEORY is not
  expected to change — only the citation strength.
- BOOK LIST: DELIVERED → BOOK-LIST-FOR-TIM.md (buy-3 essentials: Ousterhout APoSD, Kernighan&Pike, Feathers).

# §8. THE COMPRESSED FORM (what an agent loads every task)
Preserve behavior unless explicitly asked to change it. Verify behavior first. Reduce incidental
complexity (decomplect). Make state/effects explicit. Deep
modules, local reasoning, honest names. Fit code to the real data, not to a pretty abstraction. Prefer
simple-that-ships-and-is-proven over elegant-that's-hard. Reject shallow abstraction and clean-code
theater. Verify the metric semantically before acting on it. Prove the diff, don't narrate it. The maker
is not the judge. Simple (un-braided) is objective; easy (familiar) is not — optimize the former.
**No paradigm is the essence of quality — simplicity + verification + explicit state are, and they are
language-independent.**
