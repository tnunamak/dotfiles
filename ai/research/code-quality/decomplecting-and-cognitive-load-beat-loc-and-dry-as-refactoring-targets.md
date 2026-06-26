---
title: "For behavior-preserving refactoring, decomplecting and reducing cognitive load per unit are the durable targets; minimizing LOC or maximizing DRY as ends produce shallow modules, indirection, and accidental coupling"
date: 2026-06-26
topic: code-quality
tags: [refactoring, complexity, cognitive-load, dry, abstraction, deep-modules, decomplecting, simplicity]
status: draft
sources: [hickey-simple-made-easy, ousterhout-aposd, zakirullin-cognitive-load, metz-wrong-abstraction, beck-change-easy, muratori-clean-code-perf, ousterhout-vs-martin]
---

## CLAIMS

- "Simple" (from *simplex*, one fold/braid) is definitionally distinct from "easy" (from *adjacent*, near/familiar). A construct can be easy (familiar) yet complex (interleaving concerns). A construct can be simple (un-braided) yet unfamiliar. These are orthogonal axes. [hickey-simple-made-easy]
- "Complecting" is the act of interleaving or braiding concerns that should be separate. The goal of refactoring is to *decomplect* — to pull apart braided concerns into separate, composable pieces. [hickey-simple-made-easy]
- Constructs that complect include: state + identity, objects (methods + state + identity), inheritance (types + hierarchy), ORM (objects + relational schema), variables (values + time). Simpler alternatives: values, pure functions, managed references, polymorphism via protocols/data. [hickey-simple-made-easy]
- Intertwining raises complexity combinatorially: when two concerns are braided, reasoning about either requires holding both simultaneously. [hickey-simple-made-easy]
- The greatest limitation in writing software is our ability to understand the systems we are creating. Complexity that exceeds what a team can hold in mind is the primary engineering failure mode. [ousterhout-aposd]
- A **deep module** has a simple interface hiding complex functionality (high benefit/cost ratio for the reader). A **shallow module** has an interface nearly as complex as its implementation — it hides little, adding coordination overhead without information hiding. [ousterhout-aposd]
- Splitting methods into many tiny methods to comply with length rules produces shallow modules: the caller must understand both the top-level method AND all its sub-methods to understand what was once a single chunk of logic. [ousterhout-aposd]
- Complexity is incremental: no single design decision makes a system complex; complexity accumulates one slightly-wrong choice at a time. This is why complexity is hard to prevent and hard to attribute. [ousterhout-aposd]
- "Classitis" — the pathological tendency to create too many small classes doing almost nothing — results in shallow modules and high coordination overhead; it is a recognized anti-pattern in Ousterhout's taxonomy. [ousterhout-aposd]
- Ousterhout explicitly disagrees with Martin's *Clean Code* on method length and comments; these chapters were added to the second edition directly to address the conflict. Short methods as a universal rule is the primary point of disagreement. [ousterhout-vs-martin]
- Working memory holds roughly four chunks at once. Cognitive load — the number of things a developer must hold in mind simultaneously — is the primary proximate cause of errors and slow understanding in a codebase. [zakirullin-cognitive-load]
- DRY overuse creates tight coupling between unrelated components: a change in one part can cause unintended consequences in other, semantically unrelated areas. The coupling cost is invisible at extraction time but accumulates as the abstraction is called from more places. [zakirullin-cognitive-load]
- Shallow modules (many small functions/classes) force the reader to track more entities and their interactions than deep modules. Jumping between shallow components is mentally exhausting; linear thinking is more natural. [zakirullin-cognitive-load]
- Named intermediate variables (capturing a boolean or sub-expression with a descriptive name) reduce cognitive load by converting a live computation the reader must evaluate into a declared fact the reader can accept. [zakirullin-cognitive-load]
- Premature abstraction (extracting shared code before the shape of variation is understood) produces parameterized abstractions that accumulate conditionals and special cases — becoming "scar tissue" with no clear ownership or semantics. [metz-wrong-abstraction]
- "Duplication is far cheaper than the wrong abstraction." The cost of duplication is visible and local; the cost of a wrong abstraction is hidden and grows with every new caller that special-cases it. [metz-wrong-abstraction]
- The correct recovery from a wrong abstraction: inline the abstraction back into every caller, strip what each caller doesn't use, then re-extract only if genuine shared structure re-emerges from the callers. [metz-wrong-abstraction]
- The canonical refactoring move sequence is: "for each desired change, make the change easy (warning: this may be hard), then make the easy change." Preparatory refactoring is legitimate engineering work, not waste, and is often harder than the feature itself. [beck-change-easy]
- Applying *Clean Code*'s "prefer polymorphism to switch/case" rule in a benchmark produced an immediate 1.5× runtime slowdown vs. a switch statement, before any further optimization. The total performance gap under optimization was substantially larger. This is a documented cost of shallow-method OOP style. [muratori-clean-code-perf]
- Making the implicit explicit (surfacing hidden assumptions, naming unnamed concepts) is a refactoring target in its own right, distinct from LOC reduction and distinct from DRY. It reduces the gap between what the code says and what a reader must infer. [hickey-simple-made-easy] [ousterhout-aposd]

