---
title: "ASD-STE100 is a specific controlled language; plain technical English is a broader writing aim that must not be presented as STE compliance"
date: 2026-08-10
topic: writing-craft
tags: [asd-ste100, plain-language, technical-writing, documentation, controlled-language]
status: settled
sources: [asd-ste100-about, asd-ste100-issue9, asd-ste100-faq, govuk-clear-language, dfe-plain-language, iso-house-style]
source_session: unknown
---

## CLAIMS

- ASD-STE100 is a controlled natural language and an international standard for technical documentation, consisting of Part 1 writing rules and Part 2 controlled vocabulary. [asd-ste100-about] [asd-ste100-faq]
- STE was developed for English-language aerospace maintenance documentation and later used in defense; ASD-STE100 Issue 9 was released on 2025-01-15. [asd-ste100-about] [asd-ste100-issue9]
- ASD describes Issue 9 as usable beyond aerospace and defense, but still defines STE through its rules, dictionary, and technical terminology provisions. [asd-ste100-about] [asd-ste100-issue9]
- STE permits company-, project-, industry-, and subject-specific technical terms; it does not require all technical vocabulary to come from its general dictionary. [asd-ste100-about] [asd-ste100-faq]
- GOV.UK guidance says plain language does not mean removing specialist language or changing meaning; needed specialist terms should be explained when first used. [govuk-clear-language] [dfe-plain-language]
- ISO’s house style says technical jargon can be appropriate in technical documents, while recommending clear, concise language, short sentences, one idea per sentence, and simple explanations of terms. [iso-house-style]
- The authoritative sources reviewed define ASD-STE100 and plain language, but do not define “plain technical English” as a named controlled-language standard. [asd-ste100-about] [iso-house-style] [govuk-clear-language]

## SOURCES

**asd-ste100-about**
URL: https://asd-ste100.org/about_STE.html
Accessed: 2026-08-10
Quote: "ASD-STE100 Simplified Technical English (STE) is a controlled natural language ... to help the users of English-language maintenance documentation understand what they read."

**asd-ste100-issue9**
URL: https://www.asd-ste100.org/assets/files/ASD-STE100_ISSUE9.pdf
Accessed: 2026-08-10
Quote: "ASD-STE100 Simplified Technical English (STE) is a controlled natural language and an international standard to write technical documentation."

**asd-ste100-faq**
URL: https://asd-ste100.org/STE_faq.html
Accessed: 2026-08-10
Quote: "STE has two parts: a set of writing rules (part 1) and a controlled dictionary (part 2)."

**govuk-clear-language**
URL: https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/
Accessed: 2026-08-10
Quote: "Where you need to use specialist terms, you can. ... You just need to explain what they mean the first time you use them."

**dfe-plain-language**
URL: https://design.education.gov.uk/content-design/plain-language
Accessed: 2026-08-10
Quote: "Plain English is a set of principles used to write clearly and accurately ... Plain language modifies those techniques to suit the needs of the user."

**iso-house-style**
URL: https://www.iso.org/ISO-house-style.html
Accessed: 2026-08-10
Quote: "Every technical sector uses specific terminology (i.e. jargon) and it is appropriate to use technical language in ISO documents."

## SYNTHESIS

The skill can safely broaden its practical advice, but should separate two modes:

1. **ASD-STE100 mode** means the named standard: apply the actual Issue 9 rules and dictionary, and describe the result as STE-oriented or STE-checked only when that scope is true. The current partial dictionary linter cannot establish full compliance.
2. **Plain technical documentation mode** (or “clear technical English”) means domain-agnostic editing guidance inspired by STE and plain-language sources. It is not a standard and should not be called “ASD-STE100” or “Simplified Technical English” without the ASD qualifier.

Safe cross-domain guidance for READMEs and runbooks: write for the reader and task; use short sentences and one idea per sentence; put conditions before commands; use active, imperative instructions; keep terminology consistent; explain necessary specialist terms at first use; preserve exact code, API, CLI, and UI strings; and remove filler without changing technical meaning. These principles are compatible with STE, GOV.UK, and ISO guidance.

Keep marked as aerospace/STE-specific: the controlled dictionary and approved word senses/parts of speech; the formal technical-noun and technical-verb categories; the warning-versus-caution taxonomy and consequence rules; fixed STE word-count limits as compliance gates; and claims about aviation safety, ATA/S1000D requirements, translation, or non-native-reader performance. These can inform a general-purpose checklist, but must be labeled as adaptations or heuristics.

Recommended naming/triggering: retain the skill directory name for discoverability, but describe it as “ASD-STE100 and plain technical documentation.” Trigger on explicit “ASD-STE100/STE” requests for strict mode; trigger on “clear technical writing,” README, runbook, or technical-doc clarity requests for the broader mode. Avoid treating the unqualified phrase “simplified technical English” as proof that the user wants formal ASD compliance; ask or state the assumed mode when it matters.
