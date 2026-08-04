---
title: "Every real prose-facing anti-AI-slop tool in the landscape uses a fixed universal word/phrase list; none compare candidate vocabulary against a target project's own reference corpus at analysis time — Pangram leads on independently-verified detector accuracy, ehmo/slopkit's own benchmark self-ranks first"
date: 2026-08-04
topic: writing-craft
tags: [ai-tells, tooling, vale, gptzero, pangram, binoculars, detectgpt, corpus-relative-detection, benchmark-integrity, github-survey]
status: draft
sources: [vale-ai-tells, blader-humanizer, ehmo-slopkit-readme, solmaz-de-smeller, liang-non-native-bias, raid-benchmark, pangram-vub-2026, gptzero-independent, forjd-better-writing, czech-entropy-reversal]
source_session: b74defed-7075-46ee-9496-cdf4b082dd4d
---

## CLAIMS

- No shipped tool found does per-project, analysis-time corpus-relative vocabulary detection — every prose-facing tool surveyed (tbhb/vale-ai-tells, blader/humanizer, hardikpandya/stop-slop, petergyang/no-ai-slop, conorbronsdon/avoid-ai-writing, stephenturner/skill-deslop, ehmo/slopkit) applies a fixed, universal word/phrase list or a pre-built tiered taxonomy the same way regardless of the target project's own domain vocabulary. This was independently confirmed for tbhb/vale-ai-tells, whose own documentation explicitly lists "sentence-length uniformity" and "perplexity scores" as things it CANNOT detect, and confirmed absent by direct code-reading in ehmo/slopkit (`grep -rE "frequency|corpus-relative|baseline rate|tf-idf"` across the whole repo returns nothing). [vale-ai-tells] [ehmo-slopkit-readme]
- The closest analog found is solmaz.io's "AI de-smeller" write-up, which builds a fixed 8-document human-baseline reference corpus (SQLite docs, Joel Spolsky/Paul Graham essays, Julia Evans, READMEs from ripgrep/Redis/Requests at pre-LLM 2016-17 git tags) and compares 10 AI-generated landing pages against it — but the metrics compared are STRUCTURAL/SYNTACTIC (exactly-three-list rate, labeled-bullet ratio, sentence-fragment share, longest-punctuation-free run), not lexical/vocabulary-frequency comparison, and the corpus is fixed at build time, not adaptively drawn from whatever project is being checked. Its own claimed "perfect classification on 18 ground-truth docs" has no held-out validation — a toy-sized proof of concept, not a generalized method. [solmaz-de-smeller]
- forjd/better-writing (17 GitHub stars) is the closest CONCEPTUAL analog: it ships an "era-stamped and tiered" vocabulary distinguishing "distinctive markers," "common-but-overused words," and "ordinary English that only shows up across a corpus" — but this taxonomy is pre-built and shipped with the skill, not computed live against the target project's own spec/doc corpus at analysis time, so it approximates the idea in spirit without doing the adaptive per-project computation. [forjd-better-writing]
- The academic literature has the right mathematical shape for corpus-relative detection (TF-IDF / termhood scoring, Σ log(f_domain/f_general), used in domain-term-extraction research) but applies it to human-vs-AI classification or generic domain-term extraction, not specifically to distinguishing AI-slop vocabulary from a target project's own authentic technical vocabulary — no shipped tool applying this exact framing to that exact problem was found.
- ehmo/slopkit's own README benchmark ranks itself #1 of 8 (slopbeth 99/100) using its own rubric with no independent judge, and separately claims a 4.96/5 win for its sibling tool slopgent — both self-administered. Cross-referencing GitHub star counts (verified directly against the GitHub API, not search-snippet figures) shows slopkit sits at 45 stars/4 forks while several tools it claims to beat by wide margins have far higher real-world adoption: blader/humanizer 33,424 stars/3,026 forks, hardikpandya/stop-slop 15,149 stars/1,080 forks — a signal that the self-administered benchmark ranking does not track real-world adoption or independent quality assessment. [ehmo-slopkit-readme]
- Among the fixed-word-list tools, tbhb/vale-ai-tells is the only one that is both actively maintained (commits through 2026-08-04, the access date) and genuinely CI/CD-gateable as a linter (a real Vale package with pre-commit hooks and error-level rules, 78 rule files, 15 commit-message rules) rather than a prompt-only agent skill. [vale-ai-tells]
- Among academic/commercial AI-text DETECTORS (as opposed to slop-removal style tools), independent third-party evaluation quality varies sharply by vendor: Pangram Labs has the strongest independently-corroborated accuracy claims, including a June 2026 peer-reviewed Vrije Universiteit Brussel study (160 papers, ESL/AI/hybrid/humanized splits) finding Pangram was the only one of 4 tested tools (vs GPTZero, Turnitin, Copyleaks) that reliably detected AI content — though Pangram's own reported 0% false-positive rate on the TOEFL/ESL benchmark is on a benchmark the vendor states it explicitly excluded from training, and its own reported accuracy still drops to ~73% on AI-edited/"humanized" text. [pangram-vub-2026]
- GPTZero has the largest documented gap between vendor-claimed accuracy (99%) and independently measured accuracy: Scribbr measured 52%; a 2026 mixed-sample test found 83% true-positive/11% false-positive on human text; a PMC 2025 medical-text study found 80-85% accuracy with 8-12% false-positive rate. GPTZero is also the subject of active litigation (Yale, Feb 2025; University of Michigan, 2026) over false accusations, both citing non-native-speaker/disability discrimination claims. [gptzero-independent]
- DetectGPT's original 95%-accuracy claim is now understood as fragile under adversarial pressure: independent testing found accuracy collapses to ~4.6% after basic paraphrasing (a ~94% relative collapse), and the RAID benchmark found near-zero true-positive rates industry-wide across 14 tools once false-positive rate is constrained below 1%. [raid-benchmark]
- Liang et al.'s original 2023 finding (61.3% average false-positive rate across 7 detectors on 91 non-native TOEFL essays — already in this corpus's syntactic-tells entry) does NOT generalize cleanly across languages: a 2026 EACL-SRW replication using the same entropy methodology on Czech text found the OPPOSITE pattern — non-native Czech writers showed HIGHER entropy than native peers, not lower — while confirming the same method reproduces Liang et al.'s original English-language result. This suggests the non-native-writer bias may be language-specific/model-dependent rather than a universal property of AI detectors, complicating any claim that the bias generalizes across all languages by default. [czech-entropy-reversal]
- Adversarial robustness across the whole detector category remains weak in 2025-2026: one paraphrasing-attack study found an 87.88% average detection-rate reduction across all major detector types tested (arXiv 2506.07001), corroborating the RAID benchmark's finding independently.
- Every.to's own staff has documented catching AI-writing tells (symmetrical structures, rhetorical throat-clears, rule-of-three) in a HUMAN writer's own unassisted drafts, not just LLM output — direct evidence that fixed AI-tell word/pattern lists risk false-positiving on human writers who happen to share the stylistic habit, independent of any detector's technical false-positive-rate numbers.
- No formal 2025-2026 AI-slop-specific editorial policy was found from AP, Reuters, or NYT specifically — only trend/commentary coverage of the general problem, not house-style responses codifying specific banned constructions the way Every.to and GOV.UK have.

