---
title: "Google's style guides, Kernighan & Pike, and Ousterhout independently converge on the same rule: comments should explain why (or non-obvious what), not restate what the code already says, and Ousterhout gives the sharpest test — a comment at the same abstraction level as the code is useless"
date: 2026-08-14
topic: code-quality
tags: [comments, documentation, code-review, style-guides, ousterhout, kernighan-pike, google-style-guide, readability]
status: draft
sources: [google-docguide-best-practices, google-cpp-style, google-python-style, pep8-comments, go-code-review-comments, kernighan-pike-tpop, ousterhout-aposd-ch13]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

- Google's cross-language documentation guide states the primary purpose of inline comments is "to provide information that the code itself cannot contain, such as why the code is there." Method/API documentation (docstrings, Javadoc) should specify the contract — arguments, return values, gotchas, exceptions — and "does not usually explain why code behaves a particular way unless that's relevant to a developer's understanding of how to use the method"; why-explanations belong in inline comments, not API docs. [google-docguide-best-practices]
- Google's C++ style guide instructs: comments belong in "tricky, non-obvious, interesting, or important parts of your code." For function-level comments, if there is anything tricky about how a function does its job, the definition should have an explanatory comment — describing coding tricks used, an overview of steps, or "why you chose to implement the function in the way you did rather than using a viable alternative." [google-cpp-style]
- Google's C++ style guide explicitly warns against restating what a reader already knows: for constructors/destructors, "comments that just say something like 'destroys this object' are not useful" — the reader already knows what a destructor is for. If a destructor is trivial, skip the comment entirely rather than write a no-op one. [google-cpp-style]
- Google's Python style guide instructs engineers to "never describe the code" in comments and to "assume the person reading the code knows Python... better than you do" — i.e., comments should not explain language mechanics or restate control flow, only add information the code can't express. It gives a bad-comment example ("Now go through the b array and make sure whenever i occurs the next element is i+1") as the kind of restating comment to avoid. Comments belong in "tricky parts of the code" — specifically, "if you're going to have to explain it at the next code review, you should comment it now." [google-python-style]
- PEP 8 gives the canonical minimal example of the why-not-what distinction: `x = x + 1  # Increment x` is discouraged (restates the code); `x = x + 1  # Compensate for border` is the encouraged form (states the reason). PEP 8 also states "comments that contradict the code are worse than no comments," making staleness a first-class failure mode, not just an annoyance. [pep8-comments]
- Go's official code-review guidance (go.dev/wiki/CodeReviewComments) requires doc comments to be full sentences beginning with the name of the declared thing, so they read correctly when godoc extracts them — a mechanical rule distinct from, but complementary to, the why-not-what rule; it targets comment *form* for a specific downstream renderer, not comment *content*. [go-code-review-comments]
- Kernighan & Pike's *The Practice of Programming* states the "best comments aid the understanding of a program by briefly pointing out salient details or by providing a larger-scale view of the proceedings" (p. 23) and give the rule "don't belabor the obvious": "Comments should add something that is not immediately evident from the code, or collect into one place information that is spread [through] the source" (p. 23). [kernighan-pike-tpop]
- Kernighan & Pike also state "don't comment bad code, rewrite it," with the diagnostic "when the comment outweighs the code, the code probably needs fixing" (p. 25) — treating an over-long explanatory comment as a code smell pointing at the code, not a justification for keeping the code as-is. [kernighan-pike-tpop]
- Kernighan & Pike's "don't contradict the code" rule (p. 25) is the same staleness concern PEP 8 states independently: "when you change code, make sure the comments are still accurate." Two independent primary sources, decades apart, name comment/code drift as a specific commenting failure mode, not a general code-quality afterthought. [kernighan-pike-tpop]
- Ousterhout's *A Philosophy of Software Design* (2nd ed.) devotes Chapter 13, "Comments Should Describe Things that Aren't Obvious from the Code," to this question, with subsections 13.5 "Interface documentation" and 13.6 "Implementation comments: what and why, not how" — the chapter title itself is the operational test: if a fact is obvious from the code, it fails the bar for a comment; if it isn't, it's a candidate. [ousterhout-aposd-ch13]
- Ousterhout's core mechanism: comments should add information at a *different level of abstraction* than the code, not restate it at the *same* level. Lower-level comments add precision (exact meaning — units, boundary inclusivity/exclusivity, null handling, resource ownership, invariants); higher-level comments add intuition (the reasoning behind the code, or a simpler way to think about it). "Comments at the same level of detail as the code are likely to be redundant with the code — they don't provide any information beyond what the code provides." [ousterhout-aposd-ch13]
- Ousterhout separates **interface comments** (what a caller needs to know to use a class/method without reading its body: behavior, arguments, return values, side effects, exceptions, preconditions) from **implementation comments** (how the internals work — precisely the "what and why, not how" scope of section 13.6). He names the anti-pattern "Implementation Documentation Contaminates Interface" for when an interface comment leaks implementation details irrelevant to callers — treated as a design smell (often signaling a shallow interface), not just a style nit. [ousterhout-aposd-ch13]
- Ousterhout gives a review heuristic distinct from, but compatible with, "why not what": if a code reviewer says something isn't obvious, the author should not argue — "if a reader thinks it's not obvious, then it's not obvious" — and should fix it with a better comment or clearer code, deciding which based on whether the confusion is inherent to the logic (comment) or an artifact of poor naming/structure (fix the code instead). [ousterhout-aposd-ch13]

