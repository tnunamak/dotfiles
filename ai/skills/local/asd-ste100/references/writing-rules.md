# ASD-STE100 Part 1 — Writing rules (condensed)

Source: ASD-STE100 Simplified Technical English, Issue 9 (2025-01-15), Part 1. This is a
condensed paraphrase for LLM/agent use, not a verbatim reproduction. The authoritative PDF
(copyright ASD — Aerospace, Security and Defence Industries Association of Europe) is at
`references/source/asd-ste100-issue-9.pdf` for the full text, examples, and dictionary.

STE was built for aerospace maintenance manuals, written for readers who may not be native
English speakers. Two effects fall out of that origin and matter for prose that isn't a
maintenance manual: (1) the discipline generalizes well to any "written by an LLM, read by
a tired human" situation — short sentences, one topic per sentence, no buried conditionals;
(2) some rules are aerospace-specific plumbing (warning/caution taxonomy, parts catalogs,
technical-noun categories) and should be applied as *inspiration*, not literally, outside
that domain.

## Section 1 — Words

- **1.1** Use only words that are approved in the dictionary, or that qualify as a technical
  noun (1.5) or technical verb (1.12).
- **1.2** Use approved words only as the part of speech the dictionary specifies for them.
- **1.3** Use approved words only with their approved (often narrower-than-normal) meaning.
  Non-STE: *Follow the safety instructions.* → STE: *Obey the safety instructions.*
  ("follow" only approved to mean "come after, go after.")
- **1.4** Use only the approved forms of verbs and adjectives (the dictionary lists them:
  e.g. REMOVE/REMOVES/REMOVED; SLOW/SLOWER/SLOWEST). Don't invent other inflections.
- **1.5** Technical nouns (parts, systems, tools, materials — see the 22 categories in the
  full spec) don't live in the dictionary; use them if they fit one of those categories or
  your own domain glossary.
- **1.6** A word absent from the dictionary is usable only as a technical noun/part of a
  technical noun, never as ordinary vocabulary. ("base" isn't approved as a general word,
  but is fine as a technical noun: *The base of the triangle is 5 cm.*)
- **1.7** Never use a technical noun as a verb. Non-STE: *Oil the steel surfaces.* → STE:
  *Apply oil to the steel surfaces.*
- **1.8** Prefer the technical noun already established in your company/industry/domain
  glossary over inventing a new one.
- **1.9** When you must coin a technical noun, pick the short, easy-to-understand option.
- **1.10** Don't use regional, slang, or jargon words as technical nouns.
- **1.11** Don't use different technical nouns for the same referent — pick one term and
  hold it for the whole document (no elegant variation).
- **1.12** Technical verbs (domain-specific actions: drill, braze, intubate, taxi, waive)
  are usable if they fit a recognized technical-verb category — but prefer an approved
  dictionary verb when one already says the same thing.
- **1.13** Never use a technical verb as a noun.
- **1.14** Use American English spelling (per Merriam-Webster) unless a house style says
  otherwise. Don't silently "fix" spelling inside quoted text (UI strings, labels).

## Section 2 — Multi-word nouns

