---
title: "Several domains separate a named consumption-cost rating (complexity/difficulty/effort) from the quality rating, and every crowd-sourced version of it is an acknowledged-subjective proxy, not a validated measurement"
date: 2026-08-14
topic: complexity-rating-systems
tags: [bgg-weight, readability, flesch-kincaid, ski-difficulty, api-stability, hemingway-app, grammarly, cognitive-load, ux-writing]
status: draft
sources: [bgg-weight-wiki-secondary, bgg-ratings-secondary, tbgd-blog, rollacrit-blog, wikipedia-flesch-kincaid, ahrq-readability-tip, pubmed-flesch-limitations, hemingwayapp-help, hemingwayapp-articles, grammarly-blog, g2-grammarly-discussion, unofficial-networks-ski, snowbrains-ski, k8s-deprecation-policy, k8s-gateway-versioning, patent-recipe-difficulty-9489377, patent-cooking-ability-index]
source_session: unknown
---

## CLAIMS

**BoardGameGeek Weight**
- BGG's Weight is a separate crowd-voted metric from the main 1-10 quality rating; users vote complexity on a 5-point scale, and the average is displayed as a decimal (e.g. 3.42) on the game's page. [bgg-weight-wiki-secondary]
- The 5-point scale has named tiers, in order: 1.00 Light, 2.00 Medium Light, 3.00 Medium, 4.00 Medium Heavy, 5.00 Heavy. [bgg-weight-wiki-secondary]
- BGG has never published an official algorithm or rubric defining what "weight" means; it is described (via a historical page mouseover) only as "Community rating for how difficult a game is to understand. Lower rating (lighter weight) means easier." [bgg-ratings-secondary][tbgd-blog]
- Because there is no fixed definition, individual voters informally fold in different sub-factors — rules complexity, number of decisions, how much state must be tracked, and strategic depth — and different commentators explicitly propose splitting "weight" (learning difficulty) from "complexity" (in-play decision load) as two things BGG's own language conflates. [tbgd-blog]
- Practitioners describe the scale as informally exponential rather than linear: each full point step is treated as roughly a doubling of perceived complexity, so a 4 is treated as roughly 4x a 2 — this is a community heuristic, not an official BGG statement. [rollacrit-blog]
- Weight ratings are documented as subject to "weight hype" — reputation-driven bias where infamous complex games get pushed to higher weight than their actual rules complexity would justify. [rollacrit-blog]

**Flesch Reading Ease / Flesch-Kincaid Grade Level**
- Rudolf Flesch published the Flesch Reading Ease formula in 1948 for the Associated Press as part of the Plain English movement. [wikipedia-flesch-kincaid]
- Flesch Reading Ease formula: `206.835 − 1.015 × (total words / total sentences) − 84.6 × (total syllables / total words)`. Score range is nominally 0-100 (theoretical max ~121.22), with higher = easier; it can go negative for extremely dense text. [wikipedia-flesch-kincaid]
- Flesch-Kincaid Grade Level formula (same two inputs, different weights): `0.39 × (total words / total sentences) + 11.8 × (total syllables / total words) − 15.59`. Output is a US school grade level; unlike Reading Ease, lower = easier here. [wikipedia-flesch-kincaid]
- Flesch-Kincaid Grade Level was developed in 1975 by J. Peter Kincaid under contract to the US Navy, to score the readability of technical training manuals; the US Army adopted the formula for technical manual assessment in 1978, and it became a US military standard. [wikipedia-flesch-kincaid]
- Reading Ease score bands (approximate, widely reproduced): 90-100 = 5th grade/very easy; 80-90 = 6th grade; 70-80 = 7th grade; 60-70 = 8th-9th grade/plain English; 50-60 = 10th-12th grade/fairly difficult; 30-50 = college/difficult; 10-30 = college graduate/very difficult; 0-10 = professional/extremely difficult. [wikipedia-flesch-kincaid]
- Both formulas measure only two surface features — average sentence length and average syllables per word — and do not model organization, headings, layout, vocabulary diversity, tone, subject-matter difficulty, or the reader's prior knowledge. [ahrq-readability-tip][pubmed-flesch-limitations]
- AHRQ (US Agency for Healthcare Research and Quality) states explicitly: "The formulas do not measure comprehension or reading ease," and that a grade-level score alone is not a good way to judge whether a document is actually understandable by its intended audience. [ahrq-readability-tip]
- A PubMed-indexed critical review found FRE/FKGL ignore document factors (layout, images, font, spacing), person factors (education, health literacy, motivation, prior knowledge, anxiety), and writing-style factors (cultural sensitivity, appropriateness) — concluding the formulas inadequately assess real reading level for health materials. [pubmed-flesch-limitations]
- A specific documented failure mode: specialized/technical terminology is often long and multi-syllabic, which inflates the difficulty score even when the underlying concept is clearly explained — the formula cannot distinguish "hard because unfamiliar words" from "hard because genuinely complex." [pubmed-flesch-limitations]

