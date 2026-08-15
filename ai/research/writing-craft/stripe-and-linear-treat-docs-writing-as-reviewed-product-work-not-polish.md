---
title: "Stripe and Linear treat documentation/changelog writing as reviewed product work with named process owners, not a post-hoc polish pass"
date: 2026-08-14
topic: writing-craft
tags: [documentation, changelogs, developer-experience, style-guides, stripe, linear, editorial-process]
status: draft
sources: [slab-stripe-writing-culture, linear-method-build-in-public, linear-write-issues-not-user-stories, linear-startups-write-changelogs, docs-stripe-changelog-live, linear-changelog-live, stripe-dev-blog-topic-engineering, mintlify-stripe-docs, moesif-stripe-teardown]
source_session: unknown
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
-->

## CLAIMS

**Stripe — documented process, from primary reporting**
- Stripe's Documentation Manager, Dave Nunez, stated in an original interview that Stripe reviews writing the way it reviews code: "You wouldn't ship code without having it reviewed; your words are just as important." [slab-stripe-writing-culture]
- Nunez stated Stripe's leadership defaults to writing over slide decks: "From leadership on down, we default to writing. We don't really have slide decks." [slab-stripe-writing-culture]
- Nunez said Stripe CEO Patrick Collison's early internal emails used footnotes structured like research papers, and this practice was adopted company-wide after employees observed it. [slab-stripe-writing-culture]
- Per the same interview, Stripe differentiates review rigor by document leverage: documents with multi-team audience, >1 year relevance, or operational impact get formal review; lower-leverage docs are left to team autonomy. [slab-stripe-writing-culture]
- Per the same interview, Stripe runs onboarding classes focused on writing/documentation and a peer-review system for employee writing, and has piloted pairing ESL employees with writing mentors. [slab-stripe-writing-culture]
- A newer Stripe editorial hire (Shaun Young) is quoted: "I've never encountered a tech company of this size where writing is such a center of gravity." [slab-stripe-writing-culture]
- Stripe launched *Increment*, a quarterly engineering magazine with a dedicated editor-in-chief (Susan Fowler, 2017), and Stripe Press, a book-publishing imprint — both external, deliberate investments in engineering writing beyond docs. [slab-stripe-writing-culture]

**Stripe — verified structural facts (not process, but observable output)**
- Stripe's live API changelog (docs.stripe.com/changelog) presents entries as a table with exactly four fields per entry: Title, Affected Products, Breaking-change flag, Category. Titles are terse action-verb statements of WHAT changed ("Adds...", "Renames...", "Removes..."). No rationale/WHY field is present at the changelog-index level. [docs-stripe-changelog-live]
- Stripe's engineering blog (stripe.dev, formerly stripe.com/blog/engineering) publishes multi-author, problem/solution-framed long-form posts (e.g. "How Stripe uses graph search and state machines to auto-remediate a global database fleet"), distinct in register from the terse changelog. [stripe-dev-blog-topic-engineering]
- Stripe writes its docs in Markdoc, a Markdown superset it built and open-sourced, explicitly to let writers add interactivity/logic without mixing code into prose content. [mintlify-stripe-docs]

**Linear — documented process, from Linear's own primary publications**
- Linear co-founder/CEO Karri Saarinen, writing under Linear's own Medium publication, gave explicit changelog-writing rules: "Write about things that are interesting to a human. Don't include everything you do," "Feature 1–3 larger changes, and collect all the little fixes in one section," and "Include one or more screenshots or videos of the features if possible." [linear-startups-write-changelogs]
- Saarinen's piece explicitly frames changelog writing as audience-calibrated, not one fixed voice: "Depending on your audience, try to figure out what is the right voice." [linear-startups-write-changelogs]
- Linear's own "Linear Method" site (linear.app/method) states the reason to publish a changelog even pre-users: "For you and the team, it reminds you every week what happened and encourages you to ship constantly. For users, it shows the product is getting better. For investors, it shows progress." [linear-method-build-in-public]
- Linear's Method site states its position on requirements-writing generally: "We write short and simple issues that describe the task in plain language instead [of user stories]... The point of writing an issue is to communicate a task," explicitly naming brevity and plain language as the goal, and calling user stories "a cargo cult ritual." [linear-write-issues-not-user-stories]

**Linear — verified structural facts (not process, but observable output)**
- Linear's live changelog (linear.app/changelog) entries in the current run (Aug 2026) consistently open with a contextual/motivating sentence before describing the feature — e.g. "Your coding session doesn't have to stop when you leave your desk" precedes the feature description — then list fixes/improvements underneath in categorized bullets. This is a WHAT+WHY structure at the entry-lede level, unlike Stripe's changelog-index rows. [linear-changelog-live]
- Each Linear changelog entry typically pairs 1-2 screenshots or a video demo with the prose, consistent with Saarinen's 2020s guidance to include visual demonstration. [linear-changelog-live]

## SOURCES

**slab-stripe-writing-culture**
URL: https://slab.com/blog/stripe-writing-culture/
Accessed: 2026-08-14
Quote: "You wouldn't ship code without having it reviewed; your words are just as important." — Dave Nunez, Stripe Documentation Manager, in an original interview conducted for this piece (byline RC Victorino, published 2020-09-02).