- **2.1** Keep noun strings to 3 words or fewer. Long noun-stacks ("runway light connection
  resistance calibration") are ambiguous — break them up with prepositions ("calibration of
  the resistance of the runway light connection").
- **2.2** If a technical noun genuinely needs more than 3 words, spell it out in full once,
  then either (a) define and reuse a shorter form, or (b) hyphenate the directly-related
  words so the hyphenated unit counts as one word.

## Section 3 — Verbs

- **3.1** Use only the verb forms the dictionary lists for that verb.
- **3.2** Only six verb forms are approved: infinitive, imperative, simple present, simple
  past, simple future, and past participle used as an adjective. No perfect or progressive
  tenses.
- **3.3** Past participles are for describing state/condition as adjectives (*the
  disassembled unit*), not for building passive voice.
- **3.4** No auxiliary-verb constructions ("has been," "can be," "is to be" + past
  participle). Non-STE: *The volume control can be adjusted.* → STE: *You can adjust the
  volume control.*
- **3.5** "-ing" forms are only for technical nouns (*Cleaning*, *Troubleshooting*) or noun
  modifiers (*welding torch*) — not as verbs, gerund clauses, or dangling modifiers.
  Non-STE: *When you are doing this procedure...* → STE: *When you do this procedure...*
- **3.6** Prefer active voice always. In descriptive text, passive is allowed only when the
  agent truly is unknown. Test: ask "by whom/what?" — if answerable, rewrite active.
- **3.7** Use a verb to express the action, not a noun standing in for one. Non-STE: *The
  ohmmeter gives an indication of 450 ohms.* → STE: *The ohmmeter shows 450 ohms.*

## Section 4 — Sentences

- **4.1** Short, clear sentences: procedures get direct imperative steps; descriptive text
  gets one subject per sentence, no imperatives, information introduced gradually.
- **4.2** Never omit words to shorten a sentence, and never use contractions. Non-STE:
  *Rotary switch to INPUT.* → STE: *Set the rotary switch to INPUT.*
- **4.3** Use vertical lists for complex content: colon before the list, consistent item
  markers, capitalize each item's first word, period only on full-sentence items (always on
  the last item), never a comma/semicolon at an item's end.
- **4.4** Connect related sentences with approved connecting words/phrases only: "and,"
  "but," "then," "thus," "as a result," "at the same time."
- **4.5** Use an article ("the/a/an") or demonstrative ("this/these") before a noun when it
  would otherwise be ambiguous — but don't force one before a general/abstract noun, and
  don't put "the" directly before a noun immediately followed by an alphanumeric ID (*Tag
  circuit breaker 36L7*, not *Tag the circuit breaker 36L7*).

## Section 5 — Procedural writing

- **5.1** Max 20 words per sentence (warnings/cautions included; notes get 25 — see 5.5).
- **5.2** One instruction per sentence, unless two actions are genuinely simultaneous or one
  is an immediate, inseparable result of the other.
- **5.3** Write instructions in the imperative. Non-STE: *The test can be continued.* → STE:
  *Continue the test.* Don't prefix imperatives with "must" unless safety-critical.
- **5.4** If the reader needs a condition before acting, state the condition first, then a
  comma, then the command. *When the light comes on, set the switch to NORMAL* — not the
  reverse (comma placement changes meaning here).
- **5.5** Notes give information only, never instructions, never limits/tolerances/results
  (those belong directly in the step). Max 25 words. Sanity check: the procedure must still
  work correctly if you delete every note.

## Section 6 — Descriptive writing

