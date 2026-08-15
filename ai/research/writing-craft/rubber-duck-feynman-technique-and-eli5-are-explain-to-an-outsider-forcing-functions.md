---
title: "Rubber duck debugging, the Feynman Technique, and ELI5 are three independently-originated 'explain to a naive listener' forcing functions, only one of which (rubber ducking) is explicitly documented at its source"
date: 2026-08-14
topic: writing-craft
tags: [explanation-techniques, rubber-duck-debugging, feynman-technique, eli5, pr-descriptions, self-explanation-effect]
status: draft
sources: [wikipedia-rubber-duck, github-blog-ducks, pragprog-quote-secondary, scott-young-medium, chi-1994-self-explanation, eli5-fan-2019, pflugfelder-2016, mattduck-commit-messages]
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

**Rubber duck debugging**
- The term originates from a story/footnote in *The Pragmatic Programmer: From Journeyman to Master* by Andrew Hunt and David Thomas (Addison-Wesley, 1999). [wikipedia-rubber-duck]
- The book's actual described technique does not require a literal duck: explain the problem to another person who says nothing and just nods, "like a rubber duck bobbing up and down in a bathtub" — the footnote is what supplies the literal-duck anecdote. [pragprog-quote-secondary]
- Secondary sources disagree on the specific person behind the footnote anecdote: Wikipedia's article (as fetched) attributes it to "a research assistant Greg Pugh who carried around a rubber duck," while at least one blog instead describes it as "a colleague who kept an actual little yellow rubber duck on their desk." This is a real discrepancy between secondary sources, not a resolved fact — the primary text (the 1999 book itself) was not directly checked in this research pass. [wikipedia-rubber-duck] [pragprog-quote-secondary]
- No source found in this research documents an antecedent for the technique predating the 1999 book (e.g., in earlier programmer folklore or psychotherapy) — Hunt & Thomas's book is the earliest documented source found. [wikipedia-rubber-duck]
- GitHub's own engineering blog (github.blog) independently confirms the 1999/Hunt-and-Thomas origin and describes the mechanism as "explain his code to the duck — line by line" — but explicitly frames the technique as general problem-solving, with no connection drawn to documentation, PR descriptions, commit messages, or code review. [github-blog-ducks]
- The commonly cited cognitive mechanism behind why rubber duck debugging works is the "self-explanation effect": explaining material to oneself or another improves understanding and reveals gaps, first identified in the cognitive-science literature by Chi et al. (1994) in mathematics/physics learning, independent of and predating its popular application to programming. [chi-1994-self-explanation]

**The Feynman Technique**
- Richard Feynman did not publish, name, or formally codify a "Feynman Technique" study method himself. [scott-young-medium]
- The technique's biographical inspiration is usually traced to James Gleick's 1993 biography *Genius: The Life and Science of Richard Feynman*, which describes Feynman at Princeton keeping a notebook titled "NOTEBOOK OF THINGS I DON'T KNOW ABOUT" and working to disassemble and reassemble each branch of physics looking for gaps. [scott-young-medium]
- The now-standard 4-step packaging (1. choose/identify a concept, 2. teach it to someone with no background/a child, 3. identify gaps and go back to source material, 4. simplify/review) is a later popularization, most commonly attributed to writer Scott Young (writing around 2011, during his public "MIT Challenge" project). [scott-young-medium]
- Scott Young himself, in later writing, describes the method more loosely as 3 steps rather than 4, and explicitly calls his own version "only loosely based on Richard Feynman's practices" — i.e., the technique's namesake and its popularizer both, in the clearest primary-adjacent statements found, decline to claim it is a technique Feynman himself designed or taught. [scott-young-medium]
- Conclusion for citation purposes: the Feynman Technique is best described in any PR-description adaptation as "a folk-attributed learning technique popularized by online writers (notably Scott Young) using Feynman's reputation and biography as inspiration," not as "a technique documented by Feynman." [scott-young-medium]

