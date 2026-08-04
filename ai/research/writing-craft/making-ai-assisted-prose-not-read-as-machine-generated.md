---
title: "AI prose reads as machine-generated mainly through invented names, hedging density and uniform rhythm; the fixable parts are mechanizable, the rest is craft"
date: 2026-08-03
topic: writing-craft
tags: [writing, prose, ai-tells, style, editing]
status: draft
sources: [practitioner-diagnosis, pre-ai-writing-theory]
source_session: unknown
---

# Human Craft Research: Making Prose Not Read as Machine-Generated

Research date: 2026-08-03. Commissioned to answer a concrete complaint: frontier-model prose reads as "robotic," "speaks jargon," "spits out verbose text," and — the flagship example — invents names for things that have no name in the real system (a section titled "The proof loop" on the owner's own site, describing a mechanism that isn't actually called that anywhere else). The owner has limited time and cannot hand-write everything, so this report also asks what can be mechanized and what can't, and whether smaller/older/differently-prompted models help.

This is not a survey of AI-detection tools. It is about craft: what practitioners diagnose, what pre-AI writing theory already explains the failure mode, what's checkable, and what a working production system looks like.

---

## 1. What practitioners diagnose (2025–2026 discourse)

### 1.1 The term "AI slop" and its actual scope

"AI slop" traces to 2016 4chan slang for generic low-effort content, repurposed in **May 2024** by a poster using the handle "deepfates" and amplified same-day by Simon Willison, whose definition has become the standard reference: *"Not all AI-generated content is slop... if it's mindlessly generated and thrust upon someone who didn't ask for it, slop is the perfect term for it."* Willison's point is about **publishing without review**, not about AI-generation per se — his own practice: *"I attach my name and stake my credibility on the things that I publish."* ([simonwillison.net/2024/May/8/slop](https://simonwillison.net/2024/May/8/slop/))

