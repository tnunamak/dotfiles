---
title: "Abstract nouns promoted to technical terms read as AI-written because vagueness is unfalsifiable; the discriminator is corpus drift, not a ban-list"
date: 2026-08-04
topic: writing-craft
tags: [ai-tells, abstract-nouns, linting, gowers, prose-quality, discriminator-design]
status: draft
sources: [gowers-plain-words, gowers-abc-abstract, tropes-fyi, vila-load-bearing, ai-idiolect, algorithmic-bridge, avoid-ai-writing, forbes-cook-2026, excess-vocabulary]
source_session: 3abfd093-bedc-425f-98dd-cc4d68397693
---

## CLAIMS

- The mechanism is unfalsifiability, not ugliness: an abstract noun is chosen *because* it cannot be checked, so it cannot be wrong. Gowers states this directly — "The very vagueness of abstract words is one of the reasons for their popularity" — and calls the retreat into "the safer obscurity of the abstract" the greatest vice of present-day writing. [gowers-plain-words] [gowers-abc-abstract]
- The same account has been independently rediscovered three times for LLMs: abstract nouns "commit the writing to exactly nothing", with the framing that humans select words hoping to be correct while AI selects words to avoid being incorrect [ai-idiolect]; "AI has read everything but experienced nothing... it tends to reach for abstract conceptual words rather than concrete, tangible ones" [algorithmic-bridge]; and "A metaphor that fits every importance-claim describes none of them" [vila-load-bearing].
- Gowers gives a near-lintable heuristic predating LLMs by 70 years: an abstract noun as the SUBJECT of a sentence is a danger signal prompting the writer to ask whether the idea could be stated more directly. [gowers-plain-words]
- The observable form is naming without defining — abstract nouns "used as if they're established, rigorously defined terms... They function as rhetorical shorthand: name a thing, skip the argument." [tropes-fyi]
- NEGATIVE RESULT, and the most decision-relevant finding here: `boundary`, `seam`, `truth`, `proof`, `evidence`, `provenance`, `invariant`, `contract` are cited as AI tells by NO published source found in a deliberate open-web sweep. Attested members of the class are `load-bearing`, `scaffolding`, `substrate` [vila-load-bearing] and `shape`, `signal`, `honest`+technical-noun [forbes-cook-2026] [avoid-ai-writing]. Practitioner ban-lists are incomplete in a *structural*, not accidental, way. [excess-vocabulary]
- The reason mainstream lists miss this class: the empirical literature measured *style words* — verbs and adjectives (delve, intricate, pivotal, meticulously) — not content nouns, and seeded its marker lists from crowd-nominated terms, so it can only rediscover what practitioners already named. [excess-vocabulary]
- A bare ban-list is the wrong instrument in both directions: it fails open on every literal noun the author forgot ("The denylist fails open. Any literal noun we didn't think of flags"), and it flags legitimate domain use. The documented fix is to invert to an allowlist that fails CLOSED, matching a precision-over-recall bar. [avoid-ai-writing]
- A working discriminator needs two conditions ANDed, so word identity never decides alone: (a) the noun sits in a copular/attributive NAMING frame, not ordinary predicative use; (b) the domain's own corpus measurably prefers a different word for that concept. Condition (b) is countable and is what makes the rule generalize past any word list.
- Sibling regex detectors for this class have been built and REVERTED in prior art, because "every regex tight enough to spare the carve-outs stopped matching the tell" — deciding it "requires reading whether the clause carries information or only announces that information is coming, which is what a reader can do and a pattern cannot." Treat mechanical checks as a floor, not a replacement for judgment. [avoid-ai-writing]
- Mechanical find-and-replace makes the output worse, not better: "Swap 'load-bearing' for 'central' by hand across an essay and you get something worse than the tic: prose that reads as stitched." Rules should report and explain rather than auto-substitute. [vila-load-bearing]
- Attribution corrections: "abstractitis" is likely GOWERS' (added in his 1965 revision of Fowler), not Fowler's own; "abstract appendages" could not be verified as a Fowler phrase anywhere and should not be cited; "semantic bleaching" is historical-linguistics terminology for grammaticalization and is NOT an LLM finding. Orwell's "meaningless words" targets words that were already empty (romantic, values, fascism), which is a DIFFERENT class from ordinary nouns with good concrete referents being promoted to pseudo-jargon.