**ELI5 (Explain Like I'm Five)**
- The acronym "ELI5" predates the subreddit: it appeared in Urban Dictionary about a month before the subreddit's creation, and on Twitter (via user @NinkiCZ) about two months before. [reddit-eli5-history]
- The subreddit r/explainlikeimfive was created by Reddit user "bossgalaga" in 2011 (sources found disagree on the exact date — one gives 28 July 2011, another "September 2011"; this specific date was not independently resolved in this pass). [reddit-eli5-history]
- Bossgalaga's stated founding motivation was to create "a friendly place to ask questions without fear of being mocked if deemed obvious or stupid" — i.e., ELI5's community norm is explicitly about psychological safety for the asker, not literally simplifying for children. [reddit-eli5-history]
- The community convention is understood, and stated explicitly in secondary sources, as NOT meaning "explain this for an actual five-year-old" but as shorthand for "give a jargon-free, no-prior-knowledge-assumed explanation." [reddit-eli5-history]
- By 2019 the subreddit had over 15 million subscribers and was among Reddit's top-20 subreddits by size; it has since grown further. [reddit-eli5-history]
- A dedicated linguistic/discourse-analysis study exists: Pflugfelder (2016/2017), "Reddit's 'Explain Like I'm Five': Technical Descriptions in the Wild" (Technical Communication Quarterly), which analyzed 233 ELI5 threads and frames ELI5 answers as a genre of "technical description" combining two distinct moves: linguistic simplification (plain language for complex concepts) and explanatory simplification (distilling large amounts of information into a comprehensible account). [pflugfelder-2016]
- A large-scale NLP corpus paper exists: Fan et al., "ELI5: Long Form Question Answering" (ACL 2019), built from 270,000 ELI5 threads. It explicitly frames ELI5 answers as linguistically distinct because they are "self contained" (relying less on the reader's pre-existing world knowledge) and use simpler language — this is the paper's own stated reason ELI5 was chosen as a research corpus, not just this synthesis's interpretation. [eli5-fan-2019]
- Fan et al. found a large machine/human gap: their best abstractive model was still preferred less than human ("gold") answers in over 86% of blind comparisons, i.e., ELI5-quality explanation is empirically hard even for models trained specifically on the genre. [eli5-fan-2019]

**Explicit adaptation into software-engineering writing practice**
- At least one publicly written, named-author blog post explicitly and directly draws the rubber-duck-debugging analogy for commit-message writing (not PR descriptions specifically, but the same "written explanation to an outsider" genre): "Or, like rubber duck debugging, I might realise something new about my implementation when I try to explain it." The post's overall thesis is that a commit message should state what changed, why it matters, and what a reviewer needs to know — and that the act of writing it is itself a forcing function that catches problems before a human reviewer has to ask. [mattduck-commit-messages]
- No source found in this research documents an established, named, or widely-adopted engineering practice that explicitly imports the Feynman Technique's 4-step structure or the ELI5 community convention into PR-description or commit-message writing specifically (as opposed to general "explain simply" blog advice, or debugging specifically for rubber-ducking). This appears to be an open adaptation opportunity rather than settled/attested practice. [mattduck-commit-messages]

## SOURCES

**wikipedia-rubber-duck**
URL: https://en.wikipedia.org/wiki/Rubber_duck_debugging
Accessed: 2026-08-14
Quote: "The book described rubber ducking as the method of explaining a problem to another party who do not 'need to say a word; the simple act of explaining, step by step, what the code is supposed to do often causes the problem to leap off the screen and announce itself.' ... The term referred to a research assistant Greg Pugh who carried around a rubber duck for this purpose."

**github-blog-ducks**
URL: https://github.blog/engineering/engineering-principles/whats-with-all-the-ducks/
Accessed: 2026-08-14
Quote: "Our story starts back in 1999, when a book was released, The Pragmatic Programmer by Andrew Hunt... [the programmer] explained his code to the duck—line by line!"

**pragprog-quote-secondary**
URL: https://www.rubberduckdebuggingbook.com/rubber-duck-debugging-explained (and corroborating: https://handwiki.org/wiki/Rubber_duck_debugging)
Accessed: 2026-08-14
Quote: "A very simple but particularly useful technique for finding the cause of a problem is simply to explain it to someone else. The other person should look over your shoulder at the screen, and nod his or her head constantly ... They do not need to say a word; the simple act of explaining, step by step, what the code is supposed to do often causes the problem to leap off the screen and announce itself." — quoted (secondhand) as the actual text of Hunt & Thomas, The Pragmatic Programmer (1999), p. 95, footnote. Primary text (the book itself) not directly checked in this pass.

**scott-young-medium**
URL: https://scotthyoung.medium.com/the-ultimate-strategy-for-studying-anything-feynman-technique-802e0a268f7f
Accessed: 2026-08-14
Quote: "I first got the idea from this method from the Nobel prize winning physicist, Richard Feynman. In his autobiography, he describes himself struggling with a hard research paper..." (Young frames the technique as loosely inspired by Feynman, not documented/authored by him; later writing describes it as 3 steps and calls it "only loosely based on Richard Feynman's practices.")

**chi-1994-self-explanation**
URL: https://onlinelibrary.wiley.com/doi/10.1207/s15516709cog1803_3
Accessed: 2026-08-14
Quote: Chi, M.T.H. et al. (1994), "Eliciting Self-Explanations Improves Understanding," Cognitive Science 18(3). Foundational study establishing that generating explanations (including to oneself) improves learning and reveals gaps in understanding — the general cognitive-science grounding cited by later popular sources for why rubber duck debugging and Feynman-style explanation "work."

**reddit-eli5-history**
URL: https://edtimes.in/eli5-a-subreddit-that-explains-you-complex-stuff-like-you-are-five/ (cross-checked against https://en.everybodywiki.com/Explainlikeimfive)
Accessed: 2026-08-14
Quote: "The subreddit was created by user bossgalaga in September 2011 — about a month after ELI5 was entered into Urban Dictionary, and two months after the term first appeared on Twitter by user @NinkiCZ." Founding motivation quoted as: a "friendly place to ask questions without fear of being mocked if they were deemed obvious or stupid."

**pflugfelder-2016**
URL: https://www.researchgate.net/publication/311482776_Reddit's_Explain_Like_I'm_Five_Technical_Descriptions_in_the_Wild
Accessed: 2026-08-14
Quote: Pflugfelder, E.H., "Reddit's 'Explain Like I'm Five': Technical Descriptions in the Wild," Technical Communication Quarterly. Study of 233 ELI5 threads identifying two distinct simplification moves in ELI5-style answers: linguistic simplification and explanatory simplification.

**eli5-fan-2019**
URL: https://arxiv.org/abs/1907.09190
Accessed: 2026-08-14
Quote: "We introduce the first large-scale corpus for long-form question answering, a task requiring elaborate and in-depth answers to open-ended questions." 270,000 threads from r/explainlikeimfive; best abstractive model's answers were preferred over "gold" (human) answers in fewer than 14% of blind comparisons (i.e., gold preferred >86% of the time).

**mattduck-commit-messages**
URL: https://www.mattduck.com/2023-09-04-git-commit-messages
Accessed: 2026-08-14
Quote: "Or, like rubber duck debugging, I might realise something new about my implementation when I try to explain it."

## SYNTHESIS

All three techniques share one underlying mechanism (forcing generative self-explanation to a naive/silent audience surfaces gaps that silent review does not), but they differ sharply in how well-documented that mechanism is at the source, and that difference matters if this is going to be cited in an agent-facing prompt pattern:

- **Rubber duck debugging** is the only one of the three with a real documented primary source (a specific 1999 book, described consistently across independent tellings including GitHub's own engineering blog). Cite it as "Hunt & Thomas, The Pragmatic Programmer (1999)" — safe to state as fact. The one soft spot is the identity of the anecdote's subject (Wikipedia says "Greg Pugh," another source says an unnamed "colleague") — don't repeat a specific name without checking the book directly.
- **The Feynman Technique** is folklore wearing a technique's clothing. It should never be cited as "Feynman's technique" or "documented by Feynman" — the honest framing is "a learning method popularized by writers like Scott Young, using Feynman's reputation/biography as inspiration, not a method Feynman himself taught or named." If used in an agent prompt pattern, attribute it to the popularizers, not the physicist.
- **ELI5** is the best-evidenced of the three for *why* naive-audience explanation produces good outputs — it's the only one with both a dedicated academic discourse-analysis study (Pflugfelder) and a large NLP research corpus (Fan et al.) built specifically to study what makes its answers work. The empirical takeaway worth stealing for a PR-description prompt: ELI5-quality answers are self-contained (assume no reader context) and combine linguistic simplification (plain words) with explanatory simplification (compress/select what to include, not just how to phrase it) — that second move is the harder, more valuable one, and is exactly the move a good PR description needs (deciding what a reviewer needs to know, not just simplifying the prose).

For adapting this into a PR-description prompt pattern: only rubber duck debugging has a directly attested prior adaptation into written engineering communication (the mattduck.com commit-message post), and even that is one individual blog post, not an established named practice, and it's about commit messages, not PR descriptions specifically. There is no evidence of an existing named convention like "ELI5 your PR" or "Feynman your PR description" in wide use — this is white space, not something to cite as already-established practice. A prompt pattern built from this research should present itself honestly as a novel synthesis of three known techniques, not as "the well-known X practice."

A concrete pattern worth prototyping, grounded in the strongest-evidenced parts above: (1) write the PR description as if to a reviewer with zero context on this specific change (ELI5's self-contained-answer property); (2) explicitly separate "what changed" from "why it matters" (Fan et al.'s explanatory-simplification move — deciding what's worth including); (3) treat any point where the explanation gets hard to write as a signal to go back and look at the code again, not just reword the sentence (the Feynman 4-step "identify gaps, return to source" loop, honestly attributed to its popularizers) — this is functionally identical to what the self-explanation effect literature (Chi et al. 1994) says happens with rubber duck debugging, just applied to a PR description instead of a bug.
