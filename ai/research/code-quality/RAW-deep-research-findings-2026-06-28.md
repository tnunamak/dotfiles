# Raw deep-research findings — code-quality canon (wf_4600c07c-716, 2026-06-28)

Backing evidence for CANONICAL-CODE-QUALITY-THEORY.md. ~30 sourced claims; 2 at 3-0 adversarial confirmation.
NOTE: the harness mislabeled well-sourced-but-not-re-voted claims as "refuted" — they were NOT contradicted
(rate-limiting cut the re-vote round). Treat "refuted" list below as well-sourced-pending-confirmation.

## SUMMARY

The requester's naive definition — "minimize incidental complexity + maximize expressiveness (power per line)" — is directionally correct but incomplete and partly self-undermining, and the canon confirms the needed correction. The complexity-minimization half is the most strongly grounded pillar: Brooks's essence/accident distinction (the canonical origin of essential-vs-accidental complexity) and Hickey's "Simple Made Easy" together establish that high-quality code minimizes *incidental* complexity specifically, and — crucially — that "simple" (absence of interleaving/braiding) is an OBJECTIVE property, distinct from "easy" (nearness/familiarity), which is RELATIVE/subjective taste. This is the spine of the theory: minimal complexity is objectively assessable; familiarity is not. The "power per line" half is where the definition inverts into harm — the canon (and exemplars like Carmack's long, boring functions vs APL/code-golf) points toward expressiveness as leverage per unit of COGNITIVE LOAD, not per line, with Ousterhout's deep-vs-shallow modules and Hickey's reasoning-limits argument as the load-bearing support. Two claims survived full 3-0 adversarial verification (Brooks essence/accident origin; Hickey simple=objective/easy=relative); the broader pillar structure, the Clean-Code-vs-Ousterhout extraction tension, and the empirical layer (FP-reduces-defects does NOT survive reanalysis) are well-sourced to primary documents but received thinner adversarial confirmation in this round and are reported at correspondingly lower confidence.

## CONFIRMED + WELL-SOURCED CLAIMS

### [1] (conf=high vote=3-0)
PILLAR 1 (strongest-grounded): High-quality code minimizes INCIDENTAL/ACCIDENTAL complexity specifically — not all complexity. Brooks's essence/accident split is the canonical origin of this distinction and the direct anchor for the requester's first pillar. The naive definition's 'minimize incidental complexity' half is CONFIRMED as objective and central.

> Brooks (No Silver Bullet, 1986/87): 'Following Aristotle, I divide them into essence — the difficulties inherent in the nature of software — and accidents — those difficulties that today attend its production but that are not inherent.' Verbatim-confirmed against two independent full-text copies; corroborated by acolyer.org, Fermat's Library, and UNC TR86-020 that this is genuinely Aristotelian (essential=definitional/inherent, accidental=removable without changing identity) and is THE standard citation for the essential-vs-accidental distinction. Implication for the theory: the pillar must ta

Sources: https://worrydream.com/refs/Brooks_1986_-_No_Silver_Bullet.pdf, https://www.cgl.ucsf.edu/Outreach/pc204/NoSilverBullet.html

### [2] (conf=high vote=3-0)
PILLAR 1 corollary (the objectivity claim that makes the whole theory defensible): 'Simple' is OBJECTIVE (absence of interleaving/braiding; etymology sim-plex = one fold/braid) and is distinct from 'easy', which is RELATIVE (nearness/familiarity; etymology = to lie near). Therefore minimal complexity is an objective code-quality property, while familiarity/idiom-preference is subjective taste. This resolves the requester's 'objective vs taste' axis at the root.

> Hickey (Simple Made Easy, Strange Loop 2011): 'So simple is actually an objective notion... if something is interleaved or not, that is sort of an objective thing'; slide lists 'Objective' under Simple, 'sim-plex / one fold/braid'. For easy: 'easy is relative... It is a relative term'; slide 'Easy is relative', 'ease < aise < adjacens / lie near'. Clincher: 'unlike simple where we can go and look for interleavings, look for braiding, easy is always going to be: easy for whom, or hard for whom?' This is the philosophical keystone: it lets the theory claim that decomplecting is objectively asses

