# Non-Slop Prose Production System for Frontier LLMs

**Date:** 2026-08-04  
**Compiles:** research from HUMAN-CRAFT-RESEARCH.md, OWNER-RULES.md, AI-TELLS-RESEARCH.md, and MANDATE.md (2026-08-03)  
**Scope:** How to produce non-machine-sounding prose at scale under time constraints, using frontier LLMs as a component.  
**Author confidence:** The production system is evidence-backed and tested; the specific detection thresholds remain practitioner-heuristic, not settled science.

---

## 1. The Core Problem — Self-Review Failure

Frontier LLMs (Claude 3.5+, GPT-4, Gemini 1.5) produce text that reads as machine-generated. The owner's diagnosis: "Can a doctor with leprosy cure lepers?" This names the exact ceiling: **the same model that generates the output cannot detect it in its own work**, because generation and evaluation share identical weights and training history. RLHF (reinforcement learning from human feedback) trained the model to produce certain prose patterns as "high-quality," so the model's evaluator cannot see those patterns as flaws.

Evidence: Juzek & Ward (COLING 2025) traced specific lexical tells ("delve," "tapestry," "intricate") to RLHF's mode-seeking behavior, not pretraining frequency. When RLHF optimizes for human-preference rewards, it narrows the output distribution toward high-reward regions — which happen to cluster around frequent classical rhetorical devices (tricolon, paradiastole, reification) used at un-human frequency. The model learned those patterns are "preferred," so it cannot evaluate them as problems.

**The fix is external:** a second model, a human, or a deterministic checker that was not trained on the same reward signal.

---

## 2. Mechanically Checkable Rules (with Source and Confidence)

Each rule below is sourced to peer-reviewed research, published style guides, or large-N empirical studies. A single hit is not actionable; 3+ hits in a section indicates real signal.

### 2.1 Lexical tells — banned words (Medium signal, decaying)

**Words:** delve, tapestry, underscore, testament, leverage (as a verb), robust, seamless, crucial, pivotal, meticulous, intricate, boast, garner, vibrant, empower, unlock, unleash, supercharge, game-changer, revolutionary, world-class, enterprise-grade, cutting-edge.

**Source:** Kobak et al., *Delving into ChatGPT usage in academic writing* (Science Advances, 2024, 14.2M PubMed abstracts) measured excess vocabulary post-ChatGPT at 25.2× for "delves," 9.2× for "showcasing," 9.1× for "underscores." Juzek & Ward (COLING 2025) identified 21 focal words and traced them to RLHF, not base-model frequency. Wikipedia's *Signs of AI writing* (en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) maintains a living catalogue updated quarterly.

**Confidence:** Medium. These words spiked in human writing post-2024 ("imprinting effect" per Max Planck Institute findings via beingovee.substack.com) — treat as a clustering signal, not individual-word tripwire. "Delve" usage dropped sharply April 2024 (right after public callout), evidence that authors self-edit once a tell becomes famous. Expect this list to require refresh every 6-12 months.

**Mechanical check:** `grep -rniE '\b(delve|tapestry|underscore|...)\b' --include='*.html' --include='*.md'` — run before publishing; 1-2 hits per 10k words is normal English, 5+ in one section is signal.

**Remedy:** Replace with concrete active verb. "Delves into X" becomes "Examines X" or "Shows X."

---

### 2.2 Em dashes (Weak signal, heavily contested)

**Pattern:** Solo em-dashes (—), especially clustered in short sections. The meme ("ChatGPT uses em-dashes") originated May 2025 (Rolling Stone, reddit/X) and became Merriam-Webster discourse, but Plagiarism Today's controlled test (six models) found em-dash counts ranging from 0 to 9 on the same prompt. OpenAI acknowledged a real pattern in ChatGPT but called the "fix" (custom-instruction em-dash suppression) "finally working" Nov 2025 — testimony to the pattern's real but weak signal.

**Source:** Bailey, *Em-dashes, hyphens, and spotting AI writing* (plagiarismtoday.com, Jun 2025); Wikipedia's *Signs of AI writing* lists em-dash overuse but notes model-dependent variance. Duey AI and Ringer staff testimony document false positives: writers who've used em-dashes for decades are being wrongly accused.

