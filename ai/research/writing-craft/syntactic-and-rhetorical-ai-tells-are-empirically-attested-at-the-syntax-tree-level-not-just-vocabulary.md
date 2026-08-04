---
title: "Syntactic and rhetorical AI-tell structures (negative parallelism, participial-clause openers, nominalization, discourse-tree shape) are empirically measured at the syntax-tree level, not just asserted from vocabulary lists — but detector reliability built on them remains contested"
date: 2026-08-04
topic: writing-craft
tags: [ai-tells, syntax, rhetorical-structure, stylometry, negative-parallelism, burstiness, detection-bias, wikipedia-signs-of-ai-writing]
status: draft
sources: [wikipedia-signs-of-ai-writing, reinhart-pnas-2025, juzek-ward-rlhf-2508, prdetect-acl2025, dependency-distance-2411, discourse-motifs-2402, liang-non-native-bias, gptzero-burstiness-retirement, domain-regeneration-2505]
source_session: b74defed-7075-46ee-9496-cdf4b082dd4d
---

## CLAIMS

- Wikipedia's "Signs of AI writing" (WP:AI-CATCH) is the single richest catalogue found and is built from thousands of real deletion/review cases, not speculation; it names structural/syntactic tells beyond vocabulary, and — critically — most of the *language-and-grammar-level* tells are individually cited to named external studies, while most of the *formatting-level* tells (Title Case headers, inline-bold bullet lists, boldface overuse) are uncited crowd/editorial observation specific to Wikipedia's AfC-patrol context. [wikipedia-signs-of-ai-writing]
- Wikipedia names three negative-parallelism sub-patterns as empirically distinct, not one construction: "not just X, but also Y", "not X, but Y", and "X rather than Y" — the last flagged as a Grok-specific structural signature, evidence that structural tells are model-house-specific rather than universal. [wikipedia-signs-of-ai-writing]
- Wikipedia cites an empirical, numbered claim for copula avoidance specifically: >10% documented decrease in plain "is/are" use in 2023 academic writing, replaced by "serves as / stands as / marks / functions as / represents / boasts / features / maintains / offers / refers to." This is a genuinely syntactic (not lexical) finding — a systematic verb-choice shift around the sentence's main predicate. [wikipedia-signs-of-ai-writing]
- Wikipedia's own page contains a self-aware disconfirming section ("Ineffective indicators") stating that professional tone and heavy citation alone are NOT reliable AI signals — the page's authors actively guard against overclaiming, which is itself evidence the catalogue is used adversarially/critically by its own maintainers, not just accumulated. [wikipedia-signs-of-ai-writing]
- The single most reliable tell-class on Wikipedia's page is not stylistic at all: leaked internal tool-call/citation tokens (`contentReference`, `oaicite`/`oai_citation`, `turn0search0` for ChatGPT; `[cite: 1]` for Gemini; `grok_card` for Grok; `ppl-ai-file-upload` for Perplexity) are forensic string matches, not probabilistic style inference — this sidesteps the entire empirical-vs-asserted question because it's just grep. [wikipedia-signs-of-ai-writing]
- Reinhart, Markey, Laudenbach, Pantusen, Yurko, Weinberg & Brown, "Do LLMs write like humans? Variation in grammatical and rhetorical styles" (PNAS 2025; arXiv:2410.16107), is the strongest EMPIRICAL syntactic-structure source found: using Biber's grammatical/rhetorical feature framework across GPT-4o and multiple Llama-3 sizes (base + instruct), they measure present-participial clauses at 2–5x the human rate (GPT-4o specifically at 5.3x) and nominalizations at 1.5–2x the human rate. [reinhart-pnas-2025]
- The same study found agentless passive voice at HALF the human rate for GPT-4o — directly contradicting the common folk assumption that AI text over-uses passive voice; passive-voice direction is not a safe universal assumption. [reinhart-pnas-2025]
- The same study found structural tells are house-specific, not model-agnostic: GPT-4o models avoid clausal coordination while Llama-3 variants use it MORE than humans do; GPT-4o over-uses downtoners ("barely," "nearly") while Llama-3 under-uses them relative to humans. A classifier trained on these features mostly confuses different LLMs WITH EACH OTHER, not humans with LLMs — meaning these features are better at model-fingerprinting/attribution than at binary human-vs-AI detection. [reinhart-pnas-2025]
- The same study found base (non-instruction-tuned) Llama-3 models track human feature rates closely, while instruction-tuned Llama-3 and GPT-4o diverge substantially — directly implicating RLHF/instruction-tuning as the causal mechanism for syntactic (not just lexical) drift, independently corroborating the vocabulary-level RLHF mechanism already in this corpus's [[making-ai-assisted-prose-not-read-as-machine-generated]] entry via Juzek & Ward. [reinhart-pnas-2025]
- Juzek & Ward's RLHF study extends to concrete overused NOUNS with quantified occurrences-per-million data, not just the verb/adjective-heavy Kobak et al. list already in this corpus: "reliance" (1.2→40.1 opm, +3,193.6%), "generalizability" (2.4→78.5 opm, +3,124%), "radar" (0.6→16.4 opm, +2,590.6%), "staffing" (0.6→13.0 opm, +2,033.9%), "finish" (0.6→10.2 opm, +1,570%), measured by comparing Llama 3.2-3B Base vs Instruct generating continuations of 9,853 PubMed abstracts, POS-tagged with chi-square significance testing. [juzek-ward-rlhf-2508]
- The same study's mechanism finding: 400 human RLHF raters showed a statistically significant preference (52.4% vs 47.6%, p<0.01) for text containing these overused words when skimming unfamiliar/technical text — direct evidence the tell is a downstream artifact of the RLHF reward signal, not the base model's raw distribution. [juzek-ward-rlhf-2508]
- A survey synthesis (Terčon, arXiv:2510.05136, citing Herbold et al. 2023 and Reinhart et al. 2024) reframes "noun overuse" as substantially a NOMINALIZATION phenomenon — verb/adjective forms systematically converted to nouns ("announce"→"announcement") — which is a grammatical-structure effect, not a vocabulary-list effect; the same survey found LLM text has FEWER adjectives than human text, directly complicating the folk "AI overuses adjectives" framing found in less careful sources. [dependency-distance-2411]
- PRDetect (ACL Findings, NAACL 2025) is a published, peer-reviewed classifier using syntax-tree features (not lexical/embedding features) tested on HC3 and a GPT-3.5-mixed dataset; its main empirical claim is that syntax-tree features are comparatively robust to paraphrasing-attack perturbation relative to lexical/embedding-based detectors, and fastest at inference among compared methods. [prdetect-acl2025]
- A separate comparative-detection paper (arXiv:2411.06248) measured dependency distance (a parse-tree complexity metric) and found ChatGPT sentences have measurably LONGER dependency distances (more complex grammatical structure) than human text — a finding that runs counter to the common "AI writing is simple/formulaic" folk narrative; complexity and formulaicity are not the same axis and should not be conflated. [dependency-distance-2411]
- Discourse-level (not sentence-level) structure carries independent signal: "Threads of Subtlety" (arXiv:2402.10586) uses Rhetorical Structure Theory (Mann & Thompson) via the DMRST parser to extract discourse-tree depth/breadth and relation-type distribution, and found these hierarchical discourse features improve human-vs-machine classifiers including on OUT-OF-DOMAIN data — evidence that paragraph-to-paragraph relational structure, not just sentence-internal syntax, is a genuine and underexploited axis beyond anything in this corpus's existing sentence/phrase-level catalogue (negative parallelism, tricolon, em-dash). [discourse-motifs-2402]
- DISCONFIRMING EVIDENCE, the strongest found: Liang, Yuksekgonul, Mao, Wu & Zou (Patterns/Cell Press 2023; arXiv:2304.02819) tested 7 GPT detectors on 91 real TOEFL essays by non-native English speakers and found an average 61.3% FALSE POSITIVE rate. Using ChatGPT to enrich vocabulary in those same essays to sound more native-like dropped the false-positive rate from 61.22% to 11.77%; conversely, degrading US 8th-grade native-speaker essays toward simpler/non-native-style vocabulary RAISED their false-positive rate from 5.19% to 56.65%. This demonstrates the false positive is mechanistically caused by lower lexical/syntactic complexity mimicking the low-perplexity signature detectors associate with AI — not a coincidental correlation. [liang-non-native-bias]
- DISCONFIRMING EVIDENCE, structural-fingerprinting overfit: a 2026 dependency-relation classifier (arXiv:2602.15514, DependencyAI) built on M4GT-Bench reports "systematic overprediction of certain models on unseen domains" — i.e., syntactic fingerprints trained on one generator/domain do not generalize cleanly to new domains, a caution against trusting syntax-only detection as domain-robust. [dependency-distance-2411]
- DISCONFIRMING EVIDENCE, vendor self-correction: GPTZero's own documentation states it moved away from pure statistical perplexity/burstiness as of autumn 2023 toward a multi-signal/deep-learning architecture — an implicit admission that raw burstiness/perplexity thresholds were insufficiently accurate and are gameable, corroborating rather than contradicting the burstiness finding already in this corpus's [[making-ai-assisted-prose-not-read-as-machine-generated]] entry (§5.2). [gptzero-burstiness-retirement]
- Domain-regeneration research (arXiv:2505.07784) extends syntactic-structure detection beyond POS-tag-only prior work into full parse-tree metrics (parse depth, unique dependency-tag/constituency-label counts, Yngve branching-direction scores, left/right-branching ratios) across multiple text domains — evidence the field is actively moving past flat vocabulary/POS counts toward tree-shape metrics, though exact numeric results were not independently extracted in this sweep. [domain-regeneration-2505]
- NEGATIVE RESULT: no dedicated academic paper was found naming "appositive" or "summary-clause closer" as an AI tell under that exact framing — this specific vocabulary does not appear to exist in the literature searched; only generic NLP definitions of appositives surfaced. Similarly, "concessive pivot" as an exact term is not established academic vocabulary — it appears only in one unverified practitioner source (Bloomberry, methodology not independently confirmed) describing what the academic/Wikipedia literature covers under negative-parallelism and hedging-density framing instead.
- Wikipedia's page does NOT have a section specifically isolating content NOUNS from verbs/adjectives — its vocabulary catalogue mixes parts of speech together by era (delve/boasts/bolstered=verbs; crucial/pivotal/meticulous=adjectives; landscape/tapestry/testament/interplay/intricacies=nouns) with no noun-specific subsection or noun-specific citation. This is a confirmed, not merely unsearched, gap. [wikipedia-signs-of-ai-writing]

