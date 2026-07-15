# Correctness by Construction: Primary Sources

Canonical citations for "constrain the state space" / "make illegal states unrepresentable" code-quality theory.

---

## 1. "Parse, Don't Validate" — Alexis King (2019)

**Source:** Blog post, lexi-lambda.github.io  
**Published:** November 5, 2019  
**URL:** https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/

**Core Thesis (Direct Quote):**

> The difference between validation and parsing lies almost entirely in how information is preserved.
>
> `validateNonEmpty` always returns `()`, the type that contains no information, but `parseNonEmpty` returns `NonEmpty a`, a refinement of the input type that preserves the knowledge gained in the type system. Both of these functions check the same thing, but `parseNonEmpty` gives the caller access to the information it learned, while `validateNonEmpty` just throws it away.

**Key Principle (Direct Quote):**

> Avoid denormalized representations of data, *especially* if it's mutable. Duplicating the same data in multiple places introduces a trivially representable illegal state: the places getting out of sync. Strive for a single source of truth.

**Reliability:** PRIMARY — direct access to blog post; author is Alexis King (Haskell / functional programming authority); widely cited in programming communities.

**Note:** King cites Yaron Minsky's "making illegal states unrepresentable" principle explicitly in this work, bridging to source #2 below.

---

## 2. "Effective ML" — Yaron Minsky / Jane Street (2010)

**Source:** Blog post, Jane Street Blog  
**Published:** April 22, 2010  
**Author:** Yaron Minsky (OCaml lead at Jane Street)  
**URL:** https://blog.janestreet.com/effective-ml/

**Core Thesis (Direct Quote):**

> The lecture I gave was in part inspired by a book I read years ago called *Effective Java*, by Josh Bloch. The basic idea is to take some universal principles of good programming and apply them to ML.

**Key Principles (Direct Bullet List):**

- **Make illegal states unrepresentable** (appears as bullet point, fundamental to the list)
- Favor readers over writers
- Create uniform interfaces
- Code for exhaustiveness
- Open few modules
- Make common errors obvious
- Avoid boilerplate
- Avoid complex type-hackery
- Don't be puritanical about purity

**Reliability:** PRIMARY — direct access to Jane Street's official blog; Yaron Minsky is OCaml language lead and principal architect of Real World OCaml. The "make illegal states unrepresentable" principle is presented as a core design guideline for ML programming (2010, pre-Haskell blogsphere dominance).

**Attribution Note:** While the phrase is presented as a principle in Minsky's effective ML lecture (given at Northeastern and Harvard), this appears to be synthesized from functional programming best practices rather than a direct quote from an earlier published source. The principle has become canonical through Minsky's promotion of it and its adoption into functional programming pedagogy.

---

## 3. "Purely Functional Data Structures" — Chris Okasaki (1996 thesis, 1998 book)

**Source:** PhD Thesis (1996), Published as book by Cambridge University Press (1998)  
**Author:** Chris Okasaki  
**Institution:** Carnegie Mellon University  
**Thesis ID:** CMU-CS-96-177  
**URLs:**
- Thesis (PDF): https://www.cs.cmu.edu/~rwh/students/okasaki.pdf
- Book: ISBN 9780521631242, Cambridge University Press 1998

**Thesis Abstract (Direct Quote):**

> Although some data structures designed for imperative languages such as C can be quite easily adapted to a functional setting, most cannot, usually because they depend in crucial ways on assignments, which are disallowed, or at least discouraged, in functional languages. To address this imbalance, we describe several techniques for designing functional data structures, and numerous original data structures based on these techniques, including multiple variations of lists, queues, double-ended queues, and heaps, many supporting more exotic features such as random access or efficient catenation.
>
> In addition, we expose the fundamental role of lazy evaluation in amortized functional data structures. Traditional methods of amortization break down when old versions of a data structure, not just the most recent, are available for further processing. This property is known as persistence, and is taken for granted in functional languages. On the surface, persistence and amortization appear to be incompatible, but we show how lazy evaluation can be used to resolve this conflict, yielding amortized data structures that are efficient even when used persistently.

**Key Contribution:**

The thesis establishes that **immutable (persistent) data structures can achieve amortized O(1) and O(log n) operations without mutation**, via lazy evaluation. This provides the foundation for "correctness by construction" through immutability — invalid states cannot be reached because old versions of data cannot be mutated.

**Reliability:** PRIMARY — directly fetched from CMU archive; peer-reviewed PhD thesis (committee: Peter Lee, Robert Harper, Daniel Sleator, Robert Tarjan). Foundational work in functional data structures and a cornerstone of modern type-system design patterns.

---

## 4. "Data-Oriented Design" — Mike Acton (CppCon 2014)

**Source:** Conference talk (video + slide deck)  
**Speaker:** Mike Acton (Insomniac Games)  
**Conference:** CppCon 2014  
**URL (Video):** https://www.youtube.com/watch?v=4xe0JmXHyUw

**Core Philosophy (Commonly Cited Principle):**

The exact quote "the purpose of all programs is to transform data" is widely attributed to Acton but is not directly accessible from the video transcript via public archive. The philosophy is stated as:

**The three pillars of Data-Oriented Design:**
1. Understand the data.
2. Understand the hardware.
3. Transform the data (the purpose of the program).

**Available References:**
- Talk title and description emphasize that "the purpose of all programs is to transform data, and the less time you spend on that purpose, the worse your program."
- The talk focuses on understanding data layout, cache behavior, and SIMD in relation to data structure design.
- Core principle: **correctness and performance both follow from designing around actual data transformation patterns, not abstract object hierarchies**.

**Reliability:** PRIMARY SOURCE PARTIALLY VERIFIED — Video exists and is publicly accessible; Acton's authorship is confirmed. Full verbatim transcript not immediately available (YouTube transcript services vary). The principle is widely cited in game-engine and systems-programming communities with consistent attribution.

**Gap:** The exact thesis quote would require transcript extraction from YouTube or published slide deck. A secondary source (published paper, blog, or interview) with the full quote would improve this entry.

---

## Summary

| Source | Verified | Quote Quality | Best For |
|--------|----------|---------------|----------|
| King, "Parse, Don't Validate" | ✅ FULL | Direct blog post | Practical type-system design patterns |
| Minsky, "Effective ML" | ✅ FULL | Direct blog + bullet list | Functional programming principles |
| Okasaki, "Purely Functional Data Structures" | ✅ FULL | Direct thesis PDF | Theoretical foundation (immutability + asymptotics) |
| Acton, "Data-Oriented Design" | ⚠️ PARTIAL | Video exists, transcript gap | Systems/game engine perspective |

**Next Steps for Complete Sourcing:**

1. **Acton source:** Obtain CppCon 2014 slide deck or published writeup to verify the exact "purpose of all programs" formulation.
2. **Minsky attribution:** The "make illegal states unrepresentable" phrase likely originates from earlier ML literature (Hindley-Milner type theory pedagogy) but is canonically presented by Minsky; original source of the phrase remains open.
3. **King source:** Excellent bridge citing both Minsky and functional-programming theory; recommended as synthesis source.

---

*Compiled: 2026-06-28*  
*Confidence: 3/4 sources fully verified with verbatim quotes; 1/4 (Acton) verified for existence with principle documented but quote gap.*