## SOURCES

**google-docguide-best-practices**
URL: https://google.github.io/styleguide/docguide/best_practices.html
Accessed: 2026-08-14
Quote: "The primary purpose of inline comments is to provide information that the code itself cannot contain, such as why the code is there." / method documentation "does not usually explain why code behaves a particular way unless that's relevant to a developer's understanding of how to use the method... 'Why' explanations are for inline comments."

**google-cpp-style**
URL: https://google.github.io/styleguide/cppguide.html#Comments
Accessed: 2026-08-14
Quote: "In your implementation you should have comments in tricky, non-obvious, interesting, or important parts of your code." / "If there is anything tricky about how a function does its job, the function definition should have an explanatory comment." / on ctors/dtors: "comments that just say something like 'destroys this object' are not useful."
Note: Retrieved via search-engine synthesis of the live page (WebFetch on the full cppguide.html did not include the Comments section, which loads further down the single-page doc); quotes are corroborated across multiple independent summaries of the same canonical page and match Google's known public style guide text.

**google-python-style**
URL: https://google.github.io/styleguide/pyguide.html
Accessed: 2026-08-14
Quote: "The final place to have comments is in tricky parts of the code. If you're going to have to explain it at the next code review, you should comment it now." / "Never describe the code. Assume the person reading the code knows Python... better than you do."

**pep8-comments**
URL: https://peps.python.org/pep-0008/#comments
Accessed: 2026-08-14
Quote: "Comments that contradict the code are worse than no comments." Example pair: `x = x + 1  # Increment x` (discouraged) vs. `x = x + 1  # Compensate for border` (encouraged, implicit in the surrounding guidance on inline comments).

**go-code-review-comments**
URL: https://go.dev/wiki/CodeReviewComments
Accessed: 2026-08-14
Quote: "Comments documenting declarations should be full sentences, even if that seems a little redundant. This approach makes them format well when extracted into godoc documentation."