## SOURCES

**wikipedia-signs-of-ai-writing**
URL: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
Accessed: 2026-08-04
Quote: (§3.2, paraphrased from page structure) systematic replacement of "is/are" with "serves as / stands as / marks / functions as", cited to Huang and Geng with a >10% documented decrease in plain copula use in 2023 academic writing.

**reinhart-pnas-2025**
URL: https://arxiv.org/abs/2410.16107 (open-access preprint; published version at https://www.pnas.org/doi/10.1073/pnas.2422455122 returned 403 on direct fetch)
Accessed: 2026-08-04
Quote: (paraphrased from secondary coverage/abstract) present-participial clauses used at 2-5x human rate, GPT-4o at 5.3x; nominalizations at 1.5-2x human rate; agentless passive at half the human rate for GPT-4o.

**juzek-ward-rlhf-2508**
URL: https://arxiv.org/html/2508.01930v1
Accessed: 2026-08-04
Quote: overused nouns with occurrences-per-million deltas: "reliance" 1.2→40.1 opm (+3,193.6%), "generalizability" 2.4→78.5 opm (+3,124%); 400-participant human-preference validation found raters preferred text containing these words 52.4% vs 47.6% (p<0.01).

**prdetect-acl2025**
URL: https://aclanthology.org/2025.findings-naacl.464/
Accessed: 2026-08-04
Quote: (paraphrased) syntax-tree features are comparatively robust to paraphrasing-attack perturbation relative to lexical/embedding detectors, tested on HC3 and a GPT-3.5-mixed dataset.

