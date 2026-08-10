---
name: asd-ste100
description: Apply formal ASD-STE100 (Simplified Technical English) or run a rigorous plain-technical-writing pass guided by Zinsser's clarity, simplicity, brevity, and humanity. Use when the user explicitly asks for ASD-STE100, STE, simplified technical English, Zinsser's writing principles, non-slop technical writing, or a mechanical prose lint. Includes a partial STE linter; it cannot certify compliance.
---

# ASD-STE100 and quality technical writing

ASD-STE100 is the formal standard named Simplified Technical English, not a second system
beside it. Use strict STE only when requested. For other technical prose, use the
domain-independent rules as guidance and do not claim formal compliance.

Read `references/writing-rules.md` for strict STE work. Read
`references/quality-writing.md` for a general technical-writing pass. The linter uses the
partial Part 2 sample in `references/dictionary.tsv`.

## Choose the mode

- **Strict STE:** Apply Issue 9 rules and vocabulary. The partial linter cannot establish
  compliance.
- **Plain technical writing:** Apply transferable STE rules and Zinsser's four qualities.
  Preserve necessary technical terms and explain them when the reader may not know them.

Do not apply aerospace-specific vocabulary categories or safety labels outside their
domain. Do not force this style onto prose where voice or narrative rhythm is the point.

## Workflow

1. Preserve facts, exact names and strings, conditions, uncertainty, and safety meaning.
2. Use active voice, imperative instructions, one idea per sentence, conditions before
   commands, consistent terms, and direct words.
3. Review with Zinsser's four qualities: make meaning clear, remove needless complexity,
   cut words that do no work, and sound like a person addressing a real reader. Never trade
   accuracy for brevity or invent personal experience to add humanity.
4. For strict STE, run the linter. For plain technical prose, use it only as an advisory
   pass:
   ```bash
   uv run ai/skills/local/asd-ste100/scripts/ste_lint.py --mode procedural your-draft.md
   uv run ai/skills/local/asd-ste100/scripts/ste_lint.py --mode descriptive your-draft.md
   ```
5. Resolve findings deliberately, then reread. The linter cannot judge meaning, logical
   order, terminology consistency, paragraph focus, or humanity. Dictionary findings are
   review prompts because the bundled dictionary is incomplete.

## Extending the dictionary sample

`references/dictionary.tsv` is a partial extraction (~640 of ~2,149 entries) from the ASD
PDF, covering A, B–C, L–O, S, and W–Z densely; D–K and P–R are thin. If the linter's `info`
noise on legitimate words in those ranges gets annoying, extend the TSV (tab-separated:
`word	pos	approved	alternatives`, alternatives `;`-joined) from the source PDF at
`references/source/asd-ste100-issue-9.pdf` — see the dictionary's "Introduction" section
(Part 2) for the exact column format before adding entries.