## SOURCES

**hickey-simple-made-easy**
URL: https://www.infoq.com/presentations/Simple-Made-Easy/
Accessed: 2026-06-25
Quote: "The roots of 'simple' are 'sim' and 'plex', and means 'one twist'. The opposite, which would be complex, is 'multiple twists' or 'braided together'." / "The latin origin of 'easy' is the root of 'adjacent', which means 'to lie near'." / "'Complect' means to interleave, to entwine, to braid. Complect results in bad software." / "Intertwining raises complexity combinatorially."
Note: InfoQ page contains timestamped show-note paraphrases synchronized to the video, not a word-for-word transcript. Quotes above are from those show notes. No freely available verbatim transcript was found.

**ousterhout-aposd**
URL: https://web.stanford.edu/~ouster/cgi-bin/book.php
Accessed: 2026-06-25
Quote (from Pragmatic Engineer's direct book citation): "The greatest limitation in writing software is our ability to understand the systems we are creating."
Note: Book is paywalled. "Deep vs. shallow modules" and "classitis" claims are confirmed via multiple independent reviewer citations and Ousterhout's own book page. Second-edition extract PDF linked from the Stanford page at https://web.stanford.edu/~ouster/aposd2ndEdExtract.pdf.

**zakirullin-cognitive-load**
URL: https://github.com/zakirullin/cognitive-load
Accessed: 2026-06-25
Quote: "Cognitive load is how much a developer needs to think in order to complete a task." / "The average person can hold roughly four such chunks in working memory. Once the cognitive load reaches this threshold, it becomes much harder to understand things." / "When you strive to eliminate any repetition, you might end up creating tight coupling between unrelated components. As a result, changes in one part may have unintended consequences in other seemingly unrelated areas." / "Not only do we have to keep in mind each module's responsibilities, but also all their interactions. To understand the purpose of a shallow module, we first need to look at the functionality of all the related modules. Jumping between such shallow components is mentally exhausting, linear thinking is more natural to us humans."
Note: Verbatim from README. The "~4 chunks" figure links to a GitHub issue thread, not a peer-reviewed paper; the README uses "cognitive load" informally.

**metz-wrong-abstraction**
URL: https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction
Accessed: 2026-06-25
Quote: "duplication is far cheaper than the wrong abstraction" / "prefer duplication over the wrong abstraction" / "Don't get trapped by the sunk cost fallacy. If you find yourself passing parameters and adding conditional paths through shared code, the abstraction is wrong." / "Re-introduce duplication by inlining the abstracted code back into every caller."
Note: Verbatim from the article. Originally from her RailsConf 2014 talk "all the little things."

**beck-change-easy**
URL: https://twitter.com/KentBeck/status/250733358307500032
Accessed: 2026-06-25
Quote: "for each desired change, make the change easy (warning: this may be hard), then make the easy change"
Note: Posted 2012-09-25. This tweet is the canonical source; there is no prior book chapter or essay. The commonly cited paraphrase drops the opener and parenthetical.

**muratori-clean-code-perf**
URL: https://www.computerenhance.com/p/clean-code-horrible-performance
Accessed: 2026-06-25
Quote: "just that one change — writing the code the old fashioned way rather than the 'clean' code way — gave us an immediate 1.5x performance increase. That's a free 1.5x for not doing anything other than removing the extraneous stuff required to use C++ polymorphism."
Note: Published 2023-02-28. Critique targets specifically the OOP-polymorphism rules in *Clean Code*, not Martin's book as a whole.

**ousterhout-vs-martin**
URL: https://web.stanford.edu/~ouster/cgi-bin/book.php
Accessed: 2026-06-25
Quote: "I have added subsections in two chapters to compare the book's design philosophy with that of Robert Martin's *Clean Code* (we have significant differences of opinion on topics such as the length of methods and the role of comments)."
Note: From Ousterhout's own book page, describing the 2nd edition additions. No publicly available video of a live Ousterhout–Martin debate was found.

## SYNTHESIS

### The anti-goals and why they backfire

**LOC reduction as a target** produces the pathology Ousterhout names directly: shallow modules. Splitting a 40-line method into five 8-line methods to satisfy a length rule creates five new names, five new call-graph edges, five more things in working memory, and hides less complexity than the original. The reader must now understand all five plus their orchestration.

**DRY maximization as a target** produces the pathology Metz documents: wrong abstractions. An abstraction extracted before the variation space is understood accumulates parameters and conditionals as callers add special cases. The "abstraction" becomes a branching switch on caller intent. The code is shorter but much harder to reason about and much riskier to change. zakirullin is explicit: DRY overuse creates tight coupling between semantically unrelated components.

Both anti-goals optimize for the signal (line count, repetition count) rather than the cognitive cost to a reader. They are visible metrics that produce invisible harms.

### Operational priority order for a refactoring agent

1. **Decomplect first.** Find braided concerns — places where two distinct concepts share a single function, class, variable, or parameter. Pull them apart. A braided design cannot be made simple by any other means; all other improvements are cosmetic until the braid is undone. (Hickey)

2. **Reduce cognitive load per unit.** After decomplecting, ask: what must a reader hold in working memory to understand this piece? Named intermediate variables, early returns, and eliminating unnecessary parameters all reduce this count. Target ~4 chunks per function. (zakirullin)

3. **Make the implicit explicit.** Name unnamed concepts. Surface hidden preconditions in type signatures or assertions. Convert implicit temporal coupling into declared dependencies. This is a distinct improvement from decomplecting — a single-concern module can still be full of implicit knowledge. (Hickey, Ousterhout)

4. **Delete over abstract.** Before extracting a shared abstraction, ask: is the duplication actually similar? Could the shape of variation make this abstraction wrong in three months? If uncertain, leave the duplication. Inline wrong abstractions before re-extracting. (Metz)

5. **Extract only deep modules.** When you do extract, the extracted module must hide significant complexity behind a simple interface. A module whose interface is as complex as its body is not an improvement. (Ousterhout)

6. **Prepare the change before making the change.** Refactoring and feature work are separate commits. The preparatory refactor may be harder than the feature; that is still the right sequence. (Beck)

### The "simple vs easy" wedge

The Hickey distinction is operationally useful as a diagnostic: when a code pattern feels "clean" because it's familiar (ORM, object inheritance, tight loops with mutable state), that familiarity is evidence of *easiness*, not *simplicity*. The question to ask is not "does this look familiar?" but "how many concerns does this braid together?" A function that mutates state AND has side effects AND returns a value AND throws is easy to write and complex by this definition. Decomposing it is harder (unfamiliar patterns may feel wrong at first) but produces simpler, independently-reasonable pieces.