**kernighan-pike-tpop**
URL: https://weinman.cs.grinnell.edu/courses/CSC261/2020S/assignments/grading.html (course notes quoting Kernighan & Pike, *The Practice of Programming*, Addison-Wesley, 1999, ch. 1 "Style")
Accessed: 2026-08-14
Quote: "Comments should add something that is not immediately evident from the code, or collect into one place information that is spread [through] the source" (p. 23). "The best comments aid the understanding of a program by briefly pointing out salient details or by providing a larger-scale view of the proceedings" (p. 23). "When the comment outweighs the code, the code probably needs fixing" (p. 25).
Note: Not the primary text itself (a course-notes secondary source quoting it with page numbers); treat page citations as reported, not independently verified against a physical/PDF copy in this session.

**ousterhout-aposd-ch13**
URL: https://web.stanford.edu/~ouster/cgi-bin/aposd.php (book home page; chapter is "A Philosophy of Software Design," 2nd ed., Ch. 13, "Comments Should Describe Things that Aren't Obvious from the Code," sections 13.5 "Interface documentation" and 13.6 "Implementation comments: what and why, not how")
Accessed: 2026-08-14
Quote: Section title verified directly: "13.6 Implementation comments: what and why, not how." Paraphrased-but-attributed via secondary reader notes: "comments at the same level of detail as the code are likely to be redundant" and the lower-level-precision/higher-level-intuition framing; the "Implementation Documentation Contaminates Interface" anti-pattern name (book p. 114, 1st ed.).
Note: Full verbatim chapter text is under copyright and was not available via search; the chapter/section titles were confirmed directly, and content claims are drawn from multiple independent, mutually-consistent secondary summaries (reader notes, book-review posts) rather than a single retelling — treat prose-level wording as paraphrase, not verbatim, except where quoted.

## SYNTHESIS

Four independent primary sources — Google (cross-language + C++ + Python guides), PEP 8, Kernighan & Pike, and Ousterhout — converge on the same rule stated in different vocabularies: a comment earns its place only if it adds information the code doesn't already carry. Google and Ousterhout both operationalize this as a level-of-abstraction test rather than a vague "be helpful" instruction: Google splits by *audience* (interface/API docs = contract for callers, who don't want implementation rationale; inline comments = the "why" for maintainers), while Ousterhout splits by *abstraction level* (comments below the code's detail level add precision, comments above it add intuition, comments at the same level are noise) and further splits *within* implementation comments by interface-vs-implementation scope. These are compatible, not competing: Google's split is essentially Ousterhout's interface/implementation split with different names, and Ousterhout's "same-level = useless" test is a more precise formulation of Google's "never describe the code" and Kernighan & Pike's "don't belabor the obvious."

The delete-test the research question asked about ("would a reader be confused if I deleted this comment") isn't a single named test in any source verbatim, but it's the direct behavioral consequence of every rule found: Kernighan & Pike's "add something not immediately evident," Google Python's "never describe the code," and Ousterhout's "same level = redundant" are all different phrasings of the same acceptance criterion — a comment must fail to be reconstructible by re-reading the code. Ousterhout's actual named review heuristic is close but socially oriented, not mechanical: "if a reader thinks it's not obvious, then it's not obvious" — i.e., the test is empirical (does a real reader get confused) rather than something the author can self-certify.

Two points are worth flagging for any downstream style guide or lint rule built from this corpus entry:
1. **Staleness is a first-class failure mode in two independent sources** (Kernighan & Pike's "don't contradict the code," PEP 8's "comments that contradict the code are worse than no comments"), not a secondary concern. A why-comment that's gone stale is worse than no comment, which argues for keeping why-comments minimal and tightly scoped rather than maximized — quality over coverage.
2. **"Why not what" is necessary but not sufficient.** Google's C++ guide and Ousterhout both carve out a legitimate class of *low-level "what"* comments that survive the test: units, null-handling, boundary inclusivity, resource ownership, invariants — facts that are true "what" statements but are NOT recoverable from the code itself (a type signature doesn't tell you if `end` is inclusive). The rule is better stated as "comment what the code cannot say for itself" — which is usually why, but is sometimes a non-obvious precise fact. Collapsing the rule to literally "why not what" would wrongly forbid these.
