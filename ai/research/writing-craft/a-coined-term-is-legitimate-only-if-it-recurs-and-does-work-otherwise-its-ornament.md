---
title: "A coined term is legitimate only if it recurs and does real work in the text — the recurrence test is the actionable core of the invented-vocabulary AI-tell, independently derived in two unrelated writing disciplines"
date: 2026-08-04
topic: writing-craft
tags: [invented-vocabulary, jargon, naming, ai-tells, recurrence-test, editing]
status: draft
sources: [tropes-fyi, avoid-ai-writing-skill, boscoh-jargon, kubie-feature-names, whitehead-reification, orwell-meaningless-words, wikipedia-signs-of-ai-writing]
source_session: b74defed-7075-46ee-9496-cdf4b082dd4d
---

## CLAIMS

- tropes.fyi names a pattern "Invented Concept Labels": AI appends abstract problem-nouns (paradox, trap, creep, divide, vacuum, inversion) to domain words — "supervision paradox," "acceleration trap" — and uses them as if they were established, rigorously defined terms. [tropes-fyi]
- A GitHub-hosted style skill (`avoid-ai-writing`) names an adjacent pattern, "slot-fill profundity" — formulas like "X is the language of Y" or "X is the currency of Z" that manufacture a general law out of a specific observation — and separately flags AI-generated headers: a heading followed by a one-line restatement before real content starts, or a generic scaffolding heading imposed regardless of whether the actual content supports that structure. [avoid-ai-writing-skill]
- Reification, or the "fallacy of misplaced concreteness" (Whitehead, *Science and the Modern World*, 1925), names treating a process or abstraction as a discrete, concrete thing, often signaled by capitalizing it. [whitehead-reification]
- Orwell's "meaningless words" category (*Politics and the English Language*, 1946) covers words that "do not point to any discoverable object" and are not even expected to by the reader; Orwell states this category resists mechanical/rule-based treatment, unlike his other three failure categories. [orwell-meaningless-words]
- Scientific-writing guidance (boscoh.com, "Jargon: The Art of Naming Things") states: "if you refer to something only twice in a paper, just spell out the whole thing" rather than coin a term — comparing this to how secondary characters in short fiction go unnamed. [boscoh-jargon]
- Product/UX-writing guidance (Scott Kubie, "Fighting Proper Noun Feature Names") states "Don't name things if you don't have to," and distinguishes internal codenames (never user-facing) from marketing names (earned only by recurrence and real differentiation) from UI labels (should describe function, not be named). [kubie-feature-names]
- Google's Developer Documentation Style Guide gives a four-step decision procedure for coined terms: (1) write around it entirely, (2) replace with an already-established term, (3) if used only once, define it plainly and put the jargon term in parentheses rather than minting it as a standalone handle, (4) if used repeatedly, define briefly on first reference and then use it consistently. [avoid-ai-writing-skill]
- Wikipedia's "Signs of AI writing" guidance, built from editor review/deletion cases, lists "ineffective indicators" — promotional tone alone, professional style, or the mere presence of specific facts — as explicitly not reliable AI signals on their own. [wikipedia-signs-of-ai-writing]
- No N-uses threshold for when a coined term becomes acceptable (e.g. "never coin a term used only once") is codified in any of the sources above as an industry-wide standard; boscoh.com and Kubie's post are the only two sources found stating a recurrence-based rule, and both are single-author blog posts, not style-guide or peer-reviewed material. [boscoh-jargon][kubie-feature-names]

## SOURCES

**tropes-fyi**
URL: https://tropes.fyi/tropes-md (discussed further at https://ossama.is/writing/tropes)
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)
Quote: "AI clusters invented compound labels that sound analytical without being grounded... They function as rhetorical shorthand: name a thing, skip the argument. Multiple such labels in the same piece is a strong signal of AI slop."

**avoid-ai-writing-skill**
URL: https://github.com/conorbronsdon/avoid-ai-writing/blob/main/SKILL.md
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)
Quote: "'slot-fill profundity' — formulas like 'X is the language of Y' or 'X is the currency of Z' that manufacture a general law out of a specific observation"

**boscoh-jargon**
URL: https://boscoh.com/science/jargon-the-art-of-naming-things.html
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)
Quote: "if you refer to something only twice in a paper, just spell out the whole thing" rather than coin a term — like secondary characters in short fiction, "where you don't give them a name."

**kubie-feature-names**
URL: https://kubie.co/blog/fighting-feature-names/
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)
Quote: "Don't name things if you don't have to." / "Marketing loves to name things, but marketing isn't design. It shouldn't be their call."

**whitehead-reification**
URL: https://en.wikipedia.org/wiki/Reification_(fallacy)
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)

**orwell-meaningless-words**
URL: https://www.orwellfoundation.com/the-orwell-foundation/orwell/essays-and-other-works/politics-and-the-english-language/
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)

**wikipedia-signs-of-ai-writing**
URL: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
Accessed: 2026-08-03 (via prior research pass; not independently re-fetched this session)

## SYNTHESIS

This corpus already holds two entries under `writing-craft` (`making-ai-assisted-prose-not-read-as-machine-generated.md`, `non-slop-prose-production-system.md`) that reproduce fuller source research reports, covering lexical-tell word lists, em dashes, hedging, passive voice, sentence-length burstiness, and a four-layer production system. This entry deliberately does not repeat that ground. It exists because the recurrence test for invented vocabulary is, in my judgment, the single most actionable finding in that research and is under-emphasized as one subsection among many in both existing entries — and because it is a finding that traces to a named, concrete complaint (a real site shipped a section titled "The proof loop" describing a mechanism that has no other name anywhere in the system it describes) rather than a generic slop-avoidance sweep.

The recurrence-test sources (boscoh.com, Kubie) are the two I found stating this rule explicitly; I have not confirmed they are the only or the most authoritative sources for it, and no style guide I found codifies a specific N-uses threshold — treat "a name is earned by recurrence" as a plausible, convergent, but not industry-standardized heuristic, not settled science. Google's four-step jargon procedure independently reaches the same structural logic (define once used rarely, promote to a standalone term only once used repeatedly) via an authored style guide rather than a craft essay, which I read as one additional, more authoritative data point for the same rule, not fully independent confirmation of it.

My interpretation of the mechanism: this is not "coined terms are bad." Naming is normal and often load-bearing — a term used hundreds of times earns its existence by that use. The failure I'd flag is a term minted once, in one section, to sound like it compresses something rigorous when it compresses nothing.

A practical, partially mechanical proxy follows from this, though it is my own extrapolation and not something any source states directly: count how many times a Title Case or quoted "concept name" phrase recurs in a document outside the section that defines it. Near-zero recurrence is a usable signal that the term wasn't earned — a forcing function to ask the question no source claims a linter can answer on its own: does this label point to something that actually, verifiably exists in the system being described, or is it standing in for an explanation that was never written?