**dependency-distance-2411**
URL: https://arxiv.org/pdf/2411.06248
Accessed: 2026-08-04
Quote: (paraphrased) ChatGPT sentences show measurably longer dependency distances (higher parse-tree complexity) than human text.

**discourse-motifs-2402**
URL: https://arxiv.org/html/2402.10586
Accessed: 2026-08-04
Quote: (paraphrased) hierarchical discourse-tree features extracted via DMRST/RST improve human-vs-machine classification including on out-of-domain data.

**liang-non-native-bias**
URL: https://arxiv.org/pdf/2304.02819 (also published in *Patterns*, Cell Press, 2023)
Accessed: 2026-08-04 (via search synthesis; direct PDF fetch failed as unparseable binary, findings cross-checked against known publication record)
Quote: 61.3% average false-positive rate across 7 GPT detectors on 91 real TOEFL essays; vocabulary-enrichment intervention dropped false positives from 61.22% to 11.77%.

**gptzero-burstiness-retirement**
URL: https://gptzero.me/news/perplexity-and-burstiness-what-is-it/ ; https://support.gptzero.me/articles/9585228410-how-do-i-interpret-burstiness-or-perplexity
Accessed: 2026-08-04
Quote: (vendor documentation, paraphrased) GPTZero moved from pure statistical perplexity/burstiness to a multi-signal deep-learning architecture as of autumn 2023.

