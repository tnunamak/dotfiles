---
title: "Structural/cadence signals (sentence-length uniformity, repeated openers) outdiscriminate fixed vocabulary lists for AI-text detection by roughly an order of magnitude, and no surveyed tool does target-corpus-relative frequency detection"
date: 2026-08-04
topic: writing-craft
tags: [ai-detection, slop, vocabulary-lists, stylometry, corpus-relative, precision-over-recall]
status: draft
sources: [avoid-ai-writing-changelog, avoid-ai-writing-categories, slopkit-cadence, pangram-labs, storyscope-paper, vale-issue-94]
source_session: unknown
---

## CLAIMS

- A measured corpus study (RAID + HC3, 875 human / 779 machine paragraphs) found the entire 112-word
  Tier-1/2/3 "AI-tell" vocabulary table used by `conorbronsdon/avoid-ai-writing` has a **lift of 0.9x**
  against real machine-vs-human text — i.e. it fires *slightly less* on AI-generated text than on human
  text, discriminating worse than a coin flip — while the project's `uniformity` (sentence-rhythm)
  signal alone has **11.7x lift**, the strongest single discriminator they measured. [avoid-ai-writing-changelog]
- The same measurement found paragraph-level ROC-AUC for the composite AI-tell-word score was **0.501**
  (coin flip) and document-level was **0.623**; em-dash frequency lift was **inverted (0.2x — fires more
  on human text)**. [avoid-ai-writing-changelog]
- `avoid-ai-writing`'s own explicit conclusion, stated in `detector/CATEGORIES.md`: vocabulary lists are
  retained mainly as editing/clarity advice, not as evidence of machine authorship, because the
  measurement shows they don't reliably discriminate. [avoid-ai-writing-categories]
- `ehmo/slopkit`'s `slopbeth/scripts/cadence_score.py` mechanizes rhythm/cadence detection with **zero
  vocabulary wordlist** (one small exception: a 9-word "polished transitions" list): it flags
  `same_length_runs` (3+ consecutive sentences with word counts within 2 of each other), `length_cv`
  (coefficient of variation of sentence lengths <0.28 with ≥4 sentences), and `repeated_starts`
  (first-2-word sentence-opener repetition). This is a runnable, dependency-free Python implementation
  of the same "structure beats vocabulary" finding above. [slopkit-cadence]
- Pangram Labs (commercial AI-text detector, $9M raised, published technical reports incl.
  arxiv.org/pdf/2402.14873) states publicly: "structural regularity is the #1 signal AI detectors weight,
  above vocabulary," and "no single aspect of the writing determines where it lands, so a human writer is
  not at risk of being misclassified simply because ChatGPT has adopted one of their favorite devices,
  such as the em dash." Pangram's detector is a trained neural classifier operating as an author-ID
  problem (candidate vs. a learned embedding space of human/AI writing), not a fixed list. [pangram-labs]
- The academic paper "StoryScope: Investigating idiosyncrasies in AI fiction" (Russell, Rajendhran, Iyyer,
  Wieting; arXiv 2604.03136, first submitted April 2026) found that discourse-level narrative features
  ALONE (withholding all stylistic features like sentence rhythm and figurative-language density) achieve
  **93.2% macro-F1** on binary human-vs-AI detection across 61,608 stories (10,272 prompts × 6 authors: 1
  human + 5 LLMs), and that style-based detection is comparatively fragile — fine-tuning a model to mimic
  human style can crash a style-based detector's accuracy from 97% to 3%, while structural/discourse
  features are more durable to this kind of adversarial mimicry. Code is public on GitHub
  (`jenna-russell/storyscope`). [storyscope-paper]
