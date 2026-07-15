# Books to source for the code-quality canon — for Tim

You offered to obtain books given a list. This is it, prioritized. The split is deliberate: most of the
canon is FREE online and already verified (see `sources-collected/`). Only the items in TIER 1 genuinely
need a book/purchase to get primary-source quotes we could NOT verify from the web. TIER 2 are
high-value-to-own but we already have enough verified material from them online. TIER 3 = nice-to-have.

Each entry: what it UNIQUELY contributes to the theory, and why a book (vs. the free source we already have).

---

## TIER 1 — ACTUALLY NEEDED (primary quotes we could not get free online)

1. **A Philosophy of Software Design — John Ousterhout** (2018, 2nd ed. 2021)
   - WHY CANONICAL: the single best modern source for the theory's core — "deep modules," complexity =
     dependencies + obscurity, design-for-the-reader, strategic vs tactical programming. It IS the spine
     of Invariants 5/6 and the Clean-Code tension.
   - WHY BUY: we verified the deep-modules + Clean-Code-debate material from his GitHub exchange, but the
     book is the authoritative, quotable primary text and the highest-leverage single purchase. If you
     buy ONE book, this is it.

2. **The Practice of Programming — Brian Kernighan & Rob Pike** (1999)
   - WHY CANONICAL: clarity over cleverness, simple data structures, "controlling complexity is the
     essence of programming," debugging discipline, small mechanisms. The Unix-lineage taste that anchors
     "boring > clever" and "data structures dominate."
   - WHY BUY: NOT freely available online; we have Pike's free "Notes on Programming in C" (the rules)
     and the famous Kernighan debugging quote via secondary sources, but the book's full argument is
     book-only. Genuinely needed for primary quotes.

3. **The Mythical Man-Month (incl. "No Silver Bullet") — Fred Brooks** (1975/1995 anniversary ed.)
   - WHY CANONICAL: the essence/accident distinction (our BEDROCK 3-0 pillar) and the four essential
     properties (complexity/conformity/changeability/invisibility).
   - WHY BUY: "No Silver Bullet" itself is FREE online (we verified it 3-0), so this is only needed if
     you want the full book's surrounding argument (conceptual integrity, the second-system effect). The
     anniversary edition is the one to get. MEDIUM need — the key essay is already free.

---

## TIER 2 — HIGH VALUE TO OWN, but we already have enough verified online (buy if you want the full text)

4. **Working Effectively with Legacy Code — Michael Feathers** (2004)
   - CONTRIBUTES: the discipline of SAFE behavior-preserving change (characterization tests, seams) —
     the operational backbone of R2 (behavior-preservation-as-gate). Nothing else covers "change legacy
     code without breaking it" as well. Book-only; worth owning for the agent-refactoring protocol.

5. **Refactoring — Martin Fowler** (2nd ed. 2018)
   - CONTRIBUTES: the catalog + the definition of refactoring as behavior-preserving transformation
     (anchors R2/R5). Widely excerpted online; book gives the full catalog. Own-if-convenient.

6. **Purely Functional Data Structures — Chris Okasaki** (1998)
   - CONTRIBUTES: the rigorous case that immutable/persistent structures can have good asymptotics —
     grounds Invariant 10 (constrain state space) beyond hand-waving. Thesis (1996) is FREE online and we
     verified it; the book is the polished version. LOW need (free thesis suffices).

7. **Extreme Programming Explained — Kent Beck** (2nd ed. 2004)
   - CONTRIBUTES: the 4 rules of simple design + "make the change easy, then make the easy change."
   - NOTE: the famous "make the change easy" aphorism's ORIGINAL venue is untraceable online (we flagged
     it as attributed-not-verified). Owning the book would let us pin the primary source. LOW-MEDIUM.

---

## TIER 3 — NICE TO HAVE (canon completeness / taste)

8. **The Elements of Programming Style — Kernighan & Plauger** (1978) — the proto-"clarity over cleverness"
   text; book-only, mostly superseded by The Practice of Programming. Skip unless completist.
9. **Beautiful Code — ed. Oram & Wilson** (2007) — expert case studies (tradeoffs, not laws); good
   counterweight to rule-based quality. Own-if-convenient.
10. **A Discipline of Programming — Dijkstra** (1976) — rigor/elegance; his free EWDs cover most of it.
11. **The Art of Computer Programming / Literate Programming — Knuth** — the literate-programming essay
    (1984) is FREE + verified; the books are reference, not needed for the theory.

---

## DO NOT NEED TO BUY — already FREE + verified online (in sources-collected/)
- Brooks "No Silver Bullet" (full text, verified 3-0)
- Hickey "Simple Made Easy" (transcript + talk, verified)
- Parnas 1972 "On the Criteria..." (paper, verified quote)
- Hughes "Why Functional Programming Matters" (paper, verified)
- Backus 1977 Turing lecture (verified)
- Pike "Notes on Programming in C" / rules (verified)
- Knuth "Literate Programming" 1984 essay (verified, DOI)
- Dijkstra "Go To Considered Harmful" 1968 + EWDs (verified/archival)
- Alexis King "Parse, Don't Validate" (blog, verified)
- Yaron Minsky "Effective ML / illegal states unrepresentable" (verified)
- Carmack "Functional Programming in C++" (article, 4 quotes verified) — BUT his event-queue/boring-code
  views are in QuakeCon TALKS (video), not a book; would need a transcript pass, not a purchase.
- ISO/IEC 25010 + CISQ/ISO 5055 (standards; abstracts verified — full standards are paywalled by ISO but
  the characteristic lists are confirmed and that's all the theory needs)

## RECOMMENDATION
If you buy only a few: **#1 Ousterhout (APoSD), #2 Kernighan & Pike (Practice of Programming), #4 Feathers
(Legacy Code).** Those three close the only real primary-source gaps and cover design + clarity + safe-change.
Everything else in the theory is already verified from free sources.
