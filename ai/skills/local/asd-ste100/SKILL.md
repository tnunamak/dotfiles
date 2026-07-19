---
name: asd-ste100
description: Write technical documentation, READMEs, PR descriptions, runbooks, or any prose that needs to read as clear and human-authored rather than AI-generated, by following ASD-STE100 (Simplified Technical English) — a controlled-language standard originally built for aerospace maintenance manuals. Use when the user asks for STE, "simplified technical English", "ASD-STE100", non-slop technical writing, or wants documentation checked/tightened for word count, passive voice, contractions, hedging, or clarity. Includes a mechanical linter (scripts/ste_lint.py) that catches word-count violations, semicolons, contractions, passive/auxiliary constructions, banned phrasal verbs, and non-approved words — run it, don't just eyeball the prose.
---

# ASD-STE100 (Simplified Technical English)

A controlled natural language standard from the aerospace industry (ASD, Issue 9, 2025).
Built so maintenance manuals are unambiguous for non-native English readers. Its rules are
also a strong, mechanically-checkable antidote to typical LLM prose: hedging, passive voice,
elegant variation, run-on sentences, and buried instructions.

Full rule reference: `references/writing-rules.md` (condensed paraphrase of Part 1 — read it
before writing anything nontrivial in this style). A sample of the approved-word dictionary
(Part 2) is at `references/dictionary.tsv`, used by the linter.

## When to actually apply this

Good fit: READMEs, runbooks, setup guides, API docs, PR/commit descriptions, CLI help text,
error messages, anything where "boring and unambiguous" beats "engaging."

Poor fit: marketing copy, narrative writing, anything where voice/tone variety is the point.
Also: don't apply the aerospace-specific plumbing (warning/caution taxonomy, technical-noun
categories, the dictionary's narrow domain vocabulary) outside a literal maintenance-manual
context — see the "What this means for LLM-generated prose" note at the end of
`references/writing-rules.md` for which parts generalize.

## Workflow

1. **Write** following the core rules (short sentences, active voice, imperative for
   instructions, one idea per sentence/paragraph, no phrasal verbs, no contractions, no
   hedging filler, consistent terminology). Skim `references/writing-rules.md` section
   headers as a checklist while drafting.
2. **Run the mechanical linter** on the draft — don't just eyeball it:
   ```bash
   python3 ai/skills/local/asd-ste100/scripts/ste_lint.py --mode procedural your-draft.md
   # or for prose/descriptive text (25-word sentence limit instead of 20):
   python3 ai/skills/local/asd-ste100/scripts/ste_lint.py --mode descriptive your-draft.md
   ```
   It flags: semicolons (8.1), contractions (4.2), Latin abbreviations (GR-6), likely
   passive/auxiliary constructions (3.4/3.6), "-ing" used as a verb (3.5), banned phrasal
   verbs (9.3), sentences/paragraphs over the word/sentence limits (5.1/6.3/6.6), and words
   absent from the approved dictionary sample (1.3/9.2, `info` severity — the dictionary
   file is a partial sample of ~640 of the spec's ~2,149 entries, so treat `info` findings
   as suggestions to double-check, not gospel; a missing word may just be missing from the
   sample, not actually banned).
3. **Fix what it flags**, re-run until clean (or until remaining findings are false
   positives you've deliberately accepted — e.g. `info`-level dictionary misses on
   uncommon-but-fine words).
4. **What the linter can't check** — verify these by re-reading: approved *meaning* of a
   word used correctly (rule 1.3 — the linter only checks approval, not sense), whether a
   passage's terminology stays consistent throughout (1.11/9.4), whether two actions in one
   sentence are genuinely simultaneous (5.2), paragraph/sentence topic focus (6.1/6.5).

## Extending the dictionary sample

`references/dictionary.tsv` is a partial extraction (~640 of ~2,149 entries) from the ASD
PDF, covering A, B–C, L–O, S, and W–Z densely; D–K and P–R are thin. If the linter's `info`
noise on legitimate words in those ranges gets annoying, extend the TSV (tab-separated:
`word	pos	approved	alternatives`, alternatives `;`-joined) from the source PDF at
`references/source/asd-ste100-issue-9.pdf` — see the dictionary's "Introduction" section
(Part 2) for the exact column format before adding entries.