- **6.1** Give information gradually — one subject per sentence, don't front-load.
- **6.2** Reuse the same key words/phrases across sentences and paragraphs rather than
  varying vocabulary; repetition creates a traceable logical chain (this directly
  contradicts "elegant variation" instincts and most style guides — that's intentional).
- **6.3** Max 25 words per sentence in descriptive text.
- **6.4** Each paragraph opens with a topic sentence naming its subject.
- **6.5** One topic per paragraph — a reader should be able to reconstruct the outline from
  topic sentences alone.
- **6.6** Max 6 sentences per paragraph; split if longer.

## Section 7 — Safety instructions

Definitions: a **warning** = risk of injury or death; a **caution** = risk of damage to
objects/equipment only. (Other label sets like "danger"/"notice" are fine if rules 7.1–7.3
are still met.)

- **7.1** Pick the label that matches the actual risk level from real risk analysis — don't
  under-label an injury/death risk as a mere caution.
- **7.2** Open the safety instruction with the command or condition immediately — no
  preamble before the actionable content.
- **7.3** Always state the consequence/risk so the reader understands *why* it matters.

## Section 8 — Punctuation and word count

- **8.1** All standard punctuation is fine except the semicolon — split into two sentences
  instead.
- **8.2** Use hyphens to bind directly-related words: multi-word adjectives before a noun
  (*low-altitude flight*), two-word number/fractions (*forty-seven*), letter/number + noun
  shape descriptors (*T-shirt*), compound verbs (*die-cast*), vowel-adjacent
  prefix+root (*pre-amplifier*).
- **8.3** Parentheses are fine for: illustration/text references, item IDs, work-step
  numbers, abbreviations, singular/plural pairs (*component(s)*), brief explanations, and
  alternatives (*left (right) access panel*).
- **8.4** In a vertical list, a colon counts like a period for word-count purposes; the
  count then restarts per list item.
- **8.5** Parenthetical text counts as one word in the sentence containing it, but starts
  its own separate word count too.
- **8.6** Each of these counts as exactly one word: numbers; number+unit (*10 °C*);
  abbreviations (*NASA*, *a.m.*); alphanumeric IDs (*36L7*); quoted text/formulas; unalterable
  titles/labels/placards; proper nouns of people/orgs/geopolitical entities.
- **8.7** Hyphenated words count as one word.

## Section 9 — Writing practices

- **9.1** Don't do mechanical word-for-word substitution when it breaks grammar, produces
  nonsense, changes meaning, or the word to replace isn't even in the dictionary — rebuild
  the sentence around the intended meaning instead.
- **9.2** Use each approved word's *actual* approved sense — many have narrower meanings
  than everyday English. Non-STE: *Wear protective clothing.* (wrong sense) → STE: *Use
  protective clothing.*
- **9.3** No phrasal verbs (*put out*, *carry out* as loose combos) — their meaning isn't
  compositional from the parts, which breaks predictability even if both words are approved
  individually. Non-STE: *put out the fire* → STE: *extinguish the fire.*
- **9.4** Once you pick a phrasing for a recurring situation, reuse it verbatim every time —
  consistency over variety, same principle as 6.2 and 1.11.

## General Recommendations (GR-1 – GR-8) — advisory, not hard gates

- **GR-1 (that):** Keep "that" after verbs like "make sure," "show," "recommend" even
  though native speakers drop it in speech — the explicit clause boundary helps
  non-native readers and machine translation.
- **GR-2 (with):** "With" is genuinely ambiguous (association vs. instrument vs. accompaniment).
  Reread any sentence using it, or better, state the action verb directly instead of
  routing through "with."
- **GR-3 (pronouns):** Use only dictionary-approved pronouns; if a pronoun could resolve to
  more than one antecedent, name the noun instead.
- **GR-4 (this):** If "this" could refer to more than one preceding thing, restate the
  actual referent.
- **GR-5 (false friends):** Watch for words that look like a cognate in another language but
  mean something different in English (e.g. "disposition" ≠ instruction).
- **GR-6 (Latin abbreviations):** Avoid "e.g.," "i.e.," "etc." — spell out ("for example,"
  "that is") or cut.
- **GR-7 (inclusive language):** No gendered pronouns/nouns ("he," "man") unless the context
  genuinely requires it (e.g. medical text).
- **GR-8 (possessive):** The Saxon genitive ('s) is fine only when unambiguous; when in
  doubt, rephrase ("the manufacturer's instructions" is fine; if it's unclear, restructure).

## What this means for LLM-generated prose (not in the original spec)

STE was written for maintenance manuals, not blog posts or PR descriptions — apply the
*spirit*, not the aerospace-specific plumbing (technical-noun categories, warning/caution
taxonomy, the dictionary's narrow domain vocabulary). The load-bearing, domain-agnostic core
is: short sentences (≤20-25 words), one idea per sentence, active voice, imperative for
instructions, no buried conditionals, no elegant variation (reuse the same term for the same
thing), no phrasal verbs, no hedging filler. That's most of what makes LLM output read as
"written by a committee" — STE is a 40-year-old, battle-tested antidote to exactly that.