**Hemingway App and Grammarly (writing-tool applications)**
- Hemingway App assigns writing a single US grade-level score based on the Automated Readability Index, where — unlike Flesch Reading Ease — lower is better (the number is "the lowest grade level that could easily read it"); by default it targets a 9th-grade reading level, the average for US adults. [hemingwayapp-help][hemingwayapp-articles]
- Hemingway highlights sentences scoring 4+ grade levels above the target in yellow, and 6+ grade levels above in red, plus separate color-coded flags for adverbs (blue), passive voice (green), and "complicated" phrases (purple) — the score is paired with localized highlights, not shown as a bare number alone. [hemingwayapp-help]
- Grammarly's readability score is computed directly from the Flesch Reading-Ease formula and displayed on Grammarly's own 0-100 scale (higher = easier), surfaced under "Readability" in the Editor's performance/score panel; Grammarly's own guidance recommends aiming for 60+ (roughly 8th-grade level) for general audiences. [grammarly-blog][g2-grammarly-discussion]

**Ski trail difficulty ratings (green/blue/black)**
- The green-circle/blue-square/black-diamond system originated from research done for Walt Disney's unbuilt 1960s Mineral King ski resort; Disney's team tested skier reactions to shapes and colors, concluding a circle read as "soft" (easy) and green read as "mellow." [snowbrains-ski]
- The US National Ski Areas Association (NSAA) had an earlier, different trail-marking system approved in 1965 that used colors conflicting with European conventions (e.g., French resorts used red for intermediate where the earlier US system did not align); the industry converged on the Disney-designed green/blue/black scheme by 1968, and it is now the widely used North American standard. [snowbrains-ski][unofficial-networks-ski]
- Neither NSAA nor the National Ski Patrol enforces a strict, universal numeric definition (e.g., percent grade) for each color tier; conventional informal guidance cited by ski-industry writers puts green at up to ~25% grade, blue at ~25-40%, and black above ~40%, but this is not a codified cross-resort standard. [unofficial-networks-ski]
- Trail difficulty ratings are explicitly relative to each individual resort or region, not globally calibrated — the same green-circle symbol at one resort can be materially harder than a green circle at another, and a green at a harder resort can be comparable to a blue at an easier one. [unofficial-networks-ski]
- Some resorts have extended the scale beyond the original three tiers (double black diamond as a long-standing extension, and at least one resort — Big Sky, Montana — using a "triple black diamond" designation as of the sources reviewed), showing the scale is not fixed even in cardinality. [unofficial-networks-ski]

**API stability/maturity badges (cost-to-adopt, adjacent category)**
- Kubernetes marks API maturity directly in the version string using three levels: alpha (e.g. `v1alpha1`), beta (e.g. `v1beta1`), and stable/GA (e.g. `v1`), each carrying different compatibility guarantees rather than a quality judgment. [k8s-deprecation-policy]
- Under Kubernetes' deprecation policy, alpha APIs may be removed in any release with no prior notice; beta APIs must remain available for at least 9 months or 3 minor releases after being deprecated (whichever is longer); GA/stable APIs must maintain backward compatibility indefinitely once released. [k8s-deprecation-policy]
- The Kubernetes Gateway API project deliberately simplified from three maturity levels to two (stable/default-installed vs. experimental/alpha), stating in its own docs that "it's not obvious what value an intermediate (Beta) state would have" for that project — evidence that even the number of tiers in a maturity scale is a judgment call, not a universal constant. [k8s-gateway-versioning]