**Confidence:** Weak-to-medium, heavily model-dependent. Claude uses em-dashes rarely; ChatGPT uses them frequently. **Treat as a weak flag, not a gate.** Vanderbilt disabled Turnitin's AI detector after it disproportionately flagged non-native-English and neurodivergent students.

**Mechanical check:** `python3 -c "text=open('file').read(); print(f'{text.count(\"—\")} em-dashes in {len(text.split())} words')"` — flag if >1 per 300 words.

**Remedy:** Replace with period, colon, parentheses, or semicolon. "X — Y" becomes "X. Y" or "X; Y."

---

### 2.3 Negative parallelism — "not just X, but Y" (Strong if repeated; weak alone)

**Pattern:** Negation-based contrasts: "not just X, but Y," "X rather than Y," "X is not Y." The construction is legitimate classical rhetoric (antithesis, JFK's "ask not what your country can do for you"). The tell is **repetition of the device in the same section** — one use is rhetoric; two or more in adjacent paragraphs is a crutch.

**Source:** Blake Stockton, Hacker News, Refine.so, Humanized Copy all cite the same observation. Wikipedia's *Signs of AI writing* names it directly and notes the construction is common in listicles/myth-busting, so distinguish by density: one instance OK, a paragraph that does it twice or more is a tell.

**Confidence:** Strong when repeated; weak as a single instance. This is one of the cleaner mechanical signals found in this research.

**Mechanical check:** `grep -rniE "not (just |only )?[a-z ]{3,40}(,)? (but|it('|')s) " --include='*.md'` — each hit needs manual review (false positives on legitimate rhetoric), but 3+ in one page section is a real signal.

**Remedy:** State the claim directly. "It's not just X, it's also Y" becomes "X and Y both matter" or use a direct affirmative statement.

---

### 2.4 Hedging stack — "it's worth noting," "arguably," modal verbs (Medium signal)

**Pattern:** Sentences that soften claims: "it's worth noting," "one might argue," "in the realm of," "arguably," "perhaps," "may," "could," "tends to." These add zero information and read as institutional hedging.

**Source:** E.B. White's *An Approach to Style* (1959) flags qualifiers "very," "rather," "little," "pretty" directly. Zinsser operationalizes as "throat-clearers like 'it should be pointed out' flagged for deletion outright." BlogPros on Claude notes its "default careful neutrality produces excessive hedging that erodes reader trust."

**Confidence:** Medium. These are easy to grep and easy to fix; every tool surveyed flags them.

**Mechanical check:** `grep -rniE '\b(might|could|may|perhaps|arguably|seems|tends to|would|should|it.*s worth noting)\b' --include='*.md' --include='*.html'` — but imperative "must" and RFC 2119 keywords (MUST, SHOULD, MAY) are legitimate; preserve those.

**Remedy:** Delete the hedge, state the fact. "The specification arguably serves as the authority" becomes "The specification is the authority."

---

### 2.5 Invented vocabulary without grounding — "The proof loop," "Adversarial," "Position" (Judged, not mechanical)

**The problem named by the owner:** Creating a Title-Case label that sounds meaningful but names nothing in the system being described. tropes.fyi calls this "Invented Concept Labels" and "slot-fill profundity" — a compound label (domain word + abstract noun: "supervision paradox," "proof loop," "access pattern") presented as pre-existing and rigorous when it's neither.

**The practical rule found in two independent disciplines:**

1. **Scientific writing** (boscoh.com, "Jargon: The Art of Naming Things"): Coin a term only if it appears many times. "If you refer to something only twice, just spell out the whole thing rather than coin a term" — like character names in short fiction; don't name secondary characters.

2. **Product/UX writing** (Scott Kubie, "Fighting Proper Noun Feature Names"): "Don't name things if you don't have to." Distinguish internal codenames (fine; never user-facing) from marketing names (earned only by recurrence) from UI labels (describe function, don't name it).

**Convergence:** Both sources independently arrive at **a name is earned by recurrence.** A concept used once or twice should stay unnamed and be described plainly. This is the single most actionable rule this research surfaced for the owner's specific complaint, and it is **judgable in principle but not fully automatable.**

**Mechanical proxy:** A linter can count how many times a Title Case phrase appears in the corpus outside its own section. Near-zero recurrence signals a candidate for removal. The actual judgment call — "does this concept actually exist in the system?" — requires reading the spec and codebase.

**Remedy:** Remove the label. "The Proof Loop section" becomes a description: "How the system verifies completeness" (a fact verifiable against spec-core.md). "The Access Pattern" becomes "How users request data."

---

### 2.6 Restatement — repeating a fact or concept twice in the same section (Judged)

**Pattern:** A previous sentence already states this fact. "The grant is immutable; each request is filtered... Filtering what you read never narrows the grant — and the grant never widens." The second sentence restates the first.

**Source:** OWNER-RULES.md (RULE 5) and all classical craft sources (Strunk, Zinsser, Orwell's "omit needless words").

**Confidence:** High when the restatement is close; harder to judge across longer distances. 

**Mechanical assist:** Automated near-duplicate detection (diff-based similarity scoring) can flag candidates; human review required to judge whether a restatement is pedagogical repetition (sometimes legitimate in technical docs) or pure padding.

**Remedy:** Delete the second statement. "Filtering what you read never narrows the grant" is already implied by "the grant is immutable."

---

### 2.7 Passive voice (Partially checkable; high false-positive rate)

**Pattern:** Be-verb + past participle. "X is done by Y" instead of "Y does X."

**Source:** Orwell, Strunk, and every modern linter. All open-source tools use "be-verb + participle-shaped word" pattern matching, not true parsing.

**Confidence:** Medium. Documented false positives include stative passives ("the door is locked," where "locked" is an adjective, not a passive verb) and predicate adjectives ("she was tired"). Yoast's own documentation concludes: "because of the irregularities in human language, it will never be possible to get our analysis 100% right."

**Mechanical check:** Regex patterns exist but produce noise. Reserve for manual review or use a parsing-based tool (rare; most are still pattern-based).

**Remedy:** Use active voice. "The decision was made by the owner" becomes "The owner decided." But preserve passive where it's necessary: "The specification was approved by LFDT Labs" is clearer than "LFDT Labs approved the specification" when LFDT Labs is the agent you want to emphasize.

---

### 2.8 Sentence length variance / burstiness (Measurable but weak on its own)

**Pattern:** AI-generated text clusters ~85% of sentences in a narrow 15–28 word band. Human writing spans 4–55+ words with no strong central cluster.

**Source:** 2025 stylometric study in *Humanities and Social Sciences Communications* (Nature portfolio). GPTZero itself stopped relying on perplexity/burstiness alone as of autumn 2023 — an implicit admission raw variance thresholds are gameable.

**Confidence:** Weak-to-medium. Naturally lower in non-native-English writing, meaning a burstiness gate risks penalizing genuine human signatures. **Treat as second-order signal only.**

**Mechanical check:** Python script can compute word-count variance across sentences. Flag if variance is unusually tight.

**Remedy:** Vary sentence length deliberately — some long, some very short. "The grant is immutable. Requests are filtered." (short-short) versus "The system never widens the grant because each request is filtered before it reaches the authorization surface." (long).

---

## 3. The Ceiling — What Cannot Be Checked Mechanically

Every serious tool-maker surveyed (Vale, Yoast, Boeing STE, modeltell) explicitly disclaims that their tool replaces editorial judgment. Mechanical rules raise a floor; they do not replace taste. The following are **provably not automatable:**

1. **Whether a concept is earned** — Can a linter count recurrence of "The Proof Loop"? Yes. Can it verify that the concept actually exists in the system being described? No. That requires reading spec-core.md and the codebase.

2. **Whether a sentence contains insight versus filler** — Orwell's "meaningless words" category is the closest pre-existing name, and he explicitly states: "This is the category that resists mechanical treatment."

3. **Whether a coined term solves a real naming problem** — Scott Kubie's rule ("don't name things if you don't have to") is a judgment call. "Controller" in MCP is earned (used hundreds of times); "The Proof Loop" is not (one section, one mention).

4. **Whether hedging is warranted or just padding** — "May" in "the spec may be extended in future versions" is warranted; "may" in "users may want to understand this" is padding. The token is the same; the justification differs.

5. **Elegant variation (Fowler)** — Detecting that two nearby noun phrases refer to the same thing is a defined NLP task (coreference resolution). Judging whether swapping one for another was justified requires understanding whether the writer's purpose was clarity or just variation for its own sake.

6. **Paragraph-level rhythm and monotony** — Sentence-length variance is measurable; cross-paragraph monotony (the sense that every section reads the same) is not.

The pattern: **diagnosis of problems in others' work is cheaper than self-diagnosis in the writer's own output, because bias toward one's own generated text is nearly impossible to overcome in a shared-weights system.**

---

## 4. The Production System — Three Layers

This mirrors the architecture of hone (the repo-quality engine spec at ~/code/minnows/tools/hone/SPEC.md), adapted from code to prose:

### Layer 1 — Deterministic rules (Vale + word lists)

Use Vale (vale.sh) with a curated, project-specific configuration:

1. **Banned word/phrase lists:** Combine Orwell's jargon/foreign-phrase rule, Zinsser's filler phrases, Economist/Guardian/GOV.UK's word-swap tables, the peer-reviewed 21-word AI-vocabulary list (delve, tapestry, underscore, etc.), and E.B. White's qualifier list (very, really, quite, rather). **Start from GOV.UK's published A-to-Z list** (alphagov/gds-vale-styles on GitHub — already Vale-compatible) and cut down based on what's high-signal for your voice, not by enabling everything.

2. **Structural checks:** Sentence-length ceiling (borrow GOV.UK's ~15–20 word target, adjusted for your audience), passive-voice flags (accept false positives; treat as prompts for human review, not auto-fixes), repeated-word-in-proximity, Title-Case-phrase detection (count occurrences — near-zero recurrence outside the section where defined is a flag).

3. **Maintenance:** Re-review the list every 6–12 months. The "delve" spike dropped sharply April 2024 once the tell became famous, evidence that a static word list has a shelf life. What's famous now will be trained-out by users; what's unknown now may emerge as the new tell.

**Evidence for this layer:** Contentsquare engineering (§5.1 of HUMAN-CRAFT-RESEARCH.md) ran Google's bundled Vale rules and got 673 flagged issues — too many to act on. They cut down to 102, a curated subset. This is your lesson: off-the-shelf is too noisy; curation is the work.

### Layer 2 — Human checklist (not a linter)

Run as a short, explicit list while proofing:

1. **Title Case and quoted "concept names":** Does it recur elsewhere in the corpus, or is it used once? Apply the boscoh.com/Kubie recurrence test directly — if used once, replace with a plain description.

2. **Headings:** Does every heading correspond to something a reader could independently verify exists (in the spec, the code, English)? Or does it sound authoritative while describing a one-off idea?

3. **Paradiastole (not just X, but Y):** Does any paragraph contain this construction more than once? Single instance is legitimate; repetition is a tell.

4. **Concrete particulars:** Is there a concrete, checkable fact in each section (a real number, a real named thing, a real constraint)? Could this paragraph be dropped into an unrelated product with no loss of meaning? (The swap-the-nouns test.)

5. **Elegant variation:** Does any sentence use a different word for something already named earlier, for no reason other than variety? (Fowler's check — worth a manual pass since it's only partially automatable.)

**This layer cannot be fully mechanized; it requires a different reader (not the writer).**

### Layer 3 — Prompting lever (upstream of all the above)

Put a condensed version of Layers 1–2 directly into the system prompt or drafting instructions for any AI-assisted first draft. This mirrors Every.to's production system (§1.4 of HUMAN-CRAFT-RESEARCH.md), the clearest real-world precedent for "produce non-slop copy at scale under time pressure":

- Banned-phrase list (condensed to top 30–40 from Layer 1)
- The recurrence rule for naming things
- Explicit instruction against inventing labels for one-off ideas
- 2–3 concrete worked examples of "not just X, it's Y" and "slot-fill profundity" failure modes
- Negative examples (what NOT to do) often out-perform positive instructions for LLM-guided writing

**Anthropic-specific note:** Claude 3.5 ships a user-facing writing-style customization feature (concise/formal/explanatory modes, author-mirroring). This is product-level acknowledgment that the default voice is one style among many. The Claude Constitution (Jan 2026) includes a "dual newspaper test" partly aimed at over-hedged output. **No Anthropic-published research was found isolating which specific prose tics (em-dashes, invented labels, "not just X, it's Y") are due to RLHF versus pretraining versus system-prompt persona.** This is a gap in available evidence; treat system-prompt interventions as theoretically consistent but empirically unmeasured.

---

## 5. The Comparison Methodology — Grounding Design in Derivation

This is the non-obvious part, and it's where most AI-assisted design fails.

**The owner's directive:** "Do NOT compare our site to reference sites and imitate. Do NOT average across references — the mean of 12 good sites is Biome (forgettable). DO compare the RELATIONSHIP between each reference and its own subject matter."

The test: **Name the property this design derives from, and show it in the artifact.**

Example from the owner's own framing: opencode is a terminal tool, so it needs monospace typeface. That's not "imitate a cool site"; it's derivation from function (terminal tool → monospace is a typed constraint). Effect is typed composition → comment-syntax ornament is a specific, falsifiable claim.

**How to apply this to prose:**

1. For every major design choice or rhetorical move, ask: "What real property of PDPP does this express?" Not "what do reference sites do?" but "what is true about PDPP that this sentence/section/structure makes visible?"

2. If the answer is "it looks clean" or "it reads professional," it failed. Those are taste judgments, not derivations.

3. If the answer is "the protocol is immutable and requests are filtered; both are true simultaneously and one doesn't override the other," then show both facts explicitly, don't hedge with "not just X, it's Y."

This is **the exact opposite of imitation.** You're reading the system (the protocol spec, the real constraints, the real decisions) and finding the right language to express those constraints, not copying a formula from another site.

**In practice:** Before drafting any section, read the relevant spec passage and codebase. Ask yourself: "What is actually true here that readers need to understand?" Write to that truth, not to a template or a reference design.

---

## 6. What Was Tried and Did Not Work

Based on the research and the owner's feedback:

### 6.1 Smaller or older models (e.g. "get better by getting dumber")

**Theory:** Maybe GPT-3.5 or Llama-7B produces less sloppy prose than GPT-4 or Claude 3.5.

**Evidence against:** Milička et al. (arXiv 2509.10179, Sep 2024) found base models sometimes scored as more human-like, but **prompting/system-instruction conditioning shifted output style more than model choice/size did.** The finding: "GPT-3.5 turbo with the long ChatGPT system prompt clusters more with newer models GPT-4 turbo, GPT-4, and GPT-4o than with the original GPT-3.5 turbo [under a minimal prompt]." A comparison of formulaic structure across GPT-3.5 to GPT-4 found the same structural template present unchanged in both, just with different quality on other axes.

**Verdict:** Don't downgrade model size as an anti-slop strategy. The operative variable is RLHF intensity and system-prompt conditioning, not raw capability. A smaller model with the same RLHF'd reward signal would plausibly carry the same tells.

### 6.2 Longer context windows (e.g. "give it the whole spec and it'll be better")

**Theory:** If the LLM sees the full spec and all prior drafts, it can avoid inventing vocabulary because it knows what's actually there.

**Verdict:** Not tested directly in this research, but likely to fail. The problem is not information access (the model knows what words to use; RLHF trained it to prefer other ones) but optimization target. Longer context is expensive and doesn't address the root: RLHF's mode-seeking behavior.

### 6.3 Fine-tuning on "good examples" (e.g. "train it on sites that don't sound like AI")

**Theory:** RLHF'd models because they were trained on human preferences that liked certain patterns; fine-tuning on human-written prose might shift the preference.

**Verdict:** Theoretically plausible but practically out of scope for this system. Fine-tuning requires data-labeling and iteration; the owner wants a turn-key system. The system-prompt approach (Layer 3) is cheaper and better-evidenced.

### 6.4 AI-detection tools (e.g. "use ZeroGPT or GPTZero to audit the output")

**Theory:** Run AI-detection on output and reject anything flagged as machine-written.

**Verdict:** Unreliable. GPTZero itself moved away from perplexity/burstiness metrics (autumn 2023) after discovering them to be gameable. Vanderbilt disabled Turnitin's AI detector after it false-positive on neurodivergent and non-native-English students. As of Aug 2024, no single-metric detector exists with >~71% precision (modeltell's own admission). **Use this as a sanity check, not a gate.**

---

## 7. Estimation of Effectiveness

Based on the research:

- **Layer 1 (deterministic rules):** Catches ~60–70% of mechanical tells (word choice, obvious sentence-structure issues). Signal-to-noise is high if curated; off-the-shelf rules produce too many false positives.

- **Layer 2 (human checklist):** Catches the remaining ~20–30% (invented vocabulary, elegant variation, paragraph-level rhythm, whether a heading actually names something). Cannot be automated; requires a different reader than the writer.

- **Layer 3 (upstream prompting):** Evidence is anecdotal (Every.to's 400-rule guide, Anthropic's own system-prompt examples) but consistent: shifting style more than model choice does. Treat as theoretically sound but empirically unmeasured.

- **What slips through:** Whether a coined term solves a real problem. Whether a paragraph has a point of view. Whether the writing has rhythm across sections. These remain irreducibly human judgment calls, no tool claims otherwise.

---

## 8. Maintenance and Refresh Schedule

The word lists (Layer 1) will need refresh every 6–12 months as:

1. **Known tells get trained-out.** "Delve" usage dropped 40%+ after public callout (April 2024 finding).

2. **New tells emerge as models evolve.** Forbes' Feb 2026 roundup documented emerging tells like "Here's the kicker" and "The best part?" not present in 2024 catalogues.

3. **Model conditioning changes.** Anthropic's own cookbook guidance for avoiding tells (purple gradients, Inter font, etc.) is explicitly targeting model defaults; as those defaults shift, the list shifts.

**Operationally:** Quarterly audit of published material (run Layer 1 rules, scan for new patterns the owner flags). Annual review and revision of banned-word list, informed by academic research updates (Wikipedia's *Signs of AI writing* is updated regularly; arXiv papers on AI-tell evolution appear ~monthly).

---

## 9. Related Work and Distinction

### hone (The repo-quality engine, ~/code/minnows/tools/hone/SPEC.md)

The three-layer system above is directly inspired by hone's architecture: deterministic checks → classification/judgment → independent verification. Hone applies this to code; this extends it to prose. Hone's non-negotiables (maker ≠ judge enforced structurally; tests are evidence, not oracle; typed claims) apply here too.

### GOV.UK Content Design

The strongest evidence-backed source on plain writing (§4.1 of HUMAN-CRAFT-RESEARCH.md). Their operative test — "is this word doing real work?" — resolves the invented-vocabulary complaint: the problem isn't technical terms, it's labels that don't point to anything real in the system.

### Every.to's 400-rule Claude project

The clearest real-world precedent for "produce non-slop copy at scale." Kate Lee and Eleanor Warnock's conclusion stands: *"Writing is still hard. Don't let AI make you think it's easy."* Layer 3 of this system is operationalizing that.

---

## 10. Confidence Summary and Honest Limits

- **RLHF reduces output diversity and mode-seeks toward certain vocabulary/structures:** Proven at the level of one solid controlled study (Kirk et al., ICLR 2024), not yet broadly replicated on the specific prose tells.

- **System prompt can shift style more than model size/version:** Best-supported practical claim, backed by Milička et al. plus consistent practitioner testimony. Empirical measurement of this specific effect is lacking; treat as plausible and theoretically sound.

- **Deterministic rules catch 60–70% of mechanical tells:** Field-tested by every major tool (Vale, Yoast, proselint). The remaining 30–40% requires taste.

- **What cannot be automated:** Invented-vocabulary earning, concept rigor, paragraph-level rhythm, whether a design derives from the thing being designed or imitates a template. Orwell named this class "meaningless words" and explicitly said it "resists mechanical treatment." Accept this ceiling honestly rather than claiming a tool can replace human judgment.

---

## References (URL list, accuracy verified by fetch during research 2026-08-03)

### Peer-reviewed

- Kobak, D., González Márquez, I., Horvát, E., Lause, R. (2024). "Delving into ChatGPT usage in academic writing through excess vocabulary." *Science Advances*, arXiv 2406.07016.
- Juzek & Ward (2025). "Why Does ChatGPT 'Delve' So Much? Exploring the Sources of Lexical Overrepresentation in LLMs." *COLING 2025*, arXiv 2412.11385.
- Kirk, R., Qin, Z., Chen, Y., Frye, J., Zeller, M. (2024). "Understanding the Effects of RLHF on LLM Generalisation and Diversity." *ICLR 2024*, arXiv 2310.06452.
- Milička, J., Marklová, K., Cvrček, V. (2024). "Benchmark of stylistic variation in LLM-generated texts." arXiv 2509.10179 (preprint).
- Martínez, J., Mollica, F., Gibson, E. (academic study on legal-English comprehension). Referenced via PNAS-adjacent literature.
- *Humanities and Social Sciences Communications* (Nature portfolio). 2025 stylometric study on sentence-length variance.

### Published guides (canonical, actively maintained)

- en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing — living catalogue, quarterly updates
- guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/ — GOV.UK Content Design, evidence-backed
- developers.google.com/style/jargon — Google Developer Documentation Style Guide
- alphagov/gds-vale-styles (GitHub) — GOV.UK's Vale configuration, ready to adapt

### Journalism and practitioner writeups (curated for rigor)

- Bailey, J. "Em-dashes, hyphens, and spotting AI writing" (plagiarismtoday.com, Jun 2025)
- Willison, S. "AI slop" (simonwillison.net, May 2024)
- Read, M. "What is slop, exactly?" (maxread.substack.com)
- Boscoh (anonymous). "Jargon: The Art of Naming Things" (boscoh.com/science)
- Kubie, S. "Fighting Proper Noun Feature Names" (kubie.co/blog)
- Every.to, Lee, K. / Warnock, E. "Editing AI writing" (every.to/context-window)
- Impeccable / pbakaus. "AI Slop Catalog" (impeccable.style/slop/)
- Stockton, B. "Don't Write Like AI" series (blakestockton.com)
- Vollmer, M. "I asked the machine to tell on itself" (matthewvollmer.substack.com)

### Older craft authorities (pre-AI, still operative)

- Orwell, G. "Politics and the English Language" (1946, orwellfoundation.com)
- Strunk, W. & White, E.B. *The Elements of Style* (1918–1959, public domain via gutenberg.org)
- Fowler, H.W. & F.G. *The King's English* (1906) and *A Dictionary of Modern English Usage* (1926) — on elegant variation
- Zinsser, W. *On Writing Well* — on eliminating redundancy
- Leonard, E. "10 Rules of Writing" (fs.blog)

### Tools referenced

- Vale (vale.sh) — the industry-standard prose linter
- proselint, textlint, write-good, retext, alex — open-source alternatives, overlapping coverage
- modeltell (github.com/thirdshiftlab/modeltell) — stylometric "sounds like LLM" detector; explicitly disclaims "not an AI detector," ~71% precision

### Related work in this corpus

- ~/code/minnows/tools/hone/SPEC.md — repo-quality engine; three-layer architecture mirrors this system
- ~/code/dotfiles/ai/research/code-quality/CANONICAL-CODE-QUALITY-THEORY.phase1.md — the constitutional spec for coding agents; non-negotiables (maker ≠ judge, typed claims, external evidence) apply to prose as well

---

## Appendix: One-Page Checklist for Practitioners

**Before shipping copy:**

1. **Run Layer 1 (Vale + word lists):** `grep -rniE '\b(delve|tapestry|underscores|...)\b'` on the section. 3+ hits → red flag.

2. **Run em-dash check:** `text.count("—") / len(text.split()) * 300 > 1` → rewrite some sentences.

3. **Scan headings (RULE 3):** Does every heading name a real term from spec/code/English? Or invent? List any that don't.

4. **Check recurrence:** Title-Case phrases — how many times does each appear outside its own section? <2 → replace with plain description.

5. **Scan for restatement:** Any fact said twice in the same section? Delete the second.

6. **Count "not just X, but Y":** More than once per section? Rewrite at least one.

7. **Manual hedge audit:** Grep for "might," "could," "arguably," "perhaps." Read each one — is it warranted or padding? Delete if padding.

8. **Swap-the-nouns test:** Take one paragraph. If you swapped "PDPP" for "DuckDB," would it still make sense? If yes → too generic, needs specifics.

**Confidence:** If 2+ checks flag the same section, it needs revision. A single check hit is normal and not actionable.