## SOURCES

**gowers-plain-words**
URL: https://plain-words.com/chapter/8/
Accessed: 2026-08-04
Quote: "The very vagueness of abstract words is one of the reasons for their popularity."

**gowers-abc-abstract**
URL: https://www.ourcivilisation.com/smartboard/shop/gowerse/abc/abstract.htm
Accessed: 2026-08-04
Quote: "Abstract nouns have less precise meanings than concrete ones, and therefore should be avoided as far as possible by those who wish to make their meaning plain."

**tropes-fyi**
URL: https://tropes.fyi/tropes-md
Accessed: 2026-08-04
Quote: "It appends abstract problem-nouns (paradox, trap, creep, divide, vacuum, inversion) to domain words... and uses them as if they're established, rigorously defined terms. They function as rhetorical shorthand: name a thing, skip the argument. Multiple such labels in the same piece is a strong signal of AI slop."

**vila-load-bearing**
URL: https://medium.com/@Bismar/ai-when-the-metaphors-are-load-bearing-830d37971e25
Accessed: 2026-08-04
Quote: "A metaphor that fits every importance-claim describes none of them."

**ai-idiolect**
URL: https://workbravely.substack.com/p/the-ai-idiolect-a-professional-writers
Accessed: 2026-08-04
Quote: "commit the writing to exactly nothing! They have broad associative meanings, fit into many contexts, and might not be good, but also aren't… wrong?"

**algorithmic-bridge**
URL: https://www.thealgorithmicbridge.com/p/10-signs-of-ai-writing-that-99-of
Accessed: 2026-08-04
Quote: "AI has read everything but experienced nothing. Consequently, it tends to reach for abstract conceptual words rather than concrete, tangible ones."

**avoid-ai-writing**
URL: https://github.com/conorbronsdon/avoid-ai-writing
Accessed: 2026-08-04
Quote: "The denylist fails open. Any literal noun we didn't think of flags... Invert it to an allowlist: flag attributive `load-bearing` only before an *abstract* noun... Fails closed, which matches CONTRIBUTING.md's 'precision over recall' bar — an unlisted noun means a missed tell, not a wrongly-flagged human."

**forbes-cook-2026**
URL: https://www.forbes.com/sites/jodiecook/2026/05/21/15-new-giveaway-signs-of-ai-writing-may-2026-update/
Accessed: 2026-08-04
Quote: "shape — a stand-in for any abstract influence the model can't define"

**excess-vocabulary**
URL: https://arxiv.org/abs/2406.07016
Accessed: 2026-08-04
Quote: "an abrupt increase in the frequency of certain style words"

## SYNTHESIS

This is a genuine hole in the published AI-tell prior art, and the hole has a
structural cause worth remembering: every mainstream list was built by
crowd-nominating overused words, so it can only contain words someone already
noticed. Content nouns that are *also legitimate domain vocabulary* are exactly
the blind spot that method produces. Expect other unnamed classes with the same
shape.

The practical consequence for building checkers: do not implement this as a
ban-list, and do not trust an owner-supplied word list as the rule's decision
procedure — I could not corroborate most of one such list, and it was still
probably correct. Instead make word membership *necessary but not sufficient*
and put the decision on a measurable second condition. The version that worked
was: (a) is the noun in a naming frame, AND (b) does the project's own corpus
prefer a different word for that concept, counted against a synonym set. That
second condition is the transferable idea — it turns "does this feel like slop"
into "does this drift from the vocabulary the system actually uses", which is
countable, arguable from evidence, and survives the word list being wrong or
incomplete.

Two design cautions carry forward. First, always split prose from markup before
counting: in the case that motivated this, 5 of 7 hits for the offending word
were CSS class names and HTML comments no reader sees, and a naive count
overstated the problem by 20x. Second, prior art built and then reverted a regex
for the sibling rule because narrow-enough patterns stopped matching the tell —
so scope these rules as a floor that catches the clear cases, state the limits
in the tool's own output, and leave the ambiguous middle to a reader.

Related corpus entries: [a-coined-term-is-legitimate-only-if-it-recurs-and-does-work-otherwise-its-ornament.md]
covers the recurrence rule, which is the same test at a different scope —
recurrence asks "does this name exist in the system?", this asks "is this the
word the system uses for it?". A word can pass the first and fail the second,
which is precisely how this class evades existing checks.
