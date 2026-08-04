---
title: "A coined term is legitimate only if it recurs and does real work in the text — the recurrence test is the actionable core of the invented-vocabulary AI-tell, independently derived in two unrelated writing disciplines"
date: 2026-08-04
topic: writing-craft
tags: [invented-vocabulary, jargon, naming, ai-tells, recurrence-test, editing]
status: draft
sources: [tropes-fyi, avoid-ai-writing-skill, boscoh-jargon, kubie-feature-names, whitehead-reification, orwell-meaningless-words, wikipedia-signs-of-ai-writing]
source_session: unknown
---

## CLAIMS

- No single canonical term exists for "inventing a Title-Case proper-noun label for a concept that has no established name and doesn't need one." Three independent lines of inquiry converge on close matches, which is itself evidence the pattern is real rather than idiosyncratic. [tropes-fyi][avoid-ai-writing-skill][whitehead-reification]
- tropes.fyi names the pattern "Invented Concept Labels": AI appends abstract problem-nouns (paradox, trap, creep, divide, vacuum, inversion) to domain words — "supervision paradox," "acceleration trap" — and uses them as if they were established, rigorously defined terms, functioning as rhetorical shorthand that names a thing instead of arguing for it. [tropes-fyi]
- A GitHub-hosted style skill (`avoid-ai-writing`) names an adjacent pattern, "slot-fill profundity" — formulas like "X is the language of Y" or "X is the currency of Z" that manufacture a general law out of a specific observation — and separately flags AI-generated headers: a heading followed by a one-line restatement before real content starts, or a generic scaffolding heading imposed regardless of whether the actual content supports that structure. [avoid-ai-writing-skill]
- Reification, or the "fallacy of misplaced concreteness" (Whitehead, 1925), is the most rigorous pre-existing name for the underlying cognitive move — treating a process or abstraction as a discrete, concrete thing, often signaled by capitalizing it — but it predates LLMs by a century and is not specific to naming. [whitehead-reification]
- Orwell's "meaningless words" category (1946) — words that "do not point to any discoverable object" and are not even expected to by the reader — is the closest of his four failure categories, and he states explicitly that this category resists mechanical treatment. [orwell-meaningless-words]
- Two independent disciplines converge on the same operational test for when a coined term is earned: (1) scientific writing (boscoh.com, "Jargon: The Art of Naming Things") treats jargon like character names in short fiction — "if you refer to something only twice in a paper, just spell out the whole thing" rather than coin a term, the way secondary characters in fiction go unnamed; (2) product/UX writing (Scott Kubie, "Fighting Proper Noun Feature Names") states "don't name things if you don't have to," and distinguishes internal codenames (fine, never user-facing) from marketing names (earned only by recurrence and real differentiation) from UI labels (should describe function, not be named). [boscoh-jargon][kubie-feature-names]
- Both sources independently state the same rule: a name is earned by recurrence — it must be referenced many times and needs a handle to avoid repeating a long description. A concept used once or twice should stay unnamed and be described plainly. [boscoh-jargon][kubie-feature-names]
- No rigorous, citable "N-uses threshold" (e.g. "never coin a term used only once") is codified in any authoritative style guide. The recurrence rule is strong convergent practitioner consensus from two unrelated disciplines, not an industry standard — treat it as such, not as settled science. [boscoh-jargon][kubie-feature-names]
- A related, partially mechanical proxy check exists: count how many times a Title Case or quoted "concept name" phrase recurs in a corpus outside the section where it is defined. Near-zero recurrence is a usable signal that the term was not earned. This proxy is countable by a linter; whether the concept the term names actually exists in the real system being described is not — that judgment requires reading the underlying spec/codebase, not just counting occurrences. [avoid-ai-writing-skill]
- Google's Developer Documentation Style Guide gives the field's most explicit four-step decision procedure for when a coined term is acceptable: (1) write around it entirely, (2) replace with an already-established term, (3) if used only once, define it plainly and put the jargon term in parentheses rather than minting it as a standalone handle, (4) if used repeatedly, define briefly on first reference and then use it consistently. This is the same recurrence logic as (1) above, operationalized as an authored style-guide procedure rather than inferred from craft essays. [avoid-ai-writing-skill]
- Wikipedia's "Signs of AI writing" — built from thousands of real deletion/review cases — explicitly lists "ineffective indicators" (promotional tone alone, professional style, mere presence of specific facts) as *not* reliable AI signals on their own, a documented corrective against over-attributing invented-vocabulary suspicion to text that merely uses technical terms correctly. [wikipedia-signs-of-ai-writing]

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

This corpus already holds two entries under `writing-craft` (`making-ai-assisted-prose-not-read-as-machine-generated.md`, `non-slop-prose-production-system.md`) that reproduce the full source research reports nearly verbatim, covering lexical-tell word lists, em dashes, hedging, passive voice, sentence-length burstiness, and a four-layer production system. This entry deliberately does not repeat that ground. It exists because the single most load-bearing, most actionable, and most under-emphasized finding in that research — the recurrence test for invented vocabulary — is buried as one subsection among many in both existing entries, and it is the one finding that came from a *named, concrete complaint* rather than a generic slop-avoidance sweep: a real site shipped a section titled "The proof loop" describing a mechanism that has no other name anywhere in the system it describes.

The mechanism is not "coined terms are bad." Naming is normal and often load-bearing — "controller" in MCP, "grant" in an auth protocol, any term used hundreds of times earns its existence by that use. The failure is specifically a term minted once, in one section, to sound like it compresses something rigorous when it compresses nothing — the term does the work an argument should have done. The tell under the tell, per Google's own style guide independently reaching the same structure, is symmetrical: if used once, spell it out in plain language; only promote to a standalone term once real recurrence has already happened.

Practical application: before shipping a heading or a Title-Case label, grep the corpus for every other occurrence of that exact phrase. Zero or one other occurrence is the actionable proxy signal — not proof the term is wrong, but a forcing function to ask the un-automatable question a linter cannot answer: does this label point to something that actually, verifiably exists in the spec or the code, or is it standing in for an explanation that was never written?