- Across a citation-graph survey of 12+ AI-slop-detection projects (avoid-ai-writing, slopkit,
  brandonwise/humanizer, blader/humanizer [33.4k stars], isatimur/de-slop, stop-slop [15.1k stars],
  harshaneel/humanize, NulightJens/humanizer-stack, Aboudjem/humanizer-skill, tropes.fyi, devswha/patina,
  Vale [via its own open issue #94's research]), plus 2 academic datasets (RAID, HC3) and 1 commercial
  detector (Pangram Labs), **no surveyed tool compares a candidate word's frequency against a specific
  target system's own corpus** (e.g. a project's spec files, README, or domain vocabulary) to decide
  whether a word is that system's genuine, earned vocabulary or an imported/drifted abstraction. Every
  fixed-list tool compares against a static, general-purpose ban-list or general-English baseline; Pangram
  and StoryScope compare against a *generic* trained human/AI writing distribution, not a specific target
  system's own corpus. [vale-issue-94] [avoid-ai-writing-categories]
- Vale (`vale.sh`, actively maintained prose linter, 5,736 stars), per its own maintainer's research filed
  in open issue #94 proposing an AI-tell-detection package: Vale's rule model supports only `existence`,
  `substitution`, `occurrence`, `repetition`, and `readability` rule types — "no stylometry, no density
  gating across a document as far as I have checked" — confirming Vale itself has no corpus-relative or
  cadence-aware capability today. [vale-issue-94]

## SOURCES

**avoid-ai-writing-changelog**
URL: https://raw.githubusercontent.com/conorbronsdon/avoid-ai-writing/main/CHANGELOG.md
Accessed: 2026-08-04
Quote: "structural uniformity and pacing consistency are weighted higher than individual word choices" (v3.1.0 entry); v3.22.0 entry reports the 0.9x vocabulary-table lift, 0.501/0.623 ROC-AUC, 11.7x uniformity lift, and 0.2x inverted em-dash lift against RAID+HC3.

**avoid-ai-writing-categories**
URL: https://raw.githubusercontent.com/conorbronsdon/avoid-ai-writing/main/detector/CATEGORIES.md
Accessed: 2026-08-04
Quote: "a rule that wrongly flags ordinary human writing is worse than one that misses a tell, because false positives erode trust in every other rule" (CONTRIBUTING.md, cross-referenced); Section C documents LLM-judgment-only categories (no kept regex/detector form).

**slopkit-cadence**
URL: /home/tnunamak/.tmp/slopkit-study/skills/slopbeth/scripts/cadence_score.py (local clone of github.com/ehmo/slopkit v1.4.1)
Accessed: 2026-08-04
Quote: roughness formula = `2×(low_cv flag) + 2×monotony_runs + transition_count + repeated_start_total + long_sentence_count`; low_cv threshold is coefficient-of-variation < 0.28 with >=4 sentences.

**pangram-labs**
URL: https://pangram.com (How does Pangram work? blog post, and published research page)
Accessed: 2026-08-04
Quote: "Pangram is a type of neural network called a classifier model... Pangram learns to distinguish human and LLM writing by building a kind of map where authors with similar writing styles are placed close together."

**storyscope-paper**
URL: https://arxiv.org/abs/2604.03136 (StoryScope: Investigating idiosyncrasies in AI fiction)
Accessed: 2026-08-04
Quote: discourse-level narrative features alone achieve 93.2% macro-F1 on binary human-vs-AI detection; style-based detectors can be crashed from 97% to 3% accuracy by style-mimicking fine-tuning, while structural/discourse features are more durable.

**vale-issue-94**
URL: https://github.com/conorbronsdon/avoid-ai-writing/issues/94 (via `gh issue view`)
Accessed: 2026-08-04
Quote: "Vale's rule model is narrower than the detector's — no stylometry, no density gating across a document as far as I have checked." Issue also argues a Vale port "would be the only package in that registry with a measured false-positive rate rather than an asserted one. Every other one is asserted."

## SYNTHESIS

This consolidates and grounds two related findings that came up while extracting a merged anti-slop
ruleset for the PDPP site's `judge.mjs` checker (full report:
`/home/tnunamak/.tmp/pdpp-site-concept/SKILLMINE.md`, project-specific, not durable — this file extracts
only the reusable, non-project-specific claim).

First: fixed vocabulary/phrase ban-lists ("delve," "tapestry," "leverage," etc.) are the most common and
easiest-to-build anti-slop instrument, but the one rigorous measurement found in this survey says they're
close to useless as *detection* evidence (0.9x lift, near-coin-flip AUC) even though they may still be
useful as generic *prose-quality* editing advice. Cadence/rhythm signals — computed from sentence-length
statistics alone, with no wordlist — are the strongest measured discriminator by roughly an order of
magnitude, are register-independent by construction (a wordlist can misfire on domain jargon; a
uniformity statistic is about structure, not word identity), and are cheap to implement (slopkit's
`cadence_score.py` is ~50 lines of pure statistics). Any future anti-slop tooling should treat cadence
detection as the first thing to build, not an afterthought bolted onto a word list.

Second: despite an unusually deep citation-graph survey (12+ tools, 2 datasets, 1 commercial vendor, plus
their own cross-citations), nothing surveyed does true corpus-relative detection against a *specific
target system's own vocabulary* — comparing whether a candidate word is drift from, or consistent with,
the actual domain corpus of the thing being written about. Everyone compares against either a static
general list or a generic trained human/AI distribution. This looks like a genuinely open niche as of
2026-08, not a solved problem hiding under different branding — worth remembering next time this space
comes up, since it means a target-corpus-relative technique is differentiated rather than reinventing
prior art.