**domain-regeneration-2505**
URL: https://arxiv.org/html/2505.07784
Accessed: 2026-08-04
Quote: (paraphrased) extends prior POS-tag-only analysis into full parse-tree metrics — parse depth, dependency/constituency-label counts, Yngve branching scores — across multiple text domains.

## SYNTHESIS

The owner's instinct was right, and the prior lane's "style-words-only" framing was **partly right but overstated as a gap in the literature specifically — it was accurate about Wikipedia's vocabulary list and about Kobak et al., but wrong as a claim about the wider field.** The academic syntactic-detection literature (Reinhart et al./PNAS, PRDetect, the dependency-distance and discourse-motif papers) has been measuring structure — participial clauses, nominalization, dependency-tree depth, discourse-relation hierarchy — with real corpus numbers since at least 2024, running in parallel to but largely uncited by the vocabulary-list catalogues (Wikipedia, Kobak et al., Juzek & Ward's own lexical work). The two literatures don't cross-reference each other much, which is presumably why a lane surveying "published AI-tell research" through the vocabulary-catalogue door would conclude the field is style-words-only: it's the door that was checked, not the room.

The richest SINGLE source for a working list of structural tells remains Wikipedia's "Signs of AI writing" — not because it's the most rigorous (its formatting-level tells are uncited editorial observation), but because it's the only place that already does the work of naming specific constructions (three distinct negative-parallelism variants, not one; a Grok-specific "rather than" signature) at the granularity a practical linter needs, while also citing external studies for its higher-confidence claims and explicitly flagging what does NOT reliably discriminate.

The most important structural finding for anyone building a detector or a style gate is Reinhart et al.'s: **structural tells are house-specific, not universal.** A rule tuned on GPT-4o's passive-voice-avoidance will misfire on Llama-3, which does the opposite. This argues against any fixed cross-model rule list and toward the corpus-relative-detection principle this project's own `abstract-nouns` entry independently arrived at — measure against a reference corpus (of human writing, or of the target domain's own established usage), not against a universal ban-list, because "universal" is empirically false at the syntactic level, not just the lexical one.

The disconfirming evidence is not a minor footnote — it should gate deployment of any syntax/perplexity-based detector against real users. The Liang et al. non-native-writer false-positive mechanism (61.3%, with a demonstrated causal lever) is the single most consequential finding in this sweep: it shows the failure mode is not random noise but a direct consequence of what these tools measure (structural/lexical simplicity), meaning any structural-complexity-based rule inherits the same bias risk unless it's benchmarked against non-native and ESL-adjacent human writing specifically, not just native-English human baselines.

Related corpus entries: extends [[making-ai-assisted-prose-not-read-as-machine-generated]] (which already covers Wikipedia's page, Kobak et al., Juzek & Ward's original RLHF finding, and burstiness §5.2 — this entry adds the syntax-tree-level academic literature that entry didn't reach, plus the quantified noun data and the non-native-bias disconfirmation in more depth) and is a sibling to [[abstract-nouns-promoted-to-technical-terms-read-as-ai-because-vagueness-is-unfalsifiable]] (whose corpus-drift discriminator is independently supported here by Reinhart et al.'s house-specificity finding — both converge on "compare against a real reference corpus, not a universal list" from different empirical angles).