**linear-method-build-in-public**
URL: https://linear.app/method/build-in-public
Accessed: 2026-08-14
Quote: "It might seem silly to summarize your work in a changelog when you don't have many users, but we think it's helpful... For you and the team, it reminds you every week what happened and encourages you to ship constantly."

**linear-write-issues-not-user-stories**
URL: https://linear.app/method/write-issues-not-user-stories
Accessed: 2026-08-14
Quote: "We write short and simple issues that describe the task in plain language instead. The point of writing an issue is to communicate a task."

**linear-startups-write-changelogs**
URL: https://medium.com/linear-app/startups-write-changelogs-c6a1d2ff4820
Accessed: 2026-08-14
Quote: "Write about things that are interesting to a human. Don't include everything you do." — Karri Saarinen, Linear co-founder/CEO, on Linear's own Medium publication.

**docs-stripe-changelog-live**
URL: https://docs.stripe.com/changelog
Accessed: 2026-08-14
Quote: "Adds invoice description, footer, and custom parameters to the Subscription Schedules and Quotes APIs" — representative entry title, table columns Title / Affected Products / Breaking change? / Category.

**linear-changelog-live**
URL: https://linear.app/changelog
Accessed: 2026-08-14
Quote: "Your coding session doesn't have to stop when you leave your desk." — lede sentence of the "Coding Sessions on Mobile" entry (2026-07-30), preceding feature description.

**stripe-dev-blog-topic-engineering**
URL: https://stripe.dev/blog/topic/engineering
Accessed: 2026-08-14
Quote: N/A — post-title listing used to characterize register (e.g. "How Stripe uses graph search and state machines to auto-remediate a global database fleet").

**mintlify-stripe-docs**
URL: https://www.mintlify.com/blog/stripe-docs
Accessed: 2026-08-14
Quote: N/A — third-party teardown; used only for the Markdoc/open-source-tooling claim, cross-checked against Stripe's own dev.to/stripe.dev Markdoc post title.

**moesif-stripe-teardown**
URL: https://www.moesif.com/blog/best-practices/api-product-management/the-stripe-developer-experience-and-docs-teardown/
Accessed: 2026-08-14
Quote: N/A — third-party analysis, used only as corroborating (not primary) evidence for the "plain, jargon-light interface" reputation claim; treat as reputation-tier, see SYNTHESIS.

## SYNTHESIS

Two different tiers of evidence came back from this search, and they should not be flattened together.

**Tier 1 — genuinely documented, attributable process (rare but real).** Both companies have exactly one strong primary artifact each, and they're different in kind. Stripe's is a *person* — Dave Nunez, Documentation Manager, on record in a 2020 interview describing writing-review-as-code-review, differentiated review rigor by document leverage, and an internal writing-mentor program. It's five years old and I could not find a fresher on-record equivalent (Stripe's careers page confirms the docs org still exists and hires "Technical Writer, Docs Content," but that's a job posting, not a process statement). Linear's is a *document* — their own Method site plus a Medium post literally authored by co-founder/CEO Karri Saarinen giving numbered rules for changelog writing ("1-3 larger changes then a fixes bucket," "screenshots make it engaging," "match voice to audience"). Both are genuinely citable, non-folklore sources — but note neither is a formal public style guide in the Microsoft Writing Style Guide or Google Developer Documentation Style Guide sense. Stripe has no published public writing style guide I could find; Linear has no published style guide either — the Method site is closer to a product-philosophy manifesto that happens to touch on writing than a style guide.

**Tier 2 — reputation and third-party teardown, not documented process.** Most of what circulates about "Stripe has the best docs in the industry" (Mintlify, Moesif, Apidog, TechnicalWriterHQ blog posts) is competitor/vendor content marketing analyzing Stripe's *output* — three-column layout, live code samples, Markdoc — not citing any Stripe process statement. Treat "Stripe's docs are the industry benchmark" as reputation, well-earned but unsourced-to-Stripe-itself in most of these pieces. The Markdoc claim is solid because it traces to Stripe's own engineering blog/GitHub repo, not just vendor commentary.

**The structural changelog difference is real and directly observable, not reputation.** I fetched both live changelogs rather than trusting secondary summaries. Stripe's API changelog is deliberately WHAT-only at the index level — a dense table of terse, breaking-change-flagged, categorized one-liners, clearly optimized for a developer scanning for "did this break my integration," not for narrative. Linear's changelog is WHAT+WHY at the entry level — each entry opens with a motivating sentence before the feature description, plus visuals — which matches Saarinen's own stated advice almost exactly. These are two different genres solving two different jobs (API-version diff vs. product-momentum signal), which is itself a transferable finding: don't copy Linear's narrative-changelog style onto an API version log, or Stripe's terse table onto a product-marketing changelog. Match structure to the changelog's job, not to "whichever company has better docs."

One correction to the initial WebSearch-only pass: my first search summary claimed Linear's changelog entries are "mostly one sentence long" — that reputation claim (sourced from third-party release-notes blogs, not Linear itself) did NOT survive fetching linear.app/changelog directly. Current Linear changelog entries (Aug 2026) are moderate-to-long with multiple sections, screenshots/video, and categorized fix lists — closer to a mini product-launch post than a one-liner. This is a good example of exactly the reputation-vs-primary-source gap the task asked to flag: several "Linear keeps changelogs one sentence" claims trace to blog-to-blog citation, not to Linear's live product.