It was selected as Merriam-Webster's 2025 Word of the Year. Contrary to an intuitive assumption, Wikipedia's own `AI slop` article notes the term has **not** narrowed specifically to prose — it remains a catch-all across text/image/video, and "has so far resisted formal definition." ([en.wikipedia.org/wiki/AI_slop](https://en.wikipedia.org/wiki/AI_slop)) The writing-specific critique lives in a more technical, separate discourse — the sources below.

Max Read's tracing piece is the best journalism-about-journalism on the term's evolution, and argues the pre-2024 "low-effort content" sense and the post-2024 "AI-specific" sense are converging back around one shared property: **textureless, over-optimized content** with nothing underneath. ([maxread.substack.com/p/what-is-slop-exactly](https://maxread.substack.com/p/what-is-slop-exactly))

### 1.2 The most rigorous catalogues of specific tells

Two threads of evidence stand out for being empirical rather than impressionistic.

**Academic vocabulary drift (peer-reviewed, large-N).** Kobak, González Márquez, Horvát, and Lause, in *"Delving into ChatGPT usage in academic writing through excess vocabulary"* (arXiv 2406.07016, published in *Science Advances*), analyzed **14.2 million PubMed abstracts** (2010–2024) using an epidemiological "excess mortality"-style method: project pre-ChatGPT frequency trends forward and compare to what's actually observed. They found ≥10% of 2024 abstracts show LLM-influenced excess vocabulary. Top excess words by frequency ratio: **delves (25.2×), showcasing (9.2×), underscores (9.1×)**, plus intricate, meticulously, pivotal, realm, comprehensive, notably. 66% of the excess words were verbs, 18% adjectives — a style shift, not a topic shift, and one the authors call "unprecedented in quality and quantity" compared to prior vocabulary disruptions like COVID (which were content nouns, not style words). ([hackaday.com/2024/06/22/uncovering-chatgpt-usage-in-academic-papers-through-excess-vocabulary](https://hackaday.com/2024/06/22/uncovering-chatgpt-usage-in-academic-papers-through-excess-vocabulary/))

**Why those specific words — the mechanism, not just the list.** Juzek & Ward, *"Why Does ChatGPT 'Delve' So Much? Exploring the Sources of Lexical Overrepresentation in LLMs"* (arXiv 2412.11385, COLING 2025), identify 21 focal words (delve, intricate, commendable, meticulous, surpass, elevate, foster, tapestry, realm, navigate, landscape, pivotal, resonate, testament, underscore, showcasing, compelling, paramount, crucial, unwavering, alignment) and systematically test candidate causes. They rule out architecture, training algorithm, and raw pretraining-data frequency as the sole cause and instead point to **RLHF (reinforcement learning from human feedback)** as the likely mechanism — comparing a base Llama model to its RLHF-tuned counterpart showed the tuned model was measurably less "surprised" by buzzword-laden text, and a human-preference study supported the idea that raters rewarded this vocabulary. This is directly relevant to the "can we get better by getting dumber" question in §5 below. ([news.fsu.edu, Feb 2025](https://news.fsu.edu/news/science-technology/2025/02/17/why-does-chatgpt-delve-so-much-fsu-researchers-begin-to-uncover-why-chatgpt-overuses-certain-words/))

A follow-up, *"Human-LLM Coevolution: Evidence from Academic Writing"* (arXiv 2502.09606), analyzed 1.29M arXiv abstracts and found usage of "delve"/"intricate"/"realm" **dropped sharply starting ~April 2024** — right after these words were publicly called out as AI tells — while other AI-favored words like "significant" kept climbing. This is evidence that authors self-edit once a tell becomes known, and that unnoticed markers persist longer. It also means any fixed word-blocklist has a shelf life: the tells that are famous get edited out; the report's recommended system (§6) should assume the list needs periodic refresh, not a one-time build.

**The single most comprehensive catalogue.** Wikipedia's own editorial guidance, **"Wikipedia:Signs of AI writing,"** built from thousands of real deletion/review cases (not speculation), covers vocabulary (delve, boast, tapestry, crucial, underscore, vibrant), sentence structure (avoidance of plain "is/are" in favor of "serves as/functions as"; negative-parallelism "not just X but Y"; rule-of-three overuse), tone (promotional "nestled," "rich heritage"), and — directly relevant to the owner's complaint — **formatting/header tells**: Title Case headers where sentence case is standard, inline-bold-header bullet lists, and formulaic closing sections like "Challenges and Future Prospects" imposed regardless of whether the actual content supports that structure. It also explicitly lists **"ineffective indicators"** — promotional tone alone, professional style, or the mere presence of specific facts — as *not* reliable AI signals on their own, a useful corrective against overclaiming. ([en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing))

### 1.3 The rhetorical mechanism — why these patterns read as hollow, not just repetitive

The most useful sources go past "here's a list of words" to explain the actual rhetorical failure.

**Real rhetorical figures, deployed as filler.** A widely-cited analysis (Daniel Miessler; note below on sourcing confidence) identifies that AI clichés are not new — they are named classical rhetorical figures used at frequencies that break them: "It's not X, it's Y" is **paradiastole**; triadic adjective stacks are **tricolon/isocolon**; "from X to Y" is **merism**. The mechanism given: *"triadic lists dominate good persuasive prose, which means triads dominate the training corpus, which means the next-token distribution favors triadic continuations almost automatically."* The failure isn't the device — competent writers use all of these — it's frequency: *"the figures stop being load-bearing and start being wallpaper."* (Sourcing note: this page returned HTTP 410 during fetch; content reconstructed from a search-engine cache, so treat as needing re-verification via the Wayback Machine before quoting verbatim.)

**"TED-talk style."** Forbes contributor Charlie Fink names the umbrella phenomenon directly: prose that *"sounds insightful at first glance, but then you notice it's just meaningless prose delivered with dramatic flourishes."* His seven tells: contrastive framing, self-answered rhetorical questions, purposeless em-dashes, triplet framing, "the inspirational pivot" (elevating a technical point into pseudo-profound abstraction — his term for a "head fake" that simulates depth without adding any), unsourced "studies show" authority claims, and fabricated unattributed quotes. ([forbes.com/sites/charliefink/2025/06/12/the-seven-tells-of-ai-writing](https://www.forbes.com/sites/charliefink/2025/06/12/the-seven-tells-of-ai-writing/))

**The "universal omniwriter" and the feedback loop.** Sam Kriss's NYT Magazine piece (fetch blocked by paywall; via search summary, lower confidence) argues AI prose has no lived experience to draw on, so *"without sensory grounding, AI leans on vague emotional references and conceptual fog"* — and separately documents human writers unconsciously absorbing AI phrasing from exposure, meaning the tells may become self-erasing signals over time as they leak into human writing (this mirrors the "delve" self-editing finding above, but the *reverse* direction — human writers picking AI habits up rather than dropping them).

**A worked-example fixture-first proof.** One outdoor-writing critique (Adirondack Explorer; 429-blocked, via search summary) names a genre-specific formula — "manufactured profundity": exhaustion opener → doubt by paragraph two → "the trail becomes a teacher" → pain reframed as wisdom → symbolic final miles → gratitude/transformation closer — and *tests the hypothesis* by prompting an AI to write a similar essay from scratch, getting output with identical lessons, phrases, and metaphors. This is a good template for how to verify a diagnosed pattern rather than just assert it.

**A richer field guide, in the same register as the owner's complaint.** Matthew Vollmer's Substack essay catalogues lexical tells (calling out "tapestry": *"I no longer believe there's a way to innocently use the word 'tapestry'"*), syntactic tells (naming the negated-contrast "not X, it's Y" construction "the single most diagnostic rhetorical move"), and gives the clearest positive prescription found in this research: **"Be specific, be strange, be where you actually are. The machine cannot be where you are."** He also names the "missing concrete particular" as the tell underneath the tell: *"No Tuesday. No laundromat. No grandmother with a specific... mentholated cough drop."* ([matthewvollmer.substack.com/p/i-asked-the-machine-to-tell-on-itself](https://matthewvollmer.substack.com/p/i-asked-the-machine-to-tell-on-itself))

**Em dash — the most contested single tell.** Jonathan Bailey at Plagiarism Today ran an actual controlled test: the same prompt to six models (ChatGPT, Copilot, Deepseek, Claude, Gemini, Meta.ai) produced em-dash counts ranging from 9 down to **0**. His conclusion is a useful corrective to overclaiming on this one marker: em dash is real but weak and trivially defeated by find-replace — *"it can't be much more than that."* ([plagiarismtoday.com/2025/06/26/em-dashes-hyphens-and-spotting-ai-writing](https://www.plagiarismtoday.com/2025/06/26/em-dashes-hyphens-and-spotting-ai-writing/)) Treat any em-dash rule in a linter as low-value on its own.

### 1.4 What editors who ship copy at scale actually do

The most operationally useful source found is **Every.to**, a publication that produces daily AI-adjacent business writing and has had to solve this exact problem at production scale. Editor-in-chief Kate Lee built a **400-rule style guide** fed into a Claude project for staff use. Staff editor Eleanor Warnock names the AI-isms directly — *"staccato, lists of three"* — and describes text that's bad enough under scrutiny that *"it would be easier to write it from scratch rather than trying to save it with an edit."* Her operating standard is **"bulletproof writing"**: prose where every word has survived a tough editor's scrutiny. Her closing line is the most important sentence in this whole research pass for a time-constrained owner: *"Writing is still hard. Don't let AI make you think it's easy."* ([every.to/context-window/editing-ai-writing](https://every.to/context-window/editing-ai-writing)) This is direct evidence that a large, explicit, maintained rule list plus human editorial judgment is the actual production system in use at an organization solving exactly this problem — not a one-shot prompt trick.

Other publications with public policy: **Wired** was first (2023), and Gideon Lichfield's original framing is worth quoting because it's a craft judgment, not a provenance rule: *"The current AI tools are prone to both errors and bias, and often produce dull, unoriginal writing... someone who writes for a living needs to constantly be thinking about the best way to express complex ideas in their own words."* ([niemanlab.org coverage](https://www.niemanlab.org/2023/03/wired-tells-readers-what-it-will-use-generative-ai-for-and-whats-off-limits/)) The Guardian moved in March 2026 from a near-ban to permitting narrow uses (alt text, transcription, document analysis) with mandatory disclosure and sign-off ([journalism.co.uk](https://www.journalism.co.uk/the-guardian-updates-its-ai-policies-training-trust-and-in-house-tools/)).

---

## 2. The invented-vocabulary problem, specifically

This was the owner's central named complaint, so it gets its own section.

**No single canonical term exists for this exact phenomenon** — inventing a Title-Case-style proper-noun label for a concept that has no established name and doesn't need one. But research converged on close matches from three independent directions, which is itself evidence the pattern is real and not idiosyncratic.

**The single closest match** comes from a crowd-sourced but well-specified catalogue, **tropes.fyi**, which has an entry literally titled *"Invented Concept Labels"* under the category "Tone":

> "AI clusters invented compound labels that sound analytical without being grounded. It appends abstract problem-nouns (paradox, trap, creep, divide, vacuum, inversion) to domain words — 'supervision paradox,' 'acceleration trap,' 'workload creep' — and uses them as if they're established, rigorously defined terms."
> "They function as rhetorical shorthand: name a thing, skip the argument. Multiple such labels in the same piece is a strong signal of AI slop."

This is the exact mechanism of "The proof loop": domain word + abstract noun, presented as though pre-existing and load-bearing, when it's neither. ([tropes.fyi/tropes-md](https://tropes.fyi/tropes-md); discussed further at [ossama.is/writing/tropes](https://ossama.is/writing/tropes))

A closely related, directly on-target source is a GitHub-hosted style skill (`avoid-ai-writing`) that names **"slot-fill profundity"** — formulas like *"X is the language of Y"* or *"X is the currency of Z"* that "manufacture a general law out of a specific observation" — and **"aphorism formulas"** like *"the architecture of trust"* that "turn an ordinary claim into something that sounds quotable without adding precision." Same source explicitly calls out AI-generated **headers**: a heading followed by a one-line restatement before real content starts, and generic scaffolding headers imposed regardless of fit. This is the closest match found to a header like "The proof loop" — a name for something the reader can't independently verify exists anywhere else in the system being described. ([github.com/conorbronsdon/avoid-ai-writing/blob/main/SKILL.md](https://github.com/conorbronsdon/avoid-ai-writing/blob/main/SKILL.md))

**Older, more rigorous, non-AI-specific concepts underneath it:**

- **Reification / "fallacy of misplaced concreteness"** (Alfred North Whitehead, *Science and the Modern World*, 1925) — treating a process or abstraction as a discrete, concrete thing, often signaled by capitalizing it. This is the most rigorous pre-existing name for the underlying cognitive move, though it predates LLMs by a century and isn't specific to naming. ([en.wikipedia.org/wiki/Reification_(fallacy)](https://en.wikipedia.org/wiki/Reification_(fallacy)))
- **Orwell's "meaningless words"** category in *Politics and the English Language* — words that "do not point to any discoverable object" and aren't even expected to by the reader — is the closest of his four categories, though none of his four is exactly "coining a proper-noun label for an unnamed thing."
- **Thought-terminating cliché** (Robert Jay Lifton, 1961) — a reductive, definitive-sounding phrase that ends argument rather than advancing it. Close in *function* (a label substitutes for reasoning) but not in *form* (it's about received clichés, not novel coinages).

**Two independent, concrete tests for when a coinage is earned**, arrived at from different disciplines:

1. **Scientific writing** (boscoh.com, "Jargon: The Art of Naming Things"): treat jargon like character names in short fiction — *"if you refer to something only twice in a paper, just spell out the whole thing"* rather than coin a term. Concepts referenced rarely should stay unnamed, "like secondary characters... where you don't give them a name." ([boscoh.com/science/jargon-the-art-of-naming-things.html](https://boscoh.com/science/jargon-the-art-of-naming-things.html))
2. **Product/UX writing** (Scott Kubie, "Fighting Proper Noun Feature Names"): *"Don't name things if you don't have to."* Distinguishes internal codenames (fine, never user-facing) from marketing names (earned only when reused often and adding real differentiation) from UI labels (should just describe function). Also flags the institutional cause: *"Marketing loves to name things, but marketing isn't design. It shouldn't be their call."* ([kubie.co/blog/fighting-feature-names](https://kubie.co/blog/fighting-feature-names/))

Both converge on the same operational rule, independently: **a name is earned by recurrence** — it needs to be referenced many times and needs a handle to avoid repeating a long description. **A concept used once or twice should stay unnamed and just be described plainly.** This is the single most actionable, checkable-in-principle rule this research surfaced for the owner's specific complaint (see §4 for how to check it mechanically — and its limits).

A useful adjacent heuristic, from a satirical but genuinely useful source (Vaguely Strategic's buzzword generator): *cut any sentence that would still make sense with the nouns swapped out.* If "the proof loop" would mean exactly the same thing swapped into an unrelated system, it isn't saying anything specific about *this* system, and wasn't earned.

**Honest gap:** there is no rigorous, citable "N-uses threshold" (e.g. "never coin a term used only once") codified in any authoritative style guide — the closest things are the two blog posts above. Treat the recurrence rule as strong practitioner consensus, not codified industry standard.

---

## 3. Pre-AI writing craft: the antidote was already written

The core finding here is that most of what's being (re)diagnosed as "AI voice" was already named and ruled against, decades before LLMs, by writers solving the same problem (bureaucratic, padded, self-important prose) for different reasons. This section extracts only rules stated specifically enough to be checkable or near-checkable; philosophy-only guidance is noted but not weighted heavily.

### 3.1 George Orwell, "Politics and the English Language" (1946)

Full text: [orwellfoundation.com](https://www.orwellfoundation.com/the-orwell-foundation/orwell/essays-and-other-works/politics-and-the-english-language/)

Four failure categories, then six rules:

- **Dying metaphors** (worn-out figures of speech with no vivid image) — *checkable* against a maintained ban-list.
- **Operators / verbal false limbs** (padding phrases replacing a single verb: "render inoperative," "militate against") plus passive-voice and "-ize" overuse — *partially checkable*.
- **Pretentious diction** ("phenomenon," "utilize," needless Latin) — *partially checkable* via word lists.
- **Meaningless words** ("romantic," abused political words) — **not checkable**; this is the category closest to invented-vocabulary padding, and it's explicitly the one Orwell says resists mechanical treatment.

The six rules, verbatim, with a checkability call on each:

1. "Never use a metaphor, simile, or other figure of speech which you are used to seeing in print." — partially checkable (needs a reference-corpus frequency check).
2. "Never use a long word where a short one will do." — **checkable** (syllable count vs. synonym dictionary).
3. "If it is possible to cut a word out, always cut it out." — partially checkable (specific filler phrases are listable; general judgment isn't).
4. "Never use the passive where you can use the active." — **checkable** (grammatically detectable, with caveats — see §4).
5. "Never use a foreign phrase, a scientific word, or a jargon word if you can think of an everyday English equivalent." — **checkable** against jargon word lists.
6. "Break any of these rules sooner than say anything outright barbarous." — **not checkable** — explicitly a judgment override, and worth keeping as the report's own closing principle too.

### 3.2 Strunk & White, The Elements of Style (1918 text is public domain: [gutenberg.org/files/37134/37134.txt](https://www.gutenberg.org/files/37134/37134.txt))

Most load-bearing, mechanically-checkable rules:

- **Rule 10 — use active voice.** Checkable.
- **Rule 11 — put statements in positive form.** *"Avoid tame, colorless, hesitating, non-committal language."* Partially checkable (negative-construction density is countable; "hesitating" needs judgment — but this is precisely the hedging problem, see §3.7 and §4).
- **Rule 12 — use definite, specific, concrete language.** *"Prefer the specific to the general, the definite to the vague, the concrete to the abstract."* Not directly checkable, but nominalization detection (words ending -tion/-ment/-ness replacing a verb) is a usable mechanical proxy — and this rule is the pre-AI name for exactly the "no Tuesday, no laundromat" concreteness gap Vollmer diagnoses in AI prose (§1.3).
- **Rule 13 — omit needless words.** *"A sentence should contain no unnecessary words, a paragraph no unnecessary sentences."* Partially checkable via a filler-phrase list ("the fact that," "in order to").
- **Rule 14 — avoid a succession of loose sentences** joined by "and"/"which," repeated one after another. Partially checkable (parseable pattern).

E.B. White's 1959 addition, "An Approach to Style," adds one of the single most mechanically useful rules in the whole canon: **flag qualifiers directly** — "very," "rather," "little," "pretty." This is a pure word list, maximally linter-friendly, and directly targets hedging.

### 3.3 William Zinsser, On Writing Well

Not public domain; short paraphrase only. Zinsser's operative test — *"is every word doing new work?"* — isn't itself checkable, but he operationalizes it into concrete, listable substitutions: "due to the fact that" → "because," "at the present time" → "now," throat-clearers like "it should be pointed out" flagged for deletion outright. His observation that redundant adverb-verb pairs ("blare loudly") restate the verb's own meaning is a useful, partially-checkable pattern (adverb-adjacent-to-verb is parseable; whether it's *redundant* needs a collocation check).

### 3.4 Elmore Leonard's 10 Rules

[Full list](https://fs.blog/elmore-leonard-10-rules-of-writing/) — fiction-specific but two rules generalize as genuinely mechanical: never use an adverb to modify "said" (checkable — flag adverb adjacent to a dialogue tag), and a **numeric budget** on exclamation points (2–3 per 100,000 words) — the single most literally mechanical threshold found anywhere in this research. His meta-rule, though, is the honest ceiling stated by the source itself: *"If it sounds like writing, I rewrite it."* — an explicit acknowledgment that the list resists full mechanization.

### 3.5 The Economist and Guardian/Observer style guides

Both maintain literal, alphabetical **substitution tables** (jargon → plain word) and **cliché ban-lists** — fully checkable, in the sense that a lookup table is checkable. The Economist's guide explicitly traces its own lineage to Orwell's six rules. Both guides' operative test for word choice — "would you use this word talking to a friend?" — is a human heuristic, not something a linter applies, but the resulting substitution tables it produces are directly usable as linter data.

### 3.6 Plain English Campaign and Ernest Gowers (The Complete Plain Words)

Plain English Campaign's guide gives the field's most literally mechanical single artifact: an **A–Z list of complex-word-to-plain-word substitutions** — pure lookup table. It also gives a sentence-length target (~15–20 words average) that is a numeric threshold, directly checkable. Gowers, endorsing the Fowler brothers' five "prefer" rules (familiar over far-fetched, concrete over abstract, single word over circumlocution, short over long, Saxon over Romance-derived) gives the field's oldest version of Orwell's rule 2 and 5, decades earlier.

### 3.7 Fowler's "elegant variation" — the direct pre-AI name for over-varying word choice

**This is likely the single most relevant classical concept to the AI-prose problem beyond invented vocabulary.** H.W. and F.G. Fowler coined "elegant variation" in *The King's English* (1906), refined in *A Dictionary of Modern English Usage* (1926): the fault of writers who avoid repeating a word by substituting an unmotivated synonym purely for variety, not clarity — e.g. the same fire described first as a "blaze," then a "conflagration." Fowler's diagnosis of the underlying motive maps almost exactly onto AI-prose critique: it happens when writers are "intent on expressing themselves prettily" rather than conveying meaning clearly, and he calls it "one of few literary faults so prevalent." His own worked example — a passage calling the same person "the Emperor," then "His Majesty," then "the Monarch" — leads readers to "wonder what the significance of the change is, only to conclude that there is none." ([en.wikipedia.org/wiki/Elegant_variation](https://en.wikipedia.org/wiki/Elegant_variation))

This is directly checkable in principle: detecting that two nearby noun phrases plausibly refer to the same real-world referent but use different lexemes is a well-defined task (coreference resolution + lexical-variation detection). Whether the variation is *unjustified* (Fowler's actual complaint, versus legitimate disambiguation) is the part that stays a judgment call.

### 3.8 Hemingway

No numbered rule list exists — his own stated principle (Paris Review, 1958) is the "iceberg theory": *"I always try to write on the principle of the iceberg... anything you know you can eliminate and it only strengthens your iceberg."* This is **not checkable** by any mechanism — there's no way to verify what a writer knows but omitted. Useful as philosophy, not as a rule.

### 3.9 Cross-source convergence — what a linter should actually contain

The rules that recur across nearly every classical source, confirmed independently by multiple traditions, are the highest-confidence candidates for mechanical enforcement:

1. Passive voice detection (Orwell, Strunk, Zinsser, Plain English Campaign)
2. Plain-word substitution lists (Orwell, Economist, Gowers, Plain English Campaign)
3. Cuttable filler-phrase lists (Orwell, Strunk, Zinsser, Gowers)
4. Jargon/foreign-phrase lists (Orwell, Economist, Plain English Campaign)
5. Cliché/dying-metaphor lists (Orwell, Guardian)
6. Qualifier/hedge-word lists — very, rather, quite, pretty, little (White, Zinsser) — **the single most purely mechanical rule in the whole canon**
7. Sentence-length ceilings (Plain English Campaign)
8. Elegant variation / unmotivated synonym-swap for a repeated referent (Fowler) — the direct historical precedent for AI prose's word-variation problem

The **least checkable**, converged on across every source as requiring taste: Orwell's "meaningless words," Strunk's "abstract vs concrete" in the general case, "one idea per sentence" (Zinsser, Plain English Campaign), and anything gated by "sparingly," "unnecessary," or Leonard's "if it sounds like writing."

---

## 4. What good technical-writing organizations actually mandate

### 4.1 GOV.UK Content Design — the most evidence-backed source found

GOV.UK is the strongest source in this entire research pass because its rules are tied to actual comprehension studies, not just editorial taste.

**Mandate:** write for a maximum reading age of 9, even for specialist audiences — not because the audience is unsophisticated, but for *recognition speed*: *"By age 9, most people have a core vocabulary of around 5,000 words they recognise by shape, not letter by letter. Adults still find these words easier to read than words they learned later."*

**Cited evidence:**
- National Literacy Trust data: 1 in 7 adults in England read at or below the literacy level of a 9–11 year old.
- A PNAS-adjacent legalese-comprehension study (Martínez, Mollica & Gibson) found plain-language contract versions preferred over legalese by legal professionals 80% of the time, and law-degree holders specifically 86% of the time; plain English was read 7% faster with 19% greater comprehension accuracy.
- A court-forms study (Center for Plain Language) found plain-language treatment raised correct understanding of a form's purpose from 23% to 70%.

This is the single strongest piece of evidence in this whole report that plain, unadorned writing isn't just aesthetically preferable — it measurably outperforms "sophisticated" writing on comprehension, **even among expert readers**.

**A published, literal banned-word list with plain replacements** ([guidance.publishing.service.gov.uk A-to-Z](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/style-guides/a-to-z-style-guide/)) — this maps almost one-to-one onto AI-prose tells: leverage → "influence"/"use"; utilise → "use"; facilitate → say specifically how you're helping; empower → "allow"; robust, streamline, tackle, transform, foster, incentivise, deploy, dialogue, overarching, progress-as-verb — all banned with concrete replacements.

**The critical nuance, directly relevant to the owner's jargon complaint:** GOV.UK explicitly does *not* equate plain English with jargon-stripping: *"Plain English does not mean removing specialist language. Words like assurance, gateway and even project have specific meanings... Use them when they are the right word. Do not swap them for vaguer alternatives."* The operative test is not "is this word technical" but **"is this word doing real work, and have you explained it."** This is the same test that resolves the "proof loop" complaint — the problem isn't that a system has technical concepts, it's that this particular label wasn't doing real work; it was standing in for an explanation rather than compressing one.

### 4.2 Google Developer Documentation Style Guide

The clearest, most actionable answer among style guides to "when is a coined term OK," given as an explicit four-step decision procedure ([developers.google.com/style/jargon](https://developers.google.com/style/jargon)):

1. Write around it — replace the term with plain description entirely.
2. Replace with a more specific, already-established term.
3. If used only once: define it plainly and put the jargon term in parentheses, or link to a definition — don't mint it as a standalone handle.
4. If used repeatedly: define briefly on first reference, then use it consistently.

Google's guide also mandates second person ("you," not "we"), active voice, present tense, and "put conditions before instructions, not after." Its banned/discouraged word list (blacklist/whitelist → denylist/allowlist, "and/or," "etc.," "allows you to" → "lets you") is smaller and more contextual than GOV.UK's, gated on audience familiarity rather than a flat ban.

### 4.3 Diátaxis (formerly the Divio Documentation System)

Not a style-rule source — a structural framework distinguishing four documentation purposes: **tutorials** (learning-oriented, action), **how-to guides** (goal-oriented, action), **reference** (information-oriented, knowledge), **explanation** (understanding-oriented, knowledge). Its core, non-mechanical but important claim: *conflating these on one page serves neither reader* — a tutorial that stops to explain theory "distracts attention and blocks learning" for someone following steps, and a reference page that editorializes undermines its job as a lookup tool. Explicitly relevant to a site with mixed content types: mixing "what this is" (explanation) with "how it works internally" (also explanation, but a different question) in the same section, under one invented label, is a structural cause of the "proof loop" problem — the label was trying to do explanation-work that belonged in prose, not a name. ([diataxis.fr](https://diataxis.fr/))

### 4.4 Stripe (observed practice, no single official public guide)

Third-party teardowns and direct inspection of docs.stripe.com show consistent patterns: developer-question-ordered information architecture (not org-chart-ordered), reference docs generated from the OpenAPI spec so they can't drift from the real system, and blunt, declarative sentences with minimal marketing language — e.g. *"The Stripe API doesn't support bulk updates. You can work on only one object per request."* Organizationally, a feature is reportedly not considered shipped until its documentation is written and reviewed — docs as part of "definition of done," not an afterthought. No cited evidence base; this is culturally/organizationally asserted, not research-backed, unlike GOV.UK.

### 4.5 Write the Docs

Notably, this is a **meta-source**, not a peer style authority: it doesn't publish its own prescriptive rules, and instead advises teams to adopt an existing guide (Google's, Microsoft's) rather than invent one. Its actual craft position is structural, not stylistic: *"if a feature isn't documented, it doesn't exist, and if documented incorrectly, it's broken"* — and documentation can't fix a badly designed system, so docs and the thing being documented should be developed together, not after the fact.

---

## 5. What's mechanically checkable, what isn't, and the honest ceiling

### 5.1 The tools that exist

- **Vale** ([vale.sh](https://vale.sh/)) — the closest thing to an industry-standard prose linter. Ships zero rules; everything comes from installable "Styles" (Google's, Microsoft's, write-good, GOV.UK's own — see below). Rule types: existence/substitution (word/phrase lists), occurrence caps, repetition, consistency (flags mixed spellings within a doc), conditional (acronym must be defined before use), capitalization pattern checks, readability formulas, and an embedded scripting language for anything not expressible declaratively. A real-world account (Contentsquare engineering) found enabling all of Google's bundled rules produced 673 flagged issues on real docs; they had to cut down to 102 to keep signal-to-noise usable — direct evidence that off-the-shelf rule bundles need curation, not blind adoption.
- **textlint**, **proselint**, **write-good**, **retext** — overlapping open-source linters. proselint's design philosophy is explicit: codify received wisdom from named authorities (Garner, Pinker, Twain, Leonard, Strunk, Orwell) rather than derive rules from scratch — the same sources reviewed in §3, already operationalized as regex/word-list checks.
- **alex** — a differently-scoped linter, for bias/inclusivity rather than style-craft, using the same word/phrase-substitution mechanism.
- **GOV.UK's own enforcement layer** is not bespoke — it's Vale, via [alphagov/gds-vale-styles](https://github.com/alphagov/gds-vale-styles), wrapped in CI by [alphagov/tech-docs-gem](https://github.com/alphagov/tech-docs-gem), explicitly configured to be **non-blocking** (exits 0 unless a real script exception) and non-auto-fixing. The evidence-based *content strategy* is human/editorial; only its *enforcement*, where mechanizable, is standard existence/substitution/readability checking — same ceiling as every other tool here.
- **ASD-STE100 / Boeing's Simplified English Checker** — the strongest real-world case of high mechanical enforcement, but only because the domain is deliberately shrunk first: a closed ~900-word vocabulary, one part-of-speech/meaning per word, and hard sentence-length ceilings, checked by a genuine syntactic parser (400+ grammar rules), not just regex. Even so, Boeing's own documentation states: *"no language checker can guarantee full compliance with STE, because the goal of STE is clarity — only human writers can judge whether a sentence or paragraph makes good sense."* The higher ceiling here isn't better NLP, it's a smaller input space — not transferable to open, general, or analytical prose.
- **modeltell** ([github.com/thirdshiftlab/modeltell](https://github.com/thirdshiftlab/modeltell)) — the one tool found that specifically targets "sounds like LLM output" as a structural/statistical property: sentence-length variance, opener/closer classification, bullet-to-prose ratio, plus cross-model stylometric fingerprinting (TF-IDF, Burrows's Delta). Its own documentation is admirably honest about its ceiling: explicitly **"not an AI detector,"** reports only **~71% micro-precision** under manual validation, and at least one tracked construction performs at ~0% accuracy. Framing: measures "model style entangled with task style," not provenance.

### 5.2 Burstiness / sentence-length variance — is this real?

Yes, genuinely measurable and genuinely correlated, with real caveats. GPT-4o-style output has been shown to cluster ~85% of sentences in a narrow 15–28 word band, while human writing in the same genre spans 4–55+ words with no strong central cluster. A 2025 stylometric study in *Humanities and Social Sciences Communications* (Nature portfolio) independently found lower burstiness, lower lexical diversity, and more symmetrical narrative structure in AI-generated creative writing across corpora. This is the empirical backing for the "uniform sentence rhythm" tell named repeatedly in §1.

But two caveats matter: **GPTZero itself stopped relying on perplexity/burstiness alone as of autumn 2023**, moving to a multi-signal architecture — an implicit admission raw variance thresholds are gameable. And burstiness is documented to be naturally lower in non-native-English writing, meaning a burstiness gate risks penalizing a genuine human-authorship signature that correlates with something other than AI-authorship. Treat it as a weak, second-order signal, not a gate.

### 5.3 The honest three-tier ceiling

**Fully checkable, low false-positive rate:**
- Spelling
- Sentence length / word count against a hard limit
- Readability formulas (deterministic arithmetic)
- Banned/approved word or phrase lists, when curated (not exhaustive)
- Repeated words in close proximity
- Literal hedge/qualifier-word lists (very, really, quite, rather) — the single cleanest mechanical rule across the entire research pass, converging from White (§3.2), Zinsser (§3.3), and every modern linter
- Consistency of competing spellings/terms within one document

**Partially checkable — real, documented false-positive problems:**
- Passive voice — every open-source tool surveyed uses "be-verb + participle-shaped word" pattern matching, not true parsing, and documented failure modes include stative passives ("the door is locked") and predicate adjectives ("she was tired"). Even Yoast's own documentation of this exact problem concludes: *"because of the irregularities in human language, it will never be possible to get our analysis 100% right."*
- Cliché detection — closed-list lookup is high-precision/low-recall (only catches what's enumerated).
- Jargon detection — can't mechanically distinguish "necessary domain term" from "padding" without world/audience knowledge (this is precisely why GOV.UK's rule — is the word doing real work? — is a human judgment call, not a linter rule).
- Hedging-as-padding vs. hedging-as-warranted-uncertainty — the token is checkable, whether it's *justified* isn't.
- Sentence-length variance/burstiness — real and measurable, but explicitly non-definitive even by its own tool's author, and gameable under adversarial awareness.
- Elegant variation (Fowler, §3.7) — detecting candidate same-referent lexical swaps is a defined NLP task (coreference + lexical-variation matching); judging whether the swap was *unjustified* stays human.

**Not mechanically checkable at all — no tool surveyed claims otherwise:**
- Whether a sentence contains a genuine insight versus filler that merely sounds smart
- Whether a coined term is earned versus gratuitous (the recurrence heuristic in §2 is a human test, not a linter rule — a linter can *count* occurrences of a Title Case phrase, which is a genuinely usable proxy, but can't judge whether the concept it names actually exists in the system being described)
- Whether a paragraph has a real point of view versus hedged non-committal prose
- Cross-paragraph rhythm/monotony (as distinct from within-document sentence-length variance, which is the one sub-piece that's measurable)
- Whether jargon is the *right* jargon for a specific audience

The pattern across every serious tool-maker surveyed (Vale's own engineering writeups, Yoast, Boeing's STE documentation, modeltell's own README) is the same: **every one explicitly disclaims that their tool replaces editorial judgment.** The mechanical ceiling raises a floor; it does not replace taste.

---

## 6. Does model size or prompting help? ("Can we get better by getting dumber?")

**Short answer: not proven, and the honest evidence points away from size as the operative variable.** The weight of evidence favors "it's a training-target effect (RLHF alignment + system-prompt persona), not a raw-capability/size effect" — meaning a small model heavily RLHF'd the same way would plausibly carry the same tells, and prompting/system-instruction control is the better-evidenced lever than downgrading model size. This is the most load-bearing finding in this report for a practical recommendation, so precision on confidence level matters here more than anywhere else in the report.

**The mechanism, at the level of a controlled study.** Kirk et al., *"Understanding the Effects of RLHF on LLM Generalisation and Diversity"* (arXiv 2310.06452, ICLR 2024), directly compared SFT vs. reward-model/Best-of-N vs. full RLHF/PPO across two base models (LLaMA-7B, OPT) and two tasks. Finding: RLHF generalizes better out-of-distribution than SFT, but **significantly reduces output diversity** across syntactic, semantic, and logical measures, both per-input and across-input ("mode collapse"). This is a real, controlled, peer-reviewed finding — not anecdote. The proposed mechanism (independently noted across several cited papers: Khalifa et al. 2021, Perez et al. 2022, Go et al. 2023, Glaese et al. 2022) is that RLHF's reverse-KL-divergence optimization is *mode-seeking*: it converges the policy onto a narrow high-reward region of output space rather than preserving the base model's broader distribution. Caveat: this study measures diversity on summarization/instruction-following, not specifically the named prose tells (em dashes, "not just X, it's Y," invented labels) — it establishes the mechanism class, not a direct measurement of slop vocabulary.

**Direct evidence for the "get better by getting dumber" claim, and its limits.** The most directly relevant paper found, Milička, Marklová & Cvrček, *"Benchmark of stylistic variation in LLM-generated texts"* (arXiv 2509.10179, preprint, not peer-reviewed), used Biber's multidimensional register-analysis framework and found **base models often scored as more stylistically human-like than their instruction-tuned counterparts** — e.g. davinci-002 and LLaMA 3.1 base produced more human-like English text by this measure. This is real, if preliminary, support for the base-model claim. But it comes with real caveats: it failed to replicate in Czech (base models there often produced incoherent text), it didn't hold on every stylistic dimension even in English, and — the more important finding for this report's purposes — **prompting shifted output style more than model choice did**: "GPT-3.5 turbo with the long [ChatGPT] system prompt clusters more with newer models GPT-4 turbo, GPT-4, and GPT-4o than with the original GPT-3.5 turbo [under a minimal prompt]." That single result is the strongest piece of evidence in this whole research pass that **persona/system-prompt conditioning moves style more than model generation or size does.**

**Evidence against a simple "smaller/older is less sloppy" law.** A cited storytelling-quality comparison found GPT-4 substantially outscored GPT-3.5 on richness and coherence, but **the same formulaic structural template that defines "AI-slop" was present unchanged in both** — the smaller/older model wasn't less formulaic, just also lower quality on other axes. Separately, GPT-4 has been measured with *higher* lexical diversity than GPT-3.5 in some comparisons, the opposite direction the "dumber is better" hypothesis would predict. No study found isolates model size from RLHF intensity — every real-world comparison confounds the two (there's no clean experiment holding one constant while varying the other), so claims in either direction go beyond what's been measured.

**Specific tells, measured.** The Washington Post analyzed 328,744 real ChatGPT messages and found the "it's not just X, it's Y" construction (or close variants) in roughly 6% of all messages in one month — a real large-N prevalence measurement, the strongest "this is genuinely common, not just a vibe" evidence found for any single tell in this report. Causal attribution (RLHF vs. pretraining frequency vs. reward-model idiosyncrasy) remains speculative. On em dashes specifically, one practitioner analysis (Sean Goedecke, [seangoedecke.com/em-dashes](https://www.seangoedecke.com/em-dashes/)) tested and explicitly rejected the popular "RLHF workforce speaks Nigerian English, which uses more em dashes" theory by directly measuring Nigerian-English em-dash rate (0.022%/word — *lower* than general English's 0.25–0.275%), and instead points to a training-data shift (pre-1950s digitized books, which run ~30% higher em-dash density) as the likelier cause — self-labeled as speculative by its own author, but a genuine measurement-based rebuttal of a specific competing theory, which is more rigor than most claims in this space get.

**Prompting works, but the evidence is practitioner-anecdotal, not measured.** Published "anti-slop" system prompts exist (banned-word/construction lists — see Will Francis's guide, [willfrancis.com/how-to-stop-claude-writing-like-an-ai](https://willfrancis.com/how-to-stop-claude-writing-like-an-ai/)) and Every.to's 400-rule Claude-project system (§1.4) is the clearest real production example. No source found presents a controlled before/after or blind-evaluation measurement of these prompts' effectiveness — it's consistent practitioner assertion, not data. One comparison found reliability varies by model: Claude and GPT-family models reportedly follow "no em dash"-style instructions fairly consistently within a system prompt; Gemini was reported to revert to em dashes later in long outputs, suggesting some models apply such instructions as a shallow filter rather than a trained default. Treat this whole category as PLAUSIBLE-BUT-ANECDOTAL.

**Anthropic-specific note.** Claude ships a user-facing writing-style customization feature (concise/formal/explanatory modes, author-mirroring) — a product acknowledgment that the default voice is one style among many, not the only correct one. The Claude Constitution (as of Jan 2026, per public documentation) applies a "dual newspaper test" partly aimed at *overcaution/hedging*, i.e. Anthropic has separately identified and tried to counter over-hedged output at the values-document level. No Anthropic-published research was found tracing specific prose tics (em dashes, invented labels, "not just X, it's Y") to their own RLHF pipeline — this is a real gap in available evidence, not filled by inference here.

**Confidence summary, precisely stated:**
- RLHF reduces output diversity via a mode-seeking optimization mechanism — PROVEN at the level of one solid controlled study (Kirk et al.), not yet replicated on the specific prose-tell vocabulary named in §1.
- Base/non-RLHF models score more human-like on a formal stylometric register framework — PLAUSIBLE, real but preliminary evidence (one unreviewed preprint, partial replication even within it).
- Prompting/system-instruction conditioning shifts style more than model choice/size — the best-supported *practical* claim in this section, backed by the Milička et al. clustering result plus consistent (if unmeasured) practitioner experience.
- Smaller/older model size *alone*, independent of RLHF intensity, reduces slop — UNSUPPORTED. No experiment found isolates the two variables, and at least one comparison (the formulaic-structure-persists-across-GPT-3.5-to-GPT-4 finding) argues against size being the operative variable at all.

**Practical recommendation following from this:** don't downgrade to an older/smaller model as an anti-slop strategy — there's no clean evidence it works, and it costs real capability. Instead, treat this as a training-target problem to counter with an explicit system prompt: a condensed banned-phrase/construction list plus the recurrence rule from §2, in the spirit of Every.to's approach, is the theoretically consistent and better-evidenced lever.

---

## 7. Recommended system for producing non-slop copy at scale

This synthesizes §1–6 into a working process, sized for a time-constrained owner who cannot hand-edit every sentence. It deliberately does not propose a linter that claims to catch everything — §5 established that ceiling honestly, and a system that overclaims will erode trust the first time it lets slop through or flags something fine.

**Layer 1 — a maintained, curated word/phrase ban-list, enforced by Vale (not a bespoke tool).** Combine: the classical-craft substitution lists from §3 (Orwell's jargon/foreign-phrase rule, Zinsser's filler phrases, Economist/Guardian/GOV.UK's word-swap tables), the modern AI-tell vocabulary from §1.2 (delve, tapestry, underscore, intricate, meticulous, realm, pivotal, showcasing, testament, boast — the peer-reviewed 21-word list plus Wikipedia's catalogue), and White's qualifier list (very, really, quite, rather). This is Contentsquare's lesson (§5.1): start from an existing bundle (Google's Vale style, or build from GOV.UK's published A-to-Z list, which is Vale-compatible already via alphagov/gds-vale-styles) and *cut it down* to what's actually high-signal for this site's voice, rather than turning on everything and drowning in false positives. Re-review the list periodically — §1.2's finding that "delve" usage dropped once it became famous means today's list will need refreshing as tells shift.

**Layer 2 — structural checks Vale can also do:** sentence-length ceiling (borrow GOV.UK's ~15-20 word target, adjusted for a technical audience), passive-voice flags (accept the false-positive rate — Yoast's own conclusion in §5.3 — and treat these as prompts for a human look, not auto-fixes), repeated-word-in-proximity, and Title-Case-phrase detection as a proxy trigger for the invented-vocabulary check in Layer 3 (a linter can count how many times a Title Case noun phrase like "The Proof Loop" appears in the corpus outside its own section — near-zero recurrence is the mechanical proxy for "this wasn't earned," per the recurrence rule in §2).

**Layer 3 — a human (or a genuinely adversarial second model pass) check for what Layer 1–2 structurally cannot catch,** run as a short, explicit checklist rather than open-ended "does this feel AI-written":
- Does every Title Case or quoted "concept name" recur elsewhere, or is it used once? (Apply the boscoh.com/Kubie recurrence test from §2 directly — if used once, replace it with a plain description.)
- Does every heading correspond to something a reader could independently verify exists in the real system, or does it sound authoritative while describing a one-off idea? (Direct check against the tropes.fyi "Invented Concept Labels" / "slot-fill profundity" pattern from §2.)
- Does any paragraph contain the "not just X, it's Y" (paradiastole) or rule-of-three construction more than once? A single instance is a legitimate rhetorical figure; repetition is the tell (§1.3's Miessler analysis).
- Is there a concrete, checkable particular in each section (a real number, a real named thing, a real constraint) — or could this paragraph be dropped into an unrelated product with no loss of meaning (the swap-the-nouns test, §2)? This operationalizes Vollmer's "be specific, be strange, be where you actually are" (§1.3) as something a reviewer can actually apply while proofing.
- Does any sentence use a different word for something already named earlier in the piece, for no reason other than variety? (Fowler's elegant-variation check, §3.7 — genuinely worth a manual pass since it's only partially automatable.)

**Layer 4 — the prompting lever, applied upstream of all the above.** Given §6's finding that the tell is plausibly an RLHF/alignment artifact rather than a raw-capability one, put a condensed version of Layers 1–3 directly into the system prompt or drafting instructions for any AI-assisted first draft — banned-phrase list, the recurrence rule for naming things, an explicit instruction against inventing labels for one-off ideas, and 2-3 concrete worked examples of the "not just X, it's Y" and "slot-fill profundity" failure modes to avoid. This mirrors Every.to's actual production system (§1.4) — the most directly comparable real-world precedent found for "produce non-slop copy at scale under time pressure" — and is consistent with treating the tell as trainable-around rather than requiring a downgrade to a smaller or older model of unverified tuning provenance.

**What this system does not solve, stated plainly per the brief's instruction to be honest about limits:** whether a coined term is *earned*, whether a sentence has *a real point of view*, and whether the writing has *rhythm across paragraphs* (as opposed to within a single sentence) remain judgment calls no tool in this research claims to automate. Kate Lee and Eleanor Warnock's own conclusion at Every.to, after building a 400-rule guide, stands as the correct final word here: *"Writing is still hard. Don't let AI make you think it's easy."* The system above is a floor-raiser that catches the mechanical 60-70% (word choice, sentence structure, obvious tells) so the owner's limited editing time goes to the 30-40% that's irreducibly judgment — coined-term earning, structural honesty about what a section is actually named after, and whether each section says something a swapped-in unrelated system couldn't also claim.

---

## Sourcing notes and contested claims

- The "goyslop" 4chan etymology for "AI slop" (Etymology Nerd Substack) is a single-source claim, not cross-verified.
- Several high-authority mainstream sources (Washington Post and Rolling Stone em-dash pieces, Ted Chiang's New Yorker essay, Stuart Heritage's Guardian piece, Sam Kriss's NYT Magazine piece, Blake Stockton's "negation structure" coinage, Daniel Miessler's rhetorical-figures essay, the Adirondack Explorer "manufactured profundity" piece) were blocked by paywalls, TLS errors, or rate limits during research and are cited above via search-engine summaries only, not primary-text fetch. These are flagged inline where used; treat direct quotes from them as needing re-verification (e.g. via the Wayback Machine) before use in any published piece.
- The RLHF-causes-lexical-drift finding (Juzek & Ward) is a single study (Feb 2025, COLING), not yet broadly replicated — treated as the strongest available evidence, not settled science.
- The base-model-writes-more-human-like-prose finding (Milička, Marklová & Cvrček, arXiv 2509.10179) is an unreviewed preprint, and its own English-language finding didn't replicate in the Czech-language portion of the same study — treat as preliminary, not settled.
- No study found directly isolates model size from RLHF/alignment intensity as separate variables (e.g., a large base model vs. a small heavily-RLHF'd model, judged blind on "AI-sounding-ness") — that experiment does not appear to exist in the literature surfaced by this research.
- tropes.fyi is a fresh (2026), community-catalogued source, not an academic or long-established editorial authority — the best current descriptive match for the invented-vocabulary phenomenon, not a canonical term.
- No single authoritative style guide codifies an "N-uses threshold" for when a coined term becomes justified — the recurrence rule in §2 is strong convergent practitioner consensus from two independent disciplines, not an industry standard.
