---
title: "Tufte's data-ink ratio, Carroll's minimalist instruction, and Sweller's cognitive load theory independently converge on the same rule: cut everything that doesn't carry meaning for the reader, because excess costs the reader's limited working memory, not just their time"
date: 2026-08-14
topic: information-design
tags: [tufte, carroll, minimalism, cognitive-load, technical-writing, chartjunk, documentation, pr-descriptions]
status: draft
sources: [tufte-data-ink-edav, tufte-nasa-report, nng-clutter, carroll-instructionaldesign-org, carroll-nurnberg-funnel-summaries, cognitive-load-overview, redundancy-effect]
source_session: unknown
---

## CLAIMS

**Tufte — data-ink ratio and chartjunk**
- Tufte coined "chartjunk" in *The Visual Display of Quantitative Information* (1983), defining it as "ink that does not tell the viewer anything new" — non-data-ink or redundant data-ink. [tufte-data-ink-edav]
- Tufte defines data-ink as "the non-erasable core of a graphic, the non-redundant ink arranged in response to variation in the numbers represented." [tufte-data-ink-edav]
- Data-ink ratio = data-ink / total ink used to print the graphic = 1.0 − (proportion of the graphic that can be erased without loss of data-information). [tufte-nasa-report]
- Tufte's theory of data graphics states five principles: (1) above all else show the data, (2) maximize the data-ink ratio, (3) erase non-data-ink within reason, (4) erase redundant data-ink within reason, (5) revise and edit. [tufte-data-ink-edav]
- Direct Tufte quote: "Data graphics should draw the viewer's attention to the sense and substance of the data, not to something else." [nng-clutter]
- Tufte's own framework is not purely reductive — he explicitly leaves room for "complexity, structure, density, and even beauty," without specifying how that coexists with maximizing data-ink ratio. [tufte-data-ink-edav]
- Empirical pushback exists: Tufte's original claims rested on his own qualitative judgment as sole subject; later quantitative studies found some readers prefer lower-data-ink-ratio graphics, and in some cases higher data-ink ratio made charts *harder* to read. [tufte-data-ink-edav]
- A NASA technical report (Principles of Information Display for Visualization Practitioners) explicitly reframes Tufte's visual principles for documents generally, arguing visualizations "are paragraphs about data and should be treated as such" and that words, pictures, and numbers should be integrated as one information object rather than split across separate tools. [tufte-nasa-report]
- A documented "Tufte-style" extension to prose/document design (adoc-studio) reframes the analogy as "content-ink": every visual/textual element in a document must earn its place; concretely this drops decorative rules, prefers sidenotes over footnotes (because footnotes force a context-losing jump to the page bottom and back), uses typographic emphasis (e.g., italic headings) over heavy formatting, and reserves color for data rather than decoration. [tufte-nasa-report]

**Carroll — minimalist instruction ("The Nürnberg Funnel," 1990)**
- Carroll's minimalism is an action- and task-oriented theory of instruction/documentation, developed from field studies of how people actually learn word-processing and other computer systems. [carroll-nurnberg-funnel-summaries]
- Carroll and van der Meij state four core design principles: (1) choose an action-oriented approach, (2) anchor the tool in the task domain, (3) support error recognition and recovery, (4) support reading to do, study, and locate — i.e., readers use documentation to accomplish a task, to build understanding, or to look something up, and materials should support all three modes rather than assuming linear cover-to-cover reading. [carroll-nurnberg-funnel-summaries]
- Carroll's empirical starting point: studies of people learning word-processing systems found effective learning is active — self-initiated problem solving — and that standard instructional manuals of the time actively penalized and impeded this active learning style rather than supporting it. [carroll-nurnberg-funnel-summaries]
- Carroll's own card-based minimal-manual experiment (25 index cards vs. a 94-page conventional manual) found learners using the minimal cards reached competency in roughly half the time of learners using the full manual, while performing as well or better. [carroll-instructionaldesign-org]
- Carroll reports that the average chapter length across his Minimal Manuals was about three pages — substantially shorter than "systems approach" manuals of the same era. [carroll-nurnberg-funnel-summaries]
- Central principle in practice, per the "slash the verbiage" heuristic: minimize passive reading; let the reader fill in gaps by acting, rather than pre-explaining everything the reader might need. [carroll-nurnberg-funnel-summaries]
- Carroll treats error not as an instructional failure to prevent but as a normal, expected event the material should help the reader recognize and recover from — this was a deliberate break from the era's "systems approach" orthodoxy, which favored exhaustive up-front explanation and treated any error as a design failure to eliminate via more explanation. [carroll-nurnberg-funnel-summaries]
- Direct Carroll quote (paraphrased framing of his stance on prior knowledge): "Adult learners are not blank slates; they don't have funnels in their heads" — i.e., you cannot simply pour complete information into a reader and expect it to be absorbed and used; readers actively filter, skip, and act on partial information regardless of how complete the source material is. [carroll-instructionaldesign-org]

