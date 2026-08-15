---
title: "Readability formulas (Flesch-Kincaid, Gunning Fog, SMOG, Coleman-Liau, Dale-Chall) measure lexical/syntactic surface proxies (syllables, letters, sentence length, or a fixed word list), not semantic or conceptual difficulty, and this gap is empirically documented, not just folk criticism"
date: 2026-08-14
topic: writing-craft
tags: [readability, flesch-kincaid, gunning-fog, smog, coleman-liau, dale-chall, coh-metrix, comprehension, jargon, cognitive-load, eye-tracking]
status: draft
sources: [gunning-fog-wikipedia, dale-chall-wikipedia, smog-wikipedia, coleman-liau-wikipedia, bailin-grafstein-2001, coh-metrix-graesser-2004, oreilly-mcnamara-2007, ozuru-dempsey-mcnamara-2009, chv-familiarity-2007, gruteke-klein-2025]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

### The formulas themselves — what each one actually counts

- Gunning Fog Index (Robert Gunning, 1952, from his consultancy *The Technique of Clear Writing*): `0.4 × [(words/sentences) + 100 × (complex words/words)]`, where a "complex word" is any word of three or more syllables, excluding proper nouns, familiar jargon, compound words, and words that only reach three syllables via common suffixes (-es, -ed, -ing). [gunning-fog-wikipedia]
- Dale-Chall Readability Formula (Edgar Dale and Jeanne Chall, 1948, *Educational Research Bulletin*; word list revised 1995): `0.1579 × (difficult words/words × 100) + 0.0496 × (words/sentences)`, with 3.6365 added if difficult words exceed 5% of the text. [dale-chall-wikipedia]
- Dale-Chall's "difficult word" is defined structurally differently from every other formula here: it is any word absent from a fixed familiar-word list (769 words in the 1948 original, tested as known by 80% of 4th graders; expanded to ~3,000 words in the 1995 revision), regardless of that word's syllable count or letter count. [dale-chall-wikipedia]
- SMOG grade (G. Harry McLaughlin, 1969, *Journal of Reading*, explicitly named as a nod to Gunning's Fog index): `grade = 1.0430 × √(polysyllables × 30/sentences) + 3.1291`, using polysyllabic (3+ syllable) word counts from a 30-sentence sample. [smog-wikipedia]
- SMOG reports a 0.985 correlation with the grades of readers who achieved 100% comprehension on test materials in McLaughlin's original validation, and a 2010 study on consumer health materials found SMOG outperformed competing formulas (which "significantly underestimated reading difficulty") against that same comprehension-based gold standard. [smog-wikipedia]
- Coleman-Liau Index (Meri Coleman and T. L. Liau, 1975, "A computer readability formula designed for machine scoring," *Journal of Applied Psychology*): `CLI = 0.0588 × L − 0.296 × S − 15.8`, where L = average letters per 100 words and S = average sentences per 100 words. [coleman-liau-wikipedia]
- Coleman and Liau chose letter-counting over syllable-counting explicitly for computational tractability — their own abstract states "word length in letters is a better predictor of readability than word length in syllables" and notes letters are counted more accurately by computer programs than syllables are. [coleman-liau-wikipedia]
- All four formulas (Fog, Dale-Chall's second term, SMOG, Coleman-Liau) share one structural feature with Flesch-Kincaid: every one of them is a linear or near-linear function of (a) some word-length or word-familiarity-list proxy and (b) sentence length, with no term for meaning, argument structure, cohesion, or domain knowledge. [gunning-fog-wikipedia] [dale-chall-wikipedia] [smog-wikipedia] [coleman-liau-wikipedia]

### The formal criticism — proxies, not semantics

- Bailin and Grafstein's "The Linguistic Assumptions Underlying Readability Formulae: A Critique" (*Language & Communication* 21(3), 2001) is the standard academic critique: it argues readability formulae rest on the unjustified assumption that text difficulty is reducible to a single statistical score, that word length is a poor proxy for word difficulty (longer words are frequently transparent affixations that children already understand the meaning of), and that formulae ignore grammar, style, background knowledge, and coherence. [bailin-grafstein-2001]
- Bailin and Grafstein's stated practical concern is that formula scores (they specifically cite Lexile) can mislead educators into over-relying on a number that does not actually capture the linguistic factors that determine whether a text is comprehensible. [bailin-grafstein-2001]
- Graesser, McNamara, Louwerse, and Cai's "Coh-Metrix: Analysis of text on cohesion and language" (*Behavior Research Methods* 36(2), 2004) states the field's standard framing of the gap explicitly: classic readability formulas rely on word length and sentence length as surface proxies and are "uni-dimensional," ignoring cohesion, world knowledge, and discourse-level language characteristics that determine actual comprehension. [coh-metrix-graesser-2004]
- Coh-Metrix was built specifically to fill that gap: it computes over 200 measures spanning lexicons, syntactic parses, and Latent Semantic Analysis, and is explicitly grounded in the constructivist theory of discourse comprehension (readers build coherent mental models by connecting text constituents), not in surface counting. [coh-metrix-graesser-2004]
- Graesser et al. (2004) note that readability formulas are commonly gamed in practice: textbook writers shorten sentences specifically to lower a formula's reported grade level, a manipulation that changes the score without necessarily making the text easier to actually understand. [coh-metrix-graesser-2004]

### Direct empirical evidence that low-lexical-complexity text can still be hard to comprehend

- O'Reilly and McNamara (2007, *Discourse Processes* 43(2), "Reversing the Reverse Cohesion Effect: Good Texts Can Be Better for Strategic, High-Knowledge Readers") found that college readers with high prior domain knowledge but lower comprehension skill performed better on a low-cohesion (harder-to-parse-on-the-surface) text than on a high-cohesion (easier-to-parse) version of the same content, while skilled high-knowledge comprehenders benefited from the high-cohesion version — i.e., surface-level text difficulty and actual comprehension outcome decoupled and even inverted, depending on the reader's domain knowledge and skill. [oreilly-mcnamara-2007]
- Ozuru, Dempsey, and McNamara (2009, *Learning and Instruction*) extended this "reverse cohesion effect" specifically to science texts: readers with low prior domain knowledge benefit from higher-cohesion (surface-easier) text, but this benefit is concentrated in shallow, text-based comprehension questions rather than deeper bridging-inference comprehension — meaning a text can score as more "readable" by surface cohesion while still not producing deeper understanding. [ozuru-dempsey-mcnamara-2009]
- Consumer Health Vocabulary research (Zeng-Treitler et al., published via NCBI/PMC, "Assessing Consumer Health Vocabulary Familiarity") found that general-purpose readability formulas based on word length are poorly suited to the health domain because short medical/technical terms can be unfamiliar to lay readers even though they are lexically simple by syllable/letter count — and separately found that a term's predicted familiarity did not guarantee that readers who recognized the term also understood the underlying concept ("conceptualization lagged behind recognition" even for terms predicted as familiar). [chv-familiarity-2007]
- Gruteke Klein, Frenkel, Shubi, and Berzak, "Eye Tracking Based Cognitive Evaluation of Automatic Readability Assessment Methods" (arXiv:2502.11150, 2025), introduced a cognitive evaluation framework using real-time eye-tracking (reading-time) measures as ground truth for reading ease, rather than offline comprehension-test scores or subjective ratings. [gruteke-klein-2025]
- That paper's abstract states its headline result directly: applying this eye-tracking-based evaluation to "prominent traditional readability formulas, NLP-based methods, commercial systems used in education, and frontier LLMs" found they are all "poor predictors of English reading ease in adults as compared to word properties commonly used in psycholinguistics for the prediction of reading times," and that this result held across L1 and L2 speakers, different reading regimes, and different textual unit lengths. [gruteke-klein-2025]

## SOURCES

**gunning-fog-wikipedia**
URL: https://en.wikipedia.org/wiki/Gunning_fog_index
Accessed: 2026-08-14
Quote: "0.4 [(words/sentences) + 100 (complex words/words)]" — complex words defined as 3+ syllable words excluding proper nouns, familiar jargon, compound words, and common suffix inflections; developed by Robert Gunning, 1952.

**dale-chall-wikipedia**
URL: https://en.wikipedia.org/wiki/Dale%E2%80%93Chall_readability_formula
Accessed: 2026-08-14
Quote: "0.1579(difficult words/words × 100) + 0.0496(words/sentences)" plus 3.6365 if difficult words exceed 5%; original 1948 list of 769 words known by 80% of 4th graders, expanded to ~3,000 words in the 1995 revision; "difficult" words are those absent from the list, not defined by syllable count.

**smog-wikipedia**
URL: https://en.wikipedia.org/wiki/SMOG
Accessed: 2026-08-14
Quote: "grade = 1.0430√(number of polysyllables × 30/number of sentences) + 3.1291" — McLaughlin, 1969, Journal of Reading; reports 0.985 correlation with grades of readers achieving 100% comprehension in original validation; a 2010 study found competing formulas "significantly underestimated reading difficulty compared with the gold standard SMOG formula" for consumer health materials.

**coleman-liau-wikipedia**
URL: https://en.wikipedia.org/wiki/Coleman%E2%80%93Liau_index
Accessed: 2026-08-14
Quote: "CLI = 0.0588 · L − 0.296 · S − 15.8" where L = avg letters per 100 words, S = avg sentences per 100 words; original abstract states "word length in letters is a better predictor of readability than word length in syllables"; Coleman & Liau, 1975, Journal of Applied Psychology.

**bailin-grafstein-2001**
URL: https://www.sciencedirect.com/science/article/abs/pii/S0271530901000052 (also indexed at https://eric.ed.gov/?id=EJ629584)
Accessed: 2026-08-14
Quote: Argues "the criteria commonly used in readability formulae do not constitute a satisfactory basis for assessing reading difficulty"; word length is a poor proxy since longer words are often transparent affixations children already understand; factors affecting readability include "grammar, style, background knowledge, and coherence," which formulae ignore. Bailin, A. & Grafstein, A. (2001), Language & Communication 21(3).

**coh-metrix-graesser-2004**
URL: https://link.springer.com/article/10.3758/BF03195564
Accessed: 2026-08-14
Quote: Classic readability formulas "scale texts on difficulty by relying on word length and sentence length," described as "uni-dimensional" (McNamara et al. framing), whereas Coh-Metrix "is sensitive to cohesion relations, world knowledge, and language and discourse characteristics." Notes textbook writers shorten sentences specifically to lower reported grade level. Graesser, A.C., McNamara, D.S., Louwerse, M.M., & Cai, Z. (2004), Behavior Research Methods 36(2).

**oreilly-mcnamara-2007**
URL: https://www.tandfonline.com/doi/abs/10.1080/01638530709336895 (also https://www.researchgate.net/publication/233347242)
Accessed: 2026-08-14
Quote: "the benefit of low-cohesion text was restricted to less-skilled, high-knowledge readers, while skilled comprehenders with high knowledge actually benefited from a high-cohesion text" — O'Reilly, T. & McNamara, D.S. (2007), "Reversing the Reverse Cohesion Effect," Discourse Processes 43(2).

**ozuru-dempsey-mcnamara-2009**
URL: https://www.sciencedirect.com/science/article/abs/pii/S0959475208000534
Accessed: 2026-08-14
Quote: Tested whether the benefit of high-cohesion text for low-knowledge readers is "limited to relatively lower levels of comprehension — e.g., performance on text-based questions" as opposed to deeper bridging-inference comprehension, in science texts specifically. Ozuru, Y., Dempsey, K., & McNamara, D.S. (2009), Learning and Instruction.

**chv-familiarity-2007**
URL: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1874513/
Accessed: 2026-08-14
Quote: "general purpose readability formulas based primarily on word length are not well suited for the health domain, where short technical terms may be unfamiliar to consumers"; "conceptualization lagged behind recognition, especially for terms predicted as 'likely to be familiar'."

**gruteke-klein-2025**
URL: https://arxiv.org/abs/2502.11150
Accessed: 2026-08-14
Quote: "Applying this evaluation to prominent traditional readability formulas, NLP-based methods, commercial systems used in education, and frontier LLMs suggests that they are all poor predictors of English reading ease in adults as compared to word properties commonly used in psycholinguistics for the prediction of reading times. This outcome holds across L1 and L2 speakers, different reading regimes, and textual units of different lengths." Gruteke Klein, K., Frenkel, S., Shubi, O., & Berzak, Y. (2025), arXiv:2502.11150.

## SYNTHESIS

The four non-Flesch formulas researched here (Fog, SMOG, Coleman-Liau, Dale-Chall) confirm the same pattern as Flesch-Kincaid: three of them (Fog, SMOG, Coleman-Liau) are linear functions of a word-length proxy (syllables or letters) plus sentence length, full stop — no term for meaning exists in the equation. Dale-Chall is the one partial exception worth flagging: its "difficult word" term is not syllable-based at all, it's a fixed familiar-word-list lookup, which makes it sensitive to word *frequency/familiarity* rather than word *length*. That is a real, if narrow, step toward the "familiar words can still gate on domain knowledge" problem — but the fix is still lexical (is this word on a list), not conceptual (does the reader understand what the word denotes). None of the five formulas has any mechanism for detecting that a sentence built entirely from short, common, list-approved words can still convey an unfamiliar technical concept.

The strongest citable evidence for "readability formulas miss conceptual complexity, not just as a hunch but as tested science" splits into three independent lines that corroborate each other:

1. **Theoretical critique** (Bailin & Grafstein 2001) — the formulas were never designed to model meaning; their surface variables are proxies chosen for computability, not constructs with theoretical grounding in comprehension.
2. **A working alternative built explicitly to fix this** (Coh-Metrix, Graesser/McNamara/Louwerse/Cai 2004) — treats cohesion, world knowledge, and discourse structure as the missing variables, and is the most citable "here is what a formula that actually models comprehension would need to measure" reference.
3. **Direct empirical demonstrations that surface-easy and conceptually-easy diverge** — this is the part of the question with the best evidence, and it's stronger than "readability formulas are imperfect": the O'Reilly/McNamara and Ozuru/Dempsey/McNamara reverse-cohesion-effect studies show measured comprehension *inverting* relative to surface-level ease depending on the reader's prior domain knowledge — a high-knowledge reader can comprehend a "harder" (lower-cohesion, presumably lower-Flesch-score) text better than an "easier" one, because the lower-cohesion text forces them to engage their own domain knowledge instead of coasting on cohesive glue. The Consumer Health Vocabulary research operationalizes exactly the phrasing in the research question — "familiar-looking short words that are actually unfamiliar technical concepts" — with a real dataset (medical terms) and finds recognition and conceptual understanding are separable, measured outcomes.

The single best modern citation for the exact question "do readability formulas actually predict comprehension, tested against real behavior" is Gruteke Klein et al. 2025 (arXiv:2502.11150): it is recent (2025), uses a genuinely different ground truth (real-time eye-tracking / reading ease rather than offline comprehension tests, which sidesteps some of the older debate about what "comprehension test" even measures), tests Flesch-Kincaid-style formulas *and* modern NLP methods *and* frontier LLMs side by side, and states in its own abstract that all of them are poor predictors compared to simple psycholinguistic word-property baselines. This is the strongest available "the whole readability-formula paradigm, including the AI-native successors, underperforms" claim, not just an anti-Flesch folk criticism.

Practical implication for any prose-quality skill/rule that currently gates on a Flesch-Kincaid-style score: such a gate can be defeated by writing short-sentence, short-word prose about an unfamiliar concept (it will score "readable" while remaining incomprehensible to a non-expert reader), and conversely can falsely penalize longer/lower-cohesion prose that a knowledgeable reader actually processes better. If comprehension is the real target, prefer proxies closer to Coh-Metrix's dimensions (jargon/term familiarity against a domain-appropriate list, explicit definition-on-first-use, cohesion/connective density) or direct reader testing, over adding more surface-metric gates.