## SOURCES

**vale-ai-tells**
URL: https://github.com/tbhb/vale-ai-tells
Accessed: 2026-08-04
Quote: (from repo docs, paraphrased) explicitly lists sentence-length uniformity and perplexity scores as detection classes the package cannot implement; 78 rule files sourced from Wikipedia's Signs of AI writing, Beutler Ink's "How to Spot AI Writing," and Charlie Guo's "Field Guide to AI Slop."

**blader-humanizer**
URL: https://github.com/blader/humanizer
Accessed: 2026-08-04 (star/fork counts verified directly via GitHub API)
Quote: 33,424 stars / 3,026 forks; LLM-guided rewrite skill against 33 documented AI-tell patterns, prompt-only (no regex/CLI mechanism).

**ehmo-slopkit-readme**
URL: https://github.com/ehmo/slopkit (README, and local clone at /home/tnunamak/.tmp/slopkit-study inspected directly)
Accessed: 2026-08-04
Quote: "One run of one rubric against public repos as they stood on the run date, not a standing leaderboard" — slopkit's own self-administered ranking places itself #1 (99/100) among 8 competitors it names, while sitting at 45 GitHub stars against several of those competitors' 15k-33k+ stars.

**solmaz-de-smeller**
URL: https://solmaz.io/ai-de-smeller
Accessed: 2026-08-04
Quote: (paraphrased) builds an 8-document pre-LLM human-baseline reference corpus and compares structural/syntactic metrics (list-of-three rate, bullet ratio, fragment share) against 10 AI-generated pages, claiming perfect classification on an 18-document set with no held-out validation.

**liang-non-native-bias**
URL: https://arxiv.org/pdf/2304.02819 (Patterns/Cell Press, 2023)
Accessed: 2026-08-04
Quote: 61.3% average false-positive rate across 7 GPT detectors on 91 real TOEFL essays by non-native English speakers. (Cross-referenced with the syntactic-tells corpus entry, which covers this same source in more depth.)

