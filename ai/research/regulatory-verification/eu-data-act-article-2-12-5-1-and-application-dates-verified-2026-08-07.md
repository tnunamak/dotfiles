---
title: "EU Data Act (Regulation 2023/2854) Article 2(12) user definition, Article 5(1) third-party sharing right, and the two application dates (12 Sept 2025 general; 12 Sept 2026 for connected products placed on market) are all verified against primary/authoritative sources"
date: 2026-08-07
topic: regulatory-verification
tags: [eu-data-act, regulation-2023-2854, pdpp, legal-verification]
status: draft
sources: [data-act-law-eu-art2, data-act-law-eu-art5, eversheds-sutherland-art3-art50, ec-digital-strategy-page]
source_session: 8b2c8ac0-a286-48e1-b140-253d6b93668c
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

- Article 2(12) of the EU Data Act defines "user" as "a natural or legal person that owns a connected product or to whom temporary rights to use that connected product have been contractually transferred, or that receives related services." [data-act-law-eu-art2]
- Article 5(1) of the EU Data Act establishes: "Upon request by a user, or by a party acting on behalf of a user, the data holder shall make available readily available data... to a third party without undue delay, of the same quality as is available to the data holder, easily, securely..." — i.e. the user directs the data holder (source) to make data available to a third party (client/recipient). [data-act-law-eu-art5]
- The EU Data Act generally applies from 12 September 2025 (entered into force 11 January 2024, applicable from 12 September 2025 per the European Commission's own Data Act policy page). [ec-digital-strategy-page]
- Article 50 (entry into force and application) postpones the Article 3(1) design-by-default/access-by-design obligation specifically: it applies only to connected products and related services placed on the market on or after 12 September 2026. Products placed on the market before that date are not covered by the design obligation. [eversheds-sutherland-art3-art50]
- WebFetch (the built-in tool) truncates eur-lex.europa.eu full-text pages at the preamble/recitals and cannot reach operative articles (Art. 5, Art. 50) or confirm dates directly from the EUR-Lex mirror — this is a tool limitation, not evidence against the claims. SearXNG web search + web_url_read against secondary legal-summary sites (data-act-law.eu, a full Art.-by-Art. mirror; Eversheds Sutherland client-alert page) successfully retrieved verbatim article text and confirmed dates where WebFetch failed.

## SOURCES

**data-act-law-eu-art2**
URL: https://data-act-law.eu/article/2/
Accessed: 2026-08-07
Quote: "(12)'user' means a natural or legal person that owns a connected product or to whom temporary rights to use that connected product have been contractually transferred, or that receives related services;"

**data-act-law-eu-art5**
URL: https://data-act-law.eu/article/5/
Accessed: 2026-08-07
Quote: "EU Data Act | Article 5, Right of the user to share data with third parties 1. Upon request by a user, or by a party acting on behalf of a user, the data holder shall make available readily available data, as well as the relevant metadata necessary to interpret and use those data, to a third party without undue delay, of the same quality as is available to the data holder, easily, securely..."

**eversheds-sutherland-art3-art50**
URL: https://www.eversheds-sutherland.com/en/global/insights/when-do-the-design-obligations-under-the-data-act-apply-understanding-article-3-and-article-50
Accessed: 2026-08-07
Quote: "Article 50 of the Data Act postpones the application of this design obligation. Specifically, it states that Article 3 (1) shall only apply to connected products and the services related to them that are placed on the market on or after 12 September 2026."

**ec-digital-strategy-page**
URL: https://digital-strategy.ec.europa.eu/en/policies/data-act
Accessed: 2026-08-07
Quote: "entered into force on 11 January 2024" and is "applicable from 12 September 2025."

## SYNTHESIS

All four legal claims used in a PDPP spec-core.md addition (Data Act row in "Relationship to existing standards") check out against independent sources: Article 2(12)'s natural-or-legal-person definition matches PDPP's subject-neutral owner framing; Article 5(1)'s user-directs-holder-to-third-party flow matches PDPP's owner/source/client triangle; and the two-tier application timeline (general 12 Sept 2025, design-obligation carve-out for products placed on market on/after 12 Sept 2026 per Art. 50) is real and was the trickiest fact to verify because EUR-Lex's own full-text page is too large for WebFetch's summarizer to reach the operative articles — it gets stuck in the recitals every time. The reliable path was pivoting to SearXNG web search to find secondary full-text mirrors (data-act-law.eu, a complete article-by-article EU Data Act mirror site) and law-firm client alerts (Eversheds Sutherland) that quote or paraphrase the operative text directly. Reusable lesson: for EUR-Lex verification tasks, skip straight to a search-engine detour rather than retrying WebFetch against eur-lex.europa.eu directly — the tool will keep returning preamble content regardless of prompt phrasing.
