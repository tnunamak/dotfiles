---
title: "RFC 8174 makes blanket lowercase-keyword linting wrong; the only defensible mechanical rule is lowercase key words that govern a protocol role"
date: 2026-09-03
topic: writing-craft
tags: [specs, linting, rfc-2119, rfc-8174, style-guides, prose-gate]
status: verified
sources: [rfc-8174, rfc-7322, w3c-mos, rfc-8126]
source_session: 6f340ae9-d2c5-40e4-97e7-8a89c1cdc145
---

## CLAIMS

- RFC 8174 is a 4-page Best Current Practice that formally `Updates: 2119`; the two together are BCP 14. It states the RFC 2119 key words "have the meanings specified herein only when they are in all capitals", and that when not capitalized "they have their normal English meanings and are not affected by this document". [rfc-8174]
- Therefore a linter rule that flags every lowercase `must`/`should`/`may` in a specification contradicts the standard it cites: lowercase is explicitly correct, ordinary English. Measured on PDP-Connect/pdpp's root specs, a blanket rule fires ~40 times in `spec-core.md` alone, nearly all on legitimate prose ("may revoke", "must not be conflated", "roles may be co-located"). [rfc-8174]
- Scoping the rule to a named protocol role alone is NOT enough. Restricted to any key word after a role (`the AS must`, `resource server may`), it still yields 10 findings of which only 1 is real — the 9 false positives are overwhelmingly descriptive `may` in glossary rows and capability tables ("An immutable consent artifact specifying what data a client may access"). [own-measurement]
- The rule that reaches 1/1 precision needs a SECOND narrowing: obligation verbs only (`must`, `shall`), dropping `may` entirely. Lowercase `may` after a role states a possibility rather than granting a permission, so it is almost never a miscased keyword. The single surviving finding is `spec-core.md:1056`, "This section is normative: a compliant resource server must implement this interface" — normative by declaration, non-normative by RFC 8174. [own-measurement]
- The W3C Manual of Style supplies the direct authority for "no RFC 2119 key words inside notes": "Figures, examples and notes are assumed to always be informative" and "If some sections are informative, say so at the start of each section, and do not use RFC 2119 keywords in those sections." [w3c-mos]
- The W3C Manual of Style instructs authors to "Break long sentences" under Grammar but sets no numeric limit; ASD-STE100 rule 3.2 caps descriptive sentences at 25 words. A 40-word threshold is therefore a chosen operating point between the two, not a cited constant. [w3c-mos]
- RFC 7322 §2 grounds consistency-class rules (uniform wrapping, no duplicated paragraphs): the RFC Editor strives for consistency within the document, a cluster of documents, and the RFC series on the subject. §3.6 requires abbreviations be expanded on first use; §3.5 requires cross-references use section numbers rather than page numbers. [rfc-7322]
- RFC 8126 §2.2 lists what a registry section must document: registry name, registration policy, required information for registrations, size/format/syntax, and initial assignments. This is judgeable but not regex-detectable, so it belongs in a judged rubric rather than a mechanical linter. [rfc-8126]
- Hard-wrap rejoining is the only one of these rules that is safely auto-fixable. Verified on pdpp's five wrapped specs: after `--fix`, each file is byte-identical to the original under whitespace normalization (`tr -s ' \n' ' '`), with code-fence, table-row and heading counts unchanged. The other five rules each require a decision about meaning. [own-measurement]
- `filler` scores 0 on the entire corpus. A prose-gate rule that fires nowhere is still worth shipping as a ratchet, but it should be reported as a ratchet rather than counted as a finding source. [own-measurement]

## SOURCES

**rfc-8174**
URL: https://www.rfc-editor.org/rfc/rfc8174.html
Accessed: 2026-09-03
Metadata: Status "Best Current Practice", "Updates: 2119", "BCP: 14", 4 pages.
Quote: "The words have the meanings specified herein only when they are in all capitals." / "When these words are not capitalized, they have their normal English meanings and are not affected by this document."

**rfc-7322**
URL: https://www.rfc-editor.org/rfc/rfc7322.html
Accessed: 2026-09-03
Quote: §2 — consistency "within: a. the document, b. a cluster of documents, and c. the series of RFCs on the subject matter." §3.6 — "Abbreviations should be expanded in document titles and upon first use in the document." §3.5 — "Cross-references within the body of the memo and to other RFCs must use section numbers rather than page numbers."

**w3c-mos**
URL: https://www.w3.org/guide/manual-of-style/
Accessed: 2026-09-03
Quote: "Figures, examples and notes are assumed to always be informative." / "If some sections are informative, say so at the start of each section, and do not use RFC 2119 keywords in those sections." / Grammar: "Break long sentences."

**rfc-8126**
URL: https://www.rfc-editor.org/rfc/rfc8126.html
Accessed: 2026-09-03
Quote: §2.2 "Documentation Requirements for Registries" — registry name, registration policy, required information for registrations, size/format/syntax, initial assignments and reservations.

**own-measurement**
URL: PDP-Connect/pdpp @ origin/main (498818a9b), `scripts/spec-prose-lint.mjs`
Accessed: 2026-09-03
Quote: Final ruleset, 383 findings across 10 root spec files: hard-wrap 336, long-sentence 41, keyword-in-note 3, duplicate-paragraph 2, lowercase-normative 1, filler 0. Intermediate ruleset (role-scoped keyword rule including `may`) gave 392, with lowercase-normative at 10 — 9 of them false positives.

## SYNTHESIS

The generalizable lesson for building any prose gate over a standards document: the citation is not decoration, it constrains the rule. Two of the six rules I first sketched from the task description would have contradicted their own cited authority if implemented literally — the lowercase-keyword rule most obviously, because RFC 8174 exists specifically to say lowercase is not a keyword. Reading the source before writing the regex was necessary but not sufficient: the first scoping still ran at 1-in-10 precision, and only checking the actual hits against the actual files exposed that lowercase `may` had to go too. Citation constrains the rule; measurement tunes it.

The second lesson is about where to draw the mechanical/judged line. Rules that reduce to "is this token in this syntactic context" (wrapping, keyword case, keyword-in-note, duplicated block) are cheap and precise. Rules that reduce to "is this claim complete/honest/well-placed" (RFC 8126 registry completeness, abbreviation-on-first-use, whether a section's obligations belong in it) look mechanizable but need a reader. Putting the second class into a linter is how prose gates earn a reputation for noise and get disabled; putting them in a judged rubric with a one-line test per criterion keeps both halves credible.