**Recipe difficulty ratings (weaker example — cited for contrast, not primary evidence)**
- Patent filings on recipe-difficulty inference explicitly name the same subjectivity problem BGG's own community names for Weight: an author-assigned "easy/medium/hard" label reflects that author's own skill level, so a recipe an expert calls easy can be intractable for a novice, and difficulty ratings in recipe databases are described in the patent literature as "usually subjective" and "not universally applicable to all users." [patent-recipe-difficulty-9489377][patent-cooking-ability-index]
- Major recipe publishers (BBC Good Food, NYT Cooking) do not appear to publish a codified public rubric for how their easy/medium/hard labels are assigned; available editorial material frames difficulty in terms of practical factors like cooking time and technique count rather than a documented formula. [patent-recipe-difficulty-9489377]

## SOURCES

**bgg-weight-wiki-secondary**
URL: https://boardgamegeek.com/wiki/page/Weight
Accessed: 2026-08-14
Quote: "" (BGG's own wiki page was 403-blocked to automated fetch tools; claims sourced through search-engine-indexed excerpts and secondary confirmation below. Content directly attributed to this URL should be treated as search-snippet-derived, not full-page-verified.)

**bgg-ratings-secondary**
URL: https://boardgamegeek.com/wiki/page/ratings
Accessed: 2026-08-14
Quote: "Community rating for how difficult a game is to understand. Lower rating (lighter weight) means easier." (as reproduced via search-engine snippet of BGG's historical game-page mouseover text; BGG's own page returned 403 to direct fetch)

**tbgd-blog**
URL: https://tbgd.blog/2019/01/25/guide-to-boardgamegeek/
Accessed: 2026-08-14
Quote: "BGG says weight is how long to understand a game but then uses the word complexity right under it... BGG is equating weight and complexity while most gamers, and normal people, define them differently."

**rollacrit-blog**
URL: https://www.rollacrit.com/blogs/blog/how-to-use-board-game-geek-game-weights
Accessed: 2026-08-14
Quote: "" (via search summary: informal doubling heuristic per weight-scale step; "weight hype" reputation-bias framing)

**wikipedia-flesch-kincaid**
URL: https://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests
Accessed: 2026-08-14
Quote: "The Flesch–Kincaid reading grade level was developed under contract to the U.S. Navy in 1975 by J. Peter Kincaid and his team." Formula table: FRES = 206.835 − 1.015(words/sentences) − 84.6(syllables/words); FKGL = 0.39(words/sentences) + 11.8(syllables/words) − 15.59.

**ahrq-readability-tip**
URL: https://www.ahrq.gov/talkingquality/resources/writing/tip6.html
Accessed: 2026-08-14
Quote: "The formulas do not measure comprehension or reading ease."

**pubmed-flesch-limitations**
URL: https://pubmed.ncbi.nlm.nih.gov/28707643/
Accessed: 2026-08-14
Quote: "do not take into account document factors (layout, pictures and charts, color, font, spacing, legibility, and grammar), person factors (education level, comprehension, health literacy, motivation, prior knowledge, information needs, anxiety levels), and style of writing (cultural sensitivity, comprehensiveness, and appropriateness)"

**hemingwayapp-help**
URL: https://hemingwayapp.com/help/docs/readability
Accessed: 2026-08-14
Quote: "" (via search summary: grade-level score based on Automated Readability Index; yellow = 4+ grades above target, red = 6+ grades above target; default target grade 9)

**hemingwayapp-articles**
URL: https://hemingwayapp.com/articles/readability/readability-score
Accessed: 2026-08-14
Quote: "Like golf, lower numbers are better."

**grammarly-blog**
URL: https://www.grammarly.com/blog/writing-techniques/readability/
Accessed: 2026-08-14
Quote: "" (via search summary: Grammarly readability derived from Flesch reading-ease test; 0-100 scale, higher = easier)

**g2-grammarly-discussion**
URL: https://www.g2.com/discussions/how-the-readability-score-in-grammarly-calculated-and-what-does-it-means
Accessed: 2026-08-14
Quote: "" (via search summary: score surfaced under Editor performance panel; 60+ recommended for general 8th-grade-level audiences)

**unofficial-networks-ski**
URL: https://unofficialnetworks.com/2025/09/09/the-truth-behind-ski-resort-trail-rating-system/
Accessed: 2026-08-14
Quote: "a Green Circle trail at Jackson Hole, Wyoming might be as tough as a Blue Square at Sunlight, Colorado" (ratings are resort-relative, not globally calibrated)

**snowbrains-ski**
URL: https://snowbrains.com/how-walt-disney-helped-create-the-ski-area-trail-sign-system-in-north-america/
Accessed: 2026-08-14
Quote: "the group adopted a system pioneered by the Walt Disney Company for its planned but unbuilt ski resort. The resulting three-tiered system — green circle, blue square, and black diamond — was quickly adopted by ski resorts across the United States"

**k8s-deprecation-policy**
URL: https://kubernetes.io/docs/reference/using-api/deprecation-policy/
Accessed: 2026-08-14
Quote: "Alpha API versions may be removed in any release without prior deprecation notice... Beta API versions are deprecated no more than 9 months or 3 minor releases after introduction (whichever is longer)"

**k8s-gateway-versioning**
URL: https://gateway-api.sigs.k8s.io/docs/concepts/versioning/
Accessed: 2026-08-14
Quote: "In Gateway API, we've narrowed this down to 2 levels of stability... It's not obvious what value an intermediate (Beta) state would have for Gateway API."

**patent-recipe-difficulty-9489377**
URL: https://patents.justia.com/patent/9489377
Accessed: 2026-08-14
Quote: "" (via search summary: recipe-author-assigned difficulty labels are subjective to that author's own skill level and not universally applicable)

**patent-cooking-ability-index**
URL: https://patents.justia.com/patent/20220164752
Accessed: 2026-08-14
Quote: "" (via search summary: recipe-database difficulty ratings described as usually subjective, not universally applicable to all users)

## SYNTHESIS

The pattern behind BGG Weight generalizes: whenever a domain separates "is this good" from "what does this cost me to consume," the cost-axis rating is almost never a validated measurement — it's a crowd-sourced or editorial *proxy* that the domain's own experts openly admit is subjective, and every mature example eventually documents its own limitations rather than hiding them. That's true of BGG Weight (BGG's own historical copy never claims an algorithm), Flesch/Flesch-Kincaid (AHRQ and PubMed both publish formal "this doesn't measure comprehension" critiques of a 78-year-old formula still in daily use), and ski trail colors (NSAA and ski journalists openly say ratings are resort-relative, not globally calibrated). The honest examples name the proxy's boundary explicitly instead of implying it's a real measurement of the underlying construct (learning difficulty, comprehension, terrain danger).

Two structural sub-patterns are worth carrying into any future "add a complexity score" design decision:

1. **Multi-factor constructs collapse into one number, and users conflate what that number means.** BGG's community explicitly complains that "weight" (learning difficulty) and "complexity" (in-play decision load) are different things BGG bundles into one score. This is the same failure mode Flesch-Kincaid has: a score meant to proxy "hard to read" gets used as if it measures "hard to understand," even though technical jargon can score high on the formula while being perfectly clear to its intended audience (and vice versa — simple words in a poorly organized document score low but confuse readers). Any complexity/cost score you design should be explicit up front about which narrow thing it measures, and resist being read as a general difficulty verdict.

2. **The three strongest non-writing analogs (ski trails, Kubernetes API stability, recipe difficulty) split into two different kinds of "cost to consume."** Ski trails and recipe difficulty are genuinely about *learning/execution effort* (structurally the same axis as BGG Weight and readability). Kubernetes' alpha/beta/GA is adjacent but different in kind: it's a *risk-of-adopting-now* signal (will this break under you) rather than an effort-to-understand signal — still separate from "quality," but along a different dimension. Worth not conflating the two if building something similar: "how hard is this to learn" and "how risky is it to depend on this today" are both legitimately separable from "is this good," but they are not the same axis as each other.

For writing tools specifically (Hemingway, Grammarly), the dominant real-world implementation choice is: compute Flesch/FKGL (or a close relative like Automated Readability Index) under the hood, but never show the bare score alone — pair it with localized, actionable highlights (sentence-level color coding, adverb/passive-voice flags) so the user sees *where* the cost lives, not just a single opaque number. That pairing is itself a tacit admission that the underlying formula is too coarse to trust unaided — the sentence-level highlight is doing the real diagnostic work; the headline score is a motivational/tracking device.

One gap in this research: BGG's own wiki (`/wiki/page/Weight`, `/wiki/page/ratings`) returned HTTP 403 to automated fetch, so the BGG claims here rest on search-engine-indexed excerpts and independent secondary sources (a dedicated board-game blog, a board-game-shop blog) rather than a full read of BGG's primary page. Confidence is still reasonably high because three independent sources converge on the same facts (5-point scale, Light-to-Heavy labels, no official algorithm, historical mouseover text), but this should be treated as `status: draft` until someone with authenticated/human browser access can confirm the current wiki page text directly.