**raid-benchmark**
URL: (RAID benchmark findings, referenced via search synthesis in the landscape sweep; original benchmark paper not independently re-fetched in this pass)
Accessed: 2026-08-04
Quote: (paraphrased) all 14 tools tested in the underlying Weber-Wulff-style methodology scored below 80% accuracy; near-zero true-positive rates industry-wide once false-positive rate is constrained below 1%.

**pangram-vub-2026**
URL: (Vrije Universiteit Brussel peer-reviewed study, June 2026, referenced via search synthesis; not independently re-fetched as a primary PDF in this pass)
Accessed: 2026-08-04
Quote: (paraphrased) 160-paper study across ESL/AI/hybrid/humanized text splits found Pangram was the only one of 4 tools tested (vs GPTZero, Turnitin, Copyleaks) that reliably detected AI content; Pangram's own reported accuracy on AI-edited/"humanized" text drops to ~73%.

**gptzero-independent**
URL: (Scribbr accuracy test, PMC 2025 medical-text study, referenced via search synthesis; not independently re-fetched as primary sources in this pass)
Accessed: 2026-08-04
Quote: (paraphrased) Scribbr measured 52% accuracy against GPTZero's own 99% claim; PMC 2025 medical-text study found 80-85% accuracy with 8-12% false-positive rate.

**forjd-better-writing**
URL: https://github.com/forjd/better-writing
Accessed: 2026-08-04
Quote: (paraphrased) ships an "era-stamped and tiered" vocabulary distinguishing distinctive markers, common-but-overused words, and corpus-only-ordinary English, as a fixed pre-built taxonomy.

**czech-entropy-reversal**
URL: https://arxiv.org/html/2602.05769 (EACL-SRW 2026, "Different Time, Different Language")
Accessed: 2026-08-04
Quote: (paraphrased) replicating Liang et al.'s entropy methodology on Czech text found non-native Czech writers showed HIGHER entropy than native peers — the opposite direction from the original English-language finding — while confirming the method reproduces the original English result, isolating the reversal to language/model rather than a methodology mismatch.

## SYNTHESIS

The landscape confirms, rather than contradicts, the design decision behind this project's own `judge.mjs` (CHECK 5, abstract-noun drift): comparing a candidate word's frequency against the target project's OWN corpus, rather than applying a universal ban-list, is genuinely unusual. Nobody found in this sweep does the specific thing — per-project, analysis-time, lexical corpus-relative detection. The nearest neighbors either do the right comparison at the wrong granularity (solmaz.io: corpus-relative but structural/syntactic, not lexical) or the right granularity with the wrong adaptivity (forjd/better-writing: lexical tiering, but fixed at ship-time, not computed against the specific project being checked). This is a real, currently-unfilled niche — worth stating plainly rather than hedging, while also being honest that "nobody has shipped this" is not the same evidential weight as "people tried this and it failed benchmarking." No one has run the experiment either way.

The practical ranking for someone choosing what to adopt: for a maintained, CI-gateable, honestly-scoped linter, **tbhb/vale-ai-tells** is the strongest candidate in the fixed-word-list category — it is a real Vale package (not a prompt-only skill), actively maintained, and its own documentation states its limits rather than overclaiming. For AI-text *detection* specifically (a different problem than slop-removal), **Pangram** currently has the best independent third-party verification, though even its own numbers show real degradation against edited/humanized text, and no detector in this category should be deployed against real user-submitted text (e.g., for academic-integrity purposes) without accounting for the non-native-writer false-positive risk — which the 2026 Czech replication suggests is real but not uniform across languages, so "the bias will definitely reproduce in language X" is not a safe inference from the English-only original finding.

ehmo/slopkit's self-administered ranking should not be trusted as a comparative verdict — its own docs partially admit this ("not a standing leaderboard"), and the mismatch between its claimed dominance and its actual GitHub adoption (45 stars vs. 15k-33k+ for tools it claims to beat) is itself evidence the benchmark isn't measuring what real users have converged on. This doesn't mean slopkit's underlying rules or its decoy-rejection testing methodology (see the separate slopkit-deep-study corpus entry) are worthless — the benchmark ranking specifically is the untrustworthy part, not the whole artifact.

Related corpus entries: sibling to [[syntactic-and-rhetorical-ai-tells-are-empirically-attested-at-the-syntax-tree-level-not-just-vocabulary]] (Reinhart et al.'s house-specificity finding and the Liang et al. non-native bias finding are covered in more depth there) and [[abstract-nouns-promoted-to-technical-terms-read-as-ai-because-vagueness-is-unfalsifiable]] (whose corpus-drift discriminator is the specific design this entry confirms has no shipped prior art). See also the forthcoming slopkit-specific deep-study entry for the artifact-level evaluation of ehmo/slopkit's actual code, benchmark integrity, and decoy-rejection harness — this entry covers slopkit only as one data point in the wider landscape ranking.