**Sweller — cognitive load theory**
- Sweller introduced cognitive load theory in 1988, elaborated with Van Merriënboer and Paas (1998) and Paas and Sweller (2012); it explains learning breakdown as a consequence of mental effort exceeding the limited capacity of working memory. [cognitive-load-overview]
- CLT decomposes total cognitive load into three components, generally treated as additive: intrinsic load (inherent complexity of the material/task, driven by "element interactivity" and the learner's prior knowledge), extraneous load (effort from how the material is presented, not from the material itself — poor organization, irrelevant content, unnecessary steps), and germane load (effort devoted to building durable understanding/schemas). [cognitive-load-overview]
- Extraneous load is explicitly defined as effort that does NOT contribute to learning: "poorly organised notation, redundant symbol tracking, or unnecessary procedural steps." Design's job is to minimize extraneous load so working memory capacity is freed for germane (useful) load. [cognitive-load-overview]
- The redundancy effect (a specific, tested CLT finding): presenting the same information concurrently in multiple forms, or elaborating on it unnecessarily, increases working memory load rather than reducing it, because the reader must coordinate the redundant sources — eliminating the redundant material removes that coordination cost and can measurably improve learning outcomes. [redundancy-effect]
- The related split-attention effect: when a reader must integrate two or more separated sources of the same explanation (e.g., a diagram that only makes sense with distant explanatory text) they must hold both in working memory simultaneously, which imposes high load and interferes with transfer to long-term understanding; the documented fix is physical integration of related information, not separation into cross-referenced pieces. [redundancy-effect]
- Carroll's 1990 minimalism work ("The Nürnberg Funnel") is directly cited within later cognitive-load-theory literature on cognitive architecture and instructional design, and researchers explicitly connect minimalist design to reduced extraneous cognitive load — both frameworks target the same failure mode (working-memory overload from unnecessary material) from different disciplinary starting points (HCI/technical-writing empiricism vs. cognitive-psychology theory). [cognitive-load-overview]

## SOURCES

**tufte-data-ink-edav**
URL: https://jtr13.github.io/cc19/tuftes-principles-of-data-ink.html
Accessed: 2026-08-14
Quote: "Tufte defined data-ink as 'the non-erasable core of a graphic, the non-redundant ink arranged in response to variation in the numbers represented.' ... Above all else show data. Maximize the data-ink ratio. Erase non-data-ink. Erase redundant data-ink. Revise and edit of data-ink."

**tufte-nasa-report**
URL: https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/nas-94-002.pdf
Accessed: 2026-08-14
Quote: "Data-ink ratio = data-ink / total ink used to print the graphic = proportion of a graphic's ink devoted to the non-redundant display of data-information = 1.0 - proportion of a graphic that can be erased without loss of data-information."

**nng-clutter**
URL: https://www.nngroup.com/articles/clutter-charts/
Accessed: 2026-08-14
Quote: "Data graphics should draw the viewer's attention to the sense and substance of the data, not to something else." (attributed to Edward Tufte)

**carroll-instructionaldesign-org**
URL: https://www.instructionaldesign.org/theories/minimalism/
Accessed: 2026-08-14
Quote: "Adult learners are not blank slates; they don't have funnels in their heads." / card-based word processor training (25 cards versus a 94-page manual) — learners achieved competency in approximately half the time.

**carroll-nurnberg-funnel-summaries**
URL: https://www.researchgate.net/publication/3229757_John_Carroll's_The_Nurnberg_Funnel_and_Minimalist_Documentation ; https://everypageispageone.com/2013/07/02/what-is-minimalism/ ; https://static.aminer.org/pdf/PDF/000/591/907/reconstructing_minimalism.pdf
Accessed: 2026-08-14
Quote: "Choose an action-oriented approach, Anchor the tool in the task domain, Support error recognition and recovery, and Support reading to do, study and locate." / "the average chapter length in Minimal Manuals is three pages."

**cognitive-load-overview**
URL: https://link.springer.com/article/10.1007/s10648-010-9128-5 ; https://education.nsw.gov.au/content/dam/main-education/about-us/educational-data/cese/2017-cognitive-load-theory.pdf
Accessed: 2026-08-14
Quote: "Extraneous load ... effort expended on aspects of a task that do not contribute to learning, such as poorly organised notation, redundant symbol tracking, or unnecessary procedural steps."

**redundancy-effect**
URL: https://www.cambridge.org/core/books/abs/cambridge-handbook-of-multimedia-learning/redundancy-principle-in-multimedia-learning/448A5532008EB4B4BA17DBEB5A421920 ; https://files.eric.ed.gov/fulltext/ED485075.pdf
Accessed: 2026-08-14
Quote: "Redundant material interferes with rather than facilitates learning ... coordinating redundant information with essential information increases working memory load."

## SYNTHESIS

All three frameworks name the same failure mode from three different vantage points, and together they give PR/commit-message writing a much stronger justification than "be concise":

- **Tufte** names the failure as a ratio problem: every mark that isn't data is a tax on the signal, and the fix is to erase, not to add clarifying decoration. Applied to prose (the NASA report and the "content-ink" extension both make this move explicitly, so it's not a stretch I'm inventing): every sentence in a PR description that isn't information the reviewer needs is chartjunk. A screenshot with no annotation, a restated diff, a paragraph explaining what the code obviously already shows — all lower the description's "data-ink ratio." The corrective isn't "write less," it's "erase what doesn't carry the delta in meaning."
- **Carroll** names the failure as a false model of the reader: authors assume readers will read linearly and completely, but Carroll's field studies found people **act first and read only when stuck** — they use documentation to do, to study, or to locate, not to absorb. This is the more useful frame for PR descriptions specifically, because it explains *why* exhaustive descriptions fail even when they're accurate: a reviewer skims for "what changed and why," hits a wall of context they didn't ask for, and either skips it (missing something real) or reads it grudgingly (wasting their attention budget on your completeness anxiety, not their review task). Carroll's fix — support error recognition/recovery rather than pre-explain everything, and design for reading-to-do — maps directly onto "put the risk/test plan where the reviewer will look when something breaks, not buried in prose they won't read."
- **Sweller** supplies the mechanism for why both of the above work: working memory is bounded, extraneous load (unnecessary detail, poor organization, redundant restatement) directly competes with germane load (the effort the reader needs to actually evaluate your change). The redundancy effect is the most directly transferable finding — restating in prose what the diff already shows doesn't reinforce it, it costs the reviewer coordination effort to reconcile two sources of the same fact. This gives a concrete anti-pattern: a PR description that "explains the diff" in prose is often actively worse than a shorter one, not just no better, because it forces the reviewer to hold two representations in mind and check them against each other.

Common thread across all three, useful as a compressed rule: **the writer usually has more context than the reader needs, and the writer's job is subtraction, not addition — every fact/pixel/word must earn placement by reducing the reader's effort to do the thing they came to do, not by demonstrating what the writer knows.** This directly matches the existing corpus finding on invented terminology (`writing-craft/a-coined-term-is-legitimate-only-if-it-recurs-and-does-work-otherwise-its-ornament.md`) and Zinsser's four articles of faith (`writing-craft/zinsser-four-articles-of-faith-are-clarity-simplicity-brevity-and-humanity.md`) — this entry adds the empirical/theoretical backing (HCI field studies + cognitive psychology) for why brevity isn't just stylistic preference but a measurable reader-cost problem.

One caveat worth carrying forward: Tufte's data-ink ratio itself has documented empirical pushback (readers sometimes prefer lower ratios; maximizing it can sometimes hurt readability) — so the useful takeaway is the *reasoning process* (erase what doesn't inform), not the ratio as a literal metric to maximize toward zero. Don't over-mechanize "shorter is always better" from this; Carroll's principles are more actionable for prose because they're about matching structure to how readers actually use the document (do/study/locate), not about minimizing a ratio.