Sources: https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy-mostly-text.md

### [3] (conf=medium vote=0-0)
DECOMPLECTING is the mechanism behind Pillar 1, and it generalizes beyond Lisp: complexity IS complecting (interleaving/entwining/braiding things that should be independent); composition (placing simple things side by side) is the path to robustness. The requester's theory must be — and is — consistent with this even where it diverges from Clojure specifics. The 'minimize incidental complexity' pillar is really 'avoid complecting independent concerns.'

> Hickey defines complexity as 'complecting' — interleaving/braiding — and asserts complecting is THE source of complexity, to be avoided up front; composition is the alternative. He also distinguishes INCIDENTAL complexity ('yielded by the constructs/tools we choose', 'your fault') from problem/essential complexity, and insists code be judged by its long-term ARTIFACT (maintainability, changeability) not by the authoring EXPERIENCE (programmer convenience) — which maps cleanly onto Brooks's essence/accident and the minimal-incidental pillar. Sourced to the primary transcript and uncontradicted,

Sources: https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy-mostly-text.md

### [4] (conf=medium vote=0-0)
PILLAR 2 CORRECTION (the requester's hypothesis is right): expressiveness is leverage per unit of COGNITIVE LOAD, not per line. 'Power in fewest lines' inverts into harm; the correct invariant is human-reasoning capacity. This is grounded in Hickey's reasoning-limits argument and Ousterhout's deep-vs-shallow module formalization, and matches the Carmack-vs-APL exemplar tension the requester raised.

> Hickey: humans 'can only consider a few things at a time' and intertwined things must be considered TOGETHER, so complexity combinatorially destroys understanding — the limit being reasoned-about is cognitive, not textual. Ousterhout formalizes 'deep' vs 'shallow' modules: a good unit replaces a large cognitive load (reading the implementation) with a small one (learning a simple interface), and subdivision is only worthwhile while functionality-hidden-per-interface stays high. Together these reframe expressiveness as leverage-per-cognitive-load: code-golf/APL maximizes power-per-line while ma

Sources: https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy-mostly-text.md, https://github.com/johnousterhout/aposd-vs-clean-code

### [5] (conf=medium vote=0-0)
PILLAR 3 (designed-for-change / information hiding / locality of reasoning) is confirmed and originates with Parnas: decompose systems by HIDING design decisions likely to change — NOT by processing steps/flowchart. A module is a 'responsibility assignment', decoupled from runtime call structure. This is the falsifiable mechanism by which good decomposition reduces change cost.

> Parnas ('On the Criteria To Be Used in Decomposing Systems into Modules', 1972): each module should hide one difficult or change-likely design decision; its interface reveals as little as possible about internals. The falsifiable demonstration: under flowchart decomposition a single design change (in-core storage format) ripples through EVERY module; under information hiding the same change is confined to the one owning module — an objective, mechanism-level reduction in change cost. A module is a responsibility assignment, not a subroutine, decoupling design boundaries from execution flow. Pr

Sources: http://sunnyday.mit.edu/16.355/parnas-criteria.html

### [6] (conf=medium vote=0-0)
KEY TENSION (the central genuine expert disagreement, not folklore): Uncle-Bob-style aggressive function extraction (functions of 2-4 lines, one-line bodies, the 'One Thing Rule') vs Ousterhout's warning that this produces SHALLOW, ENTANGLED methods that are HARDER to understand. The disagreement is real and is about the OBJECTIVE criterion for the right grain of decomposition. Clean Code carries real value AND real, well-known objections — the theory must be even-handed.

> In the recorded Ousterhout/Martin debate, both agree over-decomposition is POSSIBLE but disagree on the threshold: Martin's extraction rule ('extract if you can name it and it does less than the original') is rejected by Ousterhout as lacking guardrails because 'anything can be named.' Ousterhout's counter-criterion is depth (functionality-hidden-per-interface). The empirical complaint study (arXiv 2507.19721) corroborates that the problem in practice is rigid MANDATORY enforcement, not the principles: 84% of 460 developer complaints fall into 'management'/'tool' categories; mandatory-policy o

Sources: https://github.com/johnousterhout/aposd-vs-clean-code, https://arxiv.org/pdf/2507.19721

### [7] (conf=medium vote=0-0)
PILLAR (FP contribution, correctly scoped): functional style raises quality chiefly through MODULARITY — Hughes argues modularity is the central determinant of quality and that higher-order functions and lazy evaluation are the 'glue' enabling composition. Backus argues imperative/von-Neumann languages lack useful mathematical properties for REASONING about programs. BUT the empirical claim that FP/static-typing reduces DEFECTS does NOT survive rigorous reanalysis — this is a critical honesty correction.

> Hughes ('Why Functional Programming Matters'): modularity is the key to quality/productivity; FP's advantage is higher-order functions + lazy evaluation as composition glue, NOT merely absence of side effects. Backus (Turing lecture): imperative languages are 'fat and weak' partly due to lacking mathematical properties for reasoning. CRITICAL counter-evidence: the famous Ray et al. (FSE 2014) 'functional/typed languages have fewer defects' finding does NOT hold under reanalysis (Berger/Vitek et al., TOPLAS 2019): languages with a defect association drop from eleven to four; surviving effects a

Sources: https://www.cse.chalmers.se/~rjmh/Papers/whyfp.html, https://fermatslibrary.com/p/15a1da0a, https://janvitek.org/pubs/toplas19.pdf

### [8] (conf=medium vote=0-0)
MEASURABLE vs JUDGED boundary (answers deliverable #4): very little of code quality is mechanically measurable; the empirical record shows popular metrics are weak proxies and rigid thresholds backfire. Cognitive complexity (the human-load notion) is the right target but is largely human/model-judged, not captured by line-count or cyclomatic complexity. Operationalization (later phase) should GUIDE, not GATE.

> Three independent strands converge: (1) automated clean-code checkers emit many false positives and 'fixing' them can degrade quality (arXiv 2507.19721); (2) hard size thresholds (the 50-line rule) are the most-resented and hardest-to-apply because simple limits collide with genuinely hard tasks; (3) language/typing→defect associations are negligible or non-reproducible (TOPLAS 2019), undercutting metric-based quality folklore. Ousterhout's depth and Hickey's interleaving are the objective TARGETS, but assessing them requires judgment (looking for braiding, counting functionality-hidden-per-in

Sources: https://arxiv.org/pdf/2507.19721, https://janvitek.org/pubs/toplas19.pdf, https://github.com/johnousterhout/aposd-vs-clean-code

### [9] (conf=? vote=1-0)
Brooks identifies the ESSENCE of software as an abstract conceptual construct, and locates the hard part of building software in the specification/design/testing of that conceptual construct rather than in its representation in code — implying that conceptual clarity, not syntactic surface, is the true locus of quality.

### [10] (conf=? vote=1-0)
Brooks names four irreducible ESSENTIAL properties of software — complexity, conformity, changeability, and invisibility — and argues complexity is an essential (not accidental) property such that abstracting it away abstracts away the essence. This both grounds and constrains the 'minimize complexity' pillar: some complexity is irreducible, so the theory must target incidental (accidental) complexity specifically.

### [11] (conf=? vote=1-0)
Brooks attributes the largest historical productivity/reliability/simplicity gains specifically to advances that removed ACCIDENTAL complexity — high-level languages (credited with ~5x productivity by freeing programs from accidental complexity), time-sharing, and unified programming environments (Unix/Interlisp) — providing concrete evidence that the highest-leverage quality improvements come from eliminating incidental complexity that 'was never inherent in the program at all.'

### [12] (conf=? vote=0-0)
Hickey defines complexity as 'complecting' (interleaving/entwining/braiding things together) and asserts that complecting is THE source of complexity, to be avoided in the first place; composition (placing simple things together) is the path to robust software. This is the decomplecting pillar the research question requires the theory be consistent with.

### [13] (conf=? vote=0-0)
Hickey argues human reasoning is severely and roughly uniformly limited ('we can only consider a few things at a time'), and that intertwined things must be considered together, so complexity combinatorially undermines understanding. This directly supports re-framing 'expressiveness' as leverage per unit of cognitive load rather than per line.

### [14] (conf=? vote=0-0)
Hickey distinguishes 'incidental' complexity (yielded by the constructs/tools we choose, 'your fault') from problem/essential complexity, and insists code must be judged by its long-term ARTIFACT (quality, maintainability, changeability) not by the authoring experience (programmer convenience). This matches Brooks's essential-vs-accidental framing and the minimal-incidental-complexity pillar.

### [15] (conf=? vote=0-0)
Parnas's central thesis: systems should NOT be decomposed by processing steps/flowchart; instead each module should be designed to hide one difficult or change-likely design decision. This is the origin of 'information hiding' and the 'modularize around what is likely to change' principle the research question attributes to him.

### [16] (conf=? vote=0-0)
The information-hiding criterion is defined concretely: every module is characterized by a design decision it conceals from all others, and its interface is chosen to reveal as little as possible about its internals — directly supporting the theory's 'information hiding / design-for-change' pillar.

### [17] (conf=? vote=0-0)
Information hiding objectively localizes change: under the flowchart decomposition a single design change (in-core storage format) ripples through every module, while under information hiding the same change is confined to the one owning module. This is the falsifiable mechanism by which the criterion reduces change cost.

### [18] (conf=? vote=0-0)
A module is a 'responsibility assignment,' not a subprogram/subroutine — decoupling the conceptual decomposition unit from runtime call structure. This grounds the claim that good decomposition is about design boundaries, not execution flow, and that modules need not map to processing phases.

### [19] (conf=? vote=0-0)
Ousterhout argues that Clean Code's method-length advice (functions of 2-4 lines, one-line if/while bodies) drives over-decomposition into 'shallow' interfaces and 'entangled' methods that are HARDER to understand, directly contradicting Martin's 'smaller is better' rule — establishing the central abstraction-vs-locality / extraction tension as a genuine expert disagreement, not folklore.

### [20] (conf=? vote=0-0)
The two authors agree it is POSSIBLE to over-decompose code but disagree on the threshold: Martin's operational rule for extraction is the 'One Thing Rule' (extract if the extracted code can be given a descriptive name and does less than the original), which Ousterhout rejects as lacking guardrails because 'anything can be named.' This pinpoints that the disagreement is about an objective criterion for the right grain of decomposition.

### [21] (conf=? vote=0-0)
Ousterhout formalizes 'deep' vs 'shallow' modules as the real measure of decomposition quality: a good method replaces a large cognitive load (reading the implementation) with a small one (learning a simple interface); subdivision is only worthwhile while functionality-hidden-per-interface stays high — grounding 'expressiveness as leverage per unit of cognitive load' rather than per line.

### [22] (conf=? vote=0-0)
Practitioner critiques of Clean Code in practice center NOT on the principles themselves but on rigid, one-size-fits-all MANDATORY enforcement: 84% of 460 developer complaints fall into the 'management' and 'tool' categories, with the single largest subcategory being objections to mandatory policy (178 responses), implying that quality rules imposed as universal hard thresholds backfire.

### [23] (conf=? vote=0-0)
Hard size thresholds — specifically the rigid 50-line function rule — are the most-resented and hardest-to-apply Clean Code constraint in practice, because simple-to-state limits collide with genuinely difficult tasks; this is direct evidence that Uncle-Bob-style function-shrinking advice can become harmful when treated as an inviolable metric rather than context-sensitive guidance.

### [24] (conf=? vote=0-0)
Automated clean-code checking tools materially misfire: they emit many false positives, and 'fixing' those false positives can actually degrade code quality — showing the gap between mechanically MEASURABLE proxies and true code cleanliness, and arguing tools should guide rather than gate/assess.

### [25] (conf=? vote=0-0)
Hughes argues that modularity is the central determinant of software quality and productivity, and that functional languages matter precisely because they push back the conceptual limits conventional languages place on how problems can be modularized.

### [26] (conf=? vote=0-0)
Hughes attributes functional programming's quality advantage specifically to two features — higher-order functions and lazy evaluation — which he argues contribute greatly to modularity (i.e. the 'glue' that lets small parts be composed into solutions), rather than to the mere absence of side effects.

### [27] (conf=? vote=0-0)
The famous Ray et al. (FSE 2014) finding — that functional languages and static/strong typing are associated with fewer software defects — does not hold up under rigorous reanalysis; corrections cut the number of languages with a defect association from eleven to only four, and even those effects are negligibly small.

### [28] (conf=? vote=0-0)
Even where a statistically significant association between language and defects survives reanalysis, its PRACTICAL significance is negligible — statistical significance was an artifact of large sample size, not a meaningful real-world effect; the predicted differences in bug-fixing commits were 'consistently small.'

### [29] (conf=? vote=0-0)
The original study's claim that functional languages have a smaller relationship to defects than procedural or scripting languages (RQ2) could not even be reproduced — the language-class results were corrupted by classification errors, making the published results 'meaningless.'

### [30] (conf=? vote=0-0)
Causation between programming language choice and defect rates is not supported by the data, and too many uncontrolled sources of bias remain to permit any meaningful comparison of bug rates across languages — yet many downstream works cited the original to assert exactly such a causal link.

### [31] (conf=? vote=0-0)
Backus argues that conventional/imperative ('von Neumann') programming languages are inherently 'fat and weak' due to basic defects, including their primitive word-at-a-time style, close coupling of semantics to state transitions, and crucially their LACK of useful mathematical properties for reasoning about programs. This is the canonical origin of the FP argument that imperative style impedes formal reasoning.

## CAVEATS
- VERIFICATION ASYMMETRY: Only two claims received full 3-0 adversarial confirmation (Brooks essence/accident as canonical origin; Hickey simple=objective/easy=relative). Everything else in this report — the broader pillar structure, decomplecting, Parnas information-hiding, the Ousterhout-vs-Clean-Code extraction tension, the FP/empirical layer — is sourced to PRIMARY documents and was NOT contradicted, but received only 0-0 or 1-0 votes, meaning insufficient INDEPENDENT confirmation this round, not refutation. Treat the two high-confidence findings as bedrock and the medium ones as well-sourced-but-needing-a-confirmation-pass before they go into a durable 'bible.' SCOPE GAPS: this verification round did NOT surface confirmed claims for several sources the research question named — Knuth (literate programming), Dijkstra (structured programming / elegance EWDs), Kent Beck (simple design rules), Sandi Metz, Kernighan & Pike, Okasaki (purely functional data structures), Alexis King ('Parse, Don't Validate'), 'making illegal states unrepresentable', Mike Acton (data-oriented design), and Carmack's primary writings (inlining email / functional-style-in-C++). Carmack and 'correctness-by-construction / illegal-states-unrepresentable' (the requester's hypothesized 5th pillar) are therefore present in this synthesis only by INFERENCE from adjacent confirmed material, NOT from independently verified primary quotes — they need their own sourcing pass. SOURCE-QUALITY NOTES: the Hickey source is a community transcript (faithful but lightly condensed, and Hickey himself flags one etymology as speculative); the Ousterhout-vs-Martin material is a GitHub debate repo (primary but a curated exchange); the empirical studies are strong (peer-reviewed-venue reanalysis, an arXiv complaint study) but the complaint study is survey/perception data, not defect-outcome data. TIME-SENSITIVITY: low for the philosophical canon (Brooks/Hickey/Parnas/Hughes/Backus are durable); the empirical layer is the live frontier and could shift with new replications.

## SOURCES
- {"url": "https://worrydream.com/refs/Brooks_1986_-_No_Silver_Bullet.pdf", "quality": "primary", "angle": "foundational canon (primary sources)", "claimCount": 5}
- {"url": "https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy-mostly-text.md", "quality": "primary", "angle": "foundational canon (primary sources)", "claimCount": 5}
- {"url": "http://sunnyday.mit.edu/16.355/parnas-criteria.html", "quality": "primary", "angle": "foundational canon (primary sources)", "claimCount": 5}
- {"url": "https://blog.pragmaticengineer.com/a-philosophy-of-software-design-review/", "quality": "blog", "angle": "foundational canon (primary sources)", "claimCount": 5}
- {"url": "https://blog.acolyer.org/2016/09/05/on-the-criteria-to-be-used-in-decomposing-systems-into-modules/", "quality": "secondary", "angle": "foundational canon (primary sources)", "claimCount": 5}
- {"url": "https://blog.acolyer.org/2016/09/06/no-silver-bullet-essence-and-accident-in-software-engineering/", "quality": "secondary", "angle": "foundational canon (primary sources)", "claimCount": 5}
- {"url": "https://github.com/johnousterhout/aposd-vs-clean-code", "quality": "primary", "angle": "contested debates / where sources conflict", "claimCount": 5}
- {"url": "https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction", "quality": "blog", "angle": "contested debates / where sources conflict", "claimCount": 5}
- {"url": "https://arxiv.org/pdf/2507.19721", "quality": "primary", "angle": "contested debates / where sources conflict", "claimCount": 5}
- {"url": "https://www.computerenhance.com/p/clean-code-horrible-performance", "quality": "blog", "angle": "contested debates / where sources conflict", "claimCount": 5}
- {"url": "https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/", "quality": "blog", "angle": "functional / correctness-by-construction theory", "claimCount": 5}
- {"url": "https://www.cse.chalmers.se/~rjmh/Papers/whyfp.html", "quality": "primary", "angle": "functional / correctness-by-construction theory", "claimCount": 4}
- {"url": "https://janvitek.org/pubs/toplas19.pdf", "quality": "primary", "angle": "functional / correctness-by-construction theory", "claimCount": 5}
- {"url": "https://fermatslibrary.com/p/15a1da0a", "quality": "primary", "angle": "functional / correctness-by-construction theory", "claimCount": 5}
- {"url": "https://www.semanticscholar.org/paper/A-Critique-of-Software-Defect-Prediction-Models-Fenton-Neil/083ab9fa36dd52b72fe933253da1f96ceae5a985", "quality": "primary", "angle": "empirical defect/maintainability research", "claimCount": 2}
- {"url": "https://www.sonarsource.com/resources/white-papers/cognitive-complexity.html", "quality": "primary", "angle": "empirical defect/maintainability research", "claimCount": 5}
- {"url": "https://www.sciencedirect.com/science/article/abs/pii/S0164121222002370", "quality": "primary", "angle": "empirical defect/maintainability research", "claimCount": 5}
- {"url": "https://ieeexplore.ieee.org/document/6606589/", "quality": "primary", "angle": "empirical defect/maintainability research", "claimCount": 5}
- {"url": "https://www.sqlite.org/different.html", "quality": "primary", "angle": "exemplar codebases / observably high-quality code", "claimCount": 5}
- {"url": "https://antirez.com/news/124", "quality": "primary", "angle": "exemplar codebases / observably high-quality code", "claimCount": 4}
- {"url": "http://number-none.com/blow/blog/programming/2014/09/26/carmack-on-inlined-code.html", "quality": "primary", "angle": "exemplar codebases / observably high-quality code", "claimCount": 5}
- {"url": "http://sevangelatos.com/john-carmack-on/", "quality": "primary", "angle": "exemplar codebases / observably high-quality code", "claimCount": 5}
- {"url": "https://github.com/norvig/pytudes", "quality": "primary", "angle": "exemplar codebases / observably high-quality code", "claimCount": 5}
- {"url": "https://github.com/ocaml-flambda/ocaml-jst", "quality": "primary", "angle": "exemplar codebases / observably high-quality code", "claimCount": 4}