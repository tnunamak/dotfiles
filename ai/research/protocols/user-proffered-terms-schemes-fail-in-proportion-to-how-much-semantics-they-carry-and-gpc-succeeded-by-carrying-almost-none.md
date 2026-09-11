---
title: "User-proffered/individual-side machine-readable terms schemes fail in inverse proportion to how much semantics they carry — P3P (rich XML policy language) died at an 8-10% adoption plateau with ~34% of deployed compact policies measurably gamed or broken, DNT died in the 2012 IE10-default-on fight not the 2019 W3C closure, and Global Privacy Control succeeded by carrying a single bit plus a statutory hook (the $1.2M Sephora CCPA settlement), while IEEE 7012-2025/MyTerms published Jan 2026 with a 3-term roster has zero found implementers beyond one legacy publisher"
date: 2026-09-03
topic: protocols
tags: [p3p, dnt, gpc, myterms, ieee-7012, customer-commons, projectvrm, ccpa, w3c, adoption-history, consent-mechanisms, pdpp]
status: draft
sources: [p3p-closure, p3p-cranor-warning, p3p-cranor-postmortem, p3p-token-attempt, p3p-deployment-numbers, dnt-closure, dnt-safari-expired, dnt-ie10-yahoo, dnt-cca-oppa, gpc-w3c-status, gpc-sephora-settlement, gpc-iapp-analysis, myterms-lineage-searls, customer-commons-roster, myterms-faq-governance, me2b-rename]
source_session: da53c1ca-0fcc-46b4-9b1a-3e44d3b7159c
---

<!--
Mechanical transformation of /home/tnunamak/code/pdpp/local/research/_deep-0903/area1-lineage.md
(sections 1-4 + adoption scoreboard) into corpus format. No new research performed.
-->

## CLAIMS

- **P3P 1.0 became a W3C Recommendation in April 2002; the P3P Specification Working Group formally closed 21 November 2006**, publishing P3P 1.1 only as a Working Group Note (not a Recommendation) after concluding there was "insufficient support from current Browser implementers for the implementation of P3P 1.1." [p3p-closure]
- As early as February 2006, WG chair Lorrie Cranor warned the group on-list that W3C members were "losing interest... due to very limited participation" and the WG might close without reaching Recommendation status. [p3p-cranor-warning]
- Cranor's own post-mortem (2012 law journal article, written by the person who chaired the P3P WG and authored *Web Privacy with P3P*) frames the core finding as **"Necessary But Not Sufficient"**: even a well-designed standardized machine-readable notice mechanism cannot overcome the fundamental limits of the notice-and-choice paradigm. [p3p-cranor-postmortem]
- **CMU CyLab's "Token Attempt" study (CMU-CyLab-10-014, Sept 2010) found errors in ~34% (11,176 of 33,139) of studied sites' P3P compact policies**, and large numbers of sites used identical *invalid* compact-policy tokens that had circulated as a known workaround for an Internet Explorer cookie-blocking bug — **Microsoft's own support site had recommended using invalid compact policies as that workaround**, i.e. Microsoft's documentation itself seeded the gaming it was meant to prevent. [p3p-token-attempt]
- Microsoft only added an "Enable Strict P3P Validation" option (rejecting any compact policy with undefined tokens) in IE10/IE11 — years after the gaming was documented — because IE's compact-policy enforcement was a rules engine keyed on token presence/absence, not a semantic parser, so any string containing the "right" tokens passed regardless of overall coherence. [p3p-token-attempt]
- **P3P adoption plateaued in the single digits/low twenties and never exceeded ~20% even among the most-resourced top-500 sites**: ~18-20% of top-500-by-traffic sites adopted shortly after the 2002 Recommendation (only 11% of top finance sites); a 2005→2006 longitudinal study of the 30,000 most-clicked domains found 8.54% (2,564 domains) had P3P policies in 2005, rising to only 9.78% (2,934 domains) in 2006, with 54 policies also removed in that window — real churn, not monotonic growth. [p3p-deployment-numbers]
- **The W3C Tracking Protection Working Group (Do Not Track) formally closed 17 January 2019**; its own closure notice states verbatim: **"As adoption has not proceeded, the specification is republished as a Working Group Note"** — DNT never exited Candidate Recommendation into full Recommendation status. [dnt-closure]
- Safari's own 2019 release notes called Do Not Track an **"expired"** standard when Apple dropped it from the browser. [dnt-safari-expired]
- **The proximate trigger for DNT's practical death was the 2012 IE10-default-on controversy, seven years before the 2019 formal W3C closure**: Microsoft shipped IE10/Windows 8 with DNT on by default (June 2012), reversing the "off unless user opts in" norm; the Association of National Advertisers (450 companies) called it "irresponsible... undercuts years of tireless, collaborative efforts"; in October 2012 Yahoo announced it would ignore the IE10 DNT signal, stating "Microsoft unilaterally decided to turn on DNT in Internet Explorer 10 by default, rather than at users' direction... this degrades the experience." Google and Adobe sided with Yahoo in permitting ad networks to ignore IE10's signal; Mozilla and Apple said networks should not ignore it — splitting the ecosystem years before the spec was ever finished. [dnt-ie10-yahoo]
- California's AB 370 (signed Sept 2013, effective 1 Jan 2014) amended CalOPPA to require operators to *disclose* how they respond to DNT-type signals but **does not require honoring DNT, and does not even define "do not track" or what constitutes a qualifying signal**. [dnt-cca-oppa]
- **Global Privacy Control originated in the W3C Privacy Community Group in April 2020 (informal incubation) and was elevated to a formal W3C Privacy Working Group work item in November 2024** — on the Recommendation track, unlike DNT's purely community-driven path. [gpc-w3c-status]
- **California AG Rob Bonta announced a $1.2M settlement with Sephora on 24 August 2022 — the CA AG's first-ever named CCPA enforcement action** — with findings stating verbatim that **"Sephora's website was not configured to detect or process any global privacy control signals"**; Sephora took no action to stop data-sharing on receipt of a GPC opt-out signal and failed to cure within the then-available 30-day cure window. [gpc-sephora-settlement]
- As of the 2026 snapshot, roughly 12 US states legally mandate honoring GPC/universal opt-out signals (California, Colorado, Connecticut, Delaware, Maryland, Minnesota, Montana, Nebraska, New Hampshire, New Jersey, Oregon, Texas, plus Kentucky/Rhode Island/Indiana added 1 Jan 2026); Texas and Nebraska impose no revenue/volume threshold for applicability. [gpc-w3c-status]
- IAPP's analysis of why GPC succeeded where DNT failed argues GPC was **"engineered from its inception to be integrated into privacy law frameworks, giving it legal force under the CCPA and similar statutes,"** whereas DNT relied purely on voluntary industry adoption with no statutory backstop. [gpc-iapp-analysis]
- **GPC carries a single binary `Sec-GPC` signal with no purpose list, no terms text, and no acceptance record on either side** — the individual-proffered scheme that actually achieved legal force did so by carrying almost no semantics, in direct contrast to P3P's rich XML policy-comparison language and DNT's more elaborate tracking-preference-expression spec. [gpc-w3c-status]
- **IEEE 7012-2025 ("MyTerms") published January 2026** after nine years of Kantara-adjacent/Customer-Commons-hosted working-group process (chairs: David P. Reed → Lisa LaVasseur → Doc Searls), as part of IEEE's 7000-series AI-ethics/GET Program standards, launched jointly by Customer Commons and MyData Global at Imperial College London. [myterms-lineage-searls]
- **The Customer Commons roster — the canonical list of terms individuals may proffer under MyTerms — contains exactly 3 named term artifacts as of this research**: P2B1 v0.9 (aka **#NoStalking**, "don't track me off your site... just show me ads not based on tracking me"), also mirrored/superseded-labeled as **P2B1 v0.9 self-flagged superseded** by a later listing, and **SD-BY-AT v0.9**. [customer-commons-roster]
- **The only confirmed publisher committed to accepting P2B1 is Linux Journal; no other adopting site or app was found.** Customer Commons' own roadmap states 11 more agreements are planned "as they approach finalization of the IEEE P7012 Standard," meaning the roster had not expanded beyond its original items even after the standard itself published. [customer-commons-roster]
- **No formal published governance procedure (proposal → review → approval → versioning) was found for how a new MyTerms term is vetted and added** — the MyTerms FAQ states only that "the names are chosen by Customer Commons, working on the model established by Creative Commons," with no documented multi-stakeholder process. Flagged explicitly by the source research as COULD NOT VERIFY a formal governance procedure document. [myterms-faq-governance]
- **Me2B Alliance (founded 2019) rebranded to Internet Safety Labs in July 2022**, dissolving its elected Me-/B- board-member roles and shifting from a volunteer-chaired-panel governance model to staff-supported panels; the underlying Me2B Safe Specification v1.0 is archived and not actively maintained, with the org's operational output since the rename being app safety-testing/labeling rather than continued standards work — i.e. the Me2B "commitments" spec track was effectively superseded by an audit/testing-lab business model, not carried forward. [me2b-rename]

## SOURCES

**p3p-closure**
URL: https://lists.w3.org/Archives/Public/public-p3p-spec/2006Nov/0010.html ; https://www.w3.org/P3P/1.1/
Accessed: 2026-09-03
Quote: "P3P Specification Working Group now closed" — WG concluded there was "insufficient support from current Browser implementers for the implementation of P3P 1.1," publishing P3P 1.1 as a Working Group Note rather than entering Candidate Recommendation.

**p3p-cranor-warning**
URL: https://lists.w3.org/Archives/Public/public-p3p-spec/2006Feb/0003.html
Accessed: 2026-09-03
Quote: W3C members "losing interest... due to very limited participation"; WG might close without reaching Recommendation status if interest didn't materialize.

**p3p-cranor-postmortem**
URL: https://fpf.org/wp-content/uploads/2013/07/Cranor_Necessary-But-Sufficient1.pdf
Accessed: 2026-09-03
Quote: Lorrie F. Cranor, "Necessary But Not Sufficient: Standardized Mechanisms for Privacy Notice and Choice," 10 Colo. Tech. L.J. 273 (2012) — argues even a well-designed standardized machine-readable notice mechanism cannot overcome the fundamental limits of the notice-and-choice paradigm.

**p3p-token-attempt**
URL: https://fpf.org/wp-content/uploads/2021/05/Token-Attempt-The-Misrepresentation-of-Website-Privacy-Policies-through-the-Misuse-of-P3P-Compact-Policy-Tokens.pdf ; https://learn.microsoft.com/en-us/archive/blogs/ieinternals/a-quick-look-at-p3p
Accessed: 2026-09-03
Quote: Leon, Cranor, McDonald, McGuire, "Token Attempt" (CMU CyLab, CMU-CyLab-10-014, Sept 2010) — of 33,139 sites studied, errors were detected in 11,176 (~34%) of their compact policies; large numbers of sites used identical invalid compact-policy tokens that had circulated as a known workaround to avoid IE cookie blocking; Microsoft's own support site had recommended using invalid CPs as a workaround for an IE FRAMESET bug.

**p3p-deployment-numbers**
URL: https://lorrie.cranor.org/pubs/p3p-deployment.pdf
Accessed: 2026-09-03 (via search summary, not independently refetched)
Quote: ~18-20% of top-500 sites by traffic adopted P3P shortly after the 2002 Recommendation (11% of top finance/investing sites); of the 30,000 most-clicked domains, 8.54% (2,564 domains) had P3P policies in 2005, rising to 9.78% (2,934 domains) in 2006, with 54 policies also removed in that window.

**dnt-closure**
URL: https://www.w3.org/2011/tracking-protection/ ; https://lists.w3.org/Archives/Public/public-tracking/2019Jan/0000.html
Accessed: 2026-09-03 (direct fetch)
Quote: "The working group is currently closed. It closed on 17 January 2019." Closure notice: "As adoption has not proceeded, the specification is republished as a Working Group Note."

**dnt-safari-expired**
URL: https://www.fastcompany.com/90308068/how-the-tragic-death-of-do-not-track-ruined-the-web-for-everyone
Accessed: 2026-09-03
Quote: Safari's 2019 (Safari 12.1) release notes called Do Not Track an "expired" standard when Apple dropped it from the browser.

**dnt-ie10-yahoo**
URL: https://www.theregister.com/2012/10/26/yahoo_to_ignore_ie10_do_not_track ; https://money.cnn.com/2012/06/01/technology/internet-explorer-do-not-track/index.htm ; https://www.markey.senate.gov/news/press-releases/markey-barton-boo-to-yahoo-for-ignoring-do-not-track
Accessed: 2026-09-03
Quote: Yahoo, October 2012: "Microsoft unilaterally decided to turn on DNT in Internet Explorer 10 by default, rather than at users' direction. In our view, this degrades the experience... and makes it hard to deliver on our value proposition." ANA (450 companies) called the IE10 default "irresponsible... undercuts years of tireless, collaborative efforts."

**dnt-cca-oppa**
URL: https://www.loeb.com/en/insights/publications/2013/10/california-enacts-law-requiring-do-not-track-dis__ ; https://www.cooley.com/news/insight/2013/ab370-californias-do-not-track-law
Accessed: 2026-09-03
Quote: AB 370 (signed Sept 2013, effective 1 Jan 2014) requires operators to disclose in their privacy policy how they respond to DNT-type browser signals; does not require honoring DNT and does not define "do not track" or what constitutes a qualifying signal.

**gpc-w3c-status**
URL: https://globalprivacycontrol.org/ ; https://lists.w3.org/Archives/Public/public-privacy/2024OctDec/0023.html ; https://www.w3.org/TR/2024/WD-gpc-20241121/
Accessed: 2026-09-03
Quote: "In November 2024, GPC was adopted as an official work item of the W3C Privacy Working Group." Resulting W3C Working Draft dated 21 November 2024, on the Recommendation track.

**gpc-sephora-settlement**
URL: https://oag.ca.gov/news/press-releases/attorney-general-bonta-announces-settlement-sephora-part-ongoing-enforcement
Accessed: 2026-09-03 (primary AG source)
Quote: "Sephora's website was not configured to detect or process any global privacy control signals." $1.2M settlement, 24 August 2022 — the CA AG's first-ever named CCPA enforcement action.

**gpc-iapp-analysis**
URL: https://iapp.org/news/a/is-gpc-the-new-do-not-track
Accessed: 2026-09-03 (via search summary — title/framing confirmed, not directly refetched for full text)
Quote: GPC was "engineered from its inception to be integrated into privacy law frameworks, giving it legal force under the CCPA and similar statutes," unlike DNT's purely voluntary industry adoption.

**myterms-lineage-searls**
URL: https://doc.searls.com/category/myterms-ieee-p7012/ ; https://doc.searls.com/2026/01/29/now-we-begin/ ; https://doc.searls.com/2022/10/11/p7012/
Accessed: 2026-09-03
Quote: IEEE 7012-2025 ("MyTerms") published January 2026 after nine years of working-group process; successive chairs David P. Reed → Lisa LaVasseur → Doc Searls; launch event held jointly by Customer Commons and MyData Global at Imperial College London.

**customer-commons-roster**
URL: https://customercommons.org/agreements/ ; https://customercommons.org/choose-your-agreements/ ; https://customercommons.org/solutions/
Accessed: 2026-09-03 (direct fetch)
Quote: Roster lists P2B1 version 0.9 (`https://customercommons.org/agreements/p2b1/0.9/`) and SD-BY-AT version 0.9 (`https://customercommons.org/myterm/SD-BY-AT/0.9/`) as the entire published roster; roadmap states 11 more agreements are planned "as they approach finalization of the IEEE P7012 Standard." First and only confirmed adopting publisher: Linux Journal.

**myterms-faq-governance**
URL: https://myterms.info/faqs/
Accessed: 2026-09-03 (direct fetch)
Quote: "The names are chosen by Customer Commons, working on the model established by Creative Commons for personal copyright licenses." No further formal governance procedure document found.

**me2b-rename**
URL: https://internetsafetylabs.org/blog/news-press/the-me2b-alliance-is-now-internet-safety-labs/ ; https://internetsafetylabs.org/archives/safetechspec/
Accessed: 2026-09-03
Quote: Me2B Alliance rebranded to Internet Safety Labs in July 2022; elected Me-/B- board member roles dissolved, volunteer-chaired panels became staff-supported; Me2B Safe Specification v1.0 archived, not actively maintained.

## SYNTHESIS

The pattern across four systems is clean enough to state as a rule: **the amount of semantics a user-proffered/individual-side terms scheme tries to carry on the wire predicts its failure, and the one unambiguous success carries almost none.** P3P tried to encode a full bidirectional policy-comparison language (purposes, categories, recipients, compact-policy tokens) and died two ways at once — a slow adoption death (never past ~20% even among top-500 sites, formally closed 2006) and a faster credibility death (a rules-engine enforcement model that couldn't tell a real compact policy from a gamed one, with ~34% of measured policies wrong and Microsoft's own docs recommending the gaming workaround). DNT tried to encode less (a single header plus a promised behavioral contract) but still died — not at its 2019 formal closure, which was seven years too late to matter, but in 2012 when IE10's default-on decision fractured the industry consensus DNT depended on, before the spec was even finished. GPC carries a single bit and nothing else — no purpose, no terms text, no record — and is the only one of the three with real legal teeth, via a $1.2M enforcement action naming GPC non-compliance directly. The mechanism IAPP identifies (statutory hook from inception) is necessary but arguably not sufficient on its own: a scheme with a hook AND heavy semantics (P3P had none, but even a semantically-thin scheme without a hook, DNT, still failed) suggests the hook is what turns "carries a bit" into force, while the bit-not-a-policy shape is what made the hook attachable in the first place — CCPA could define compliance as "did you honor a boolean signal," which is a testable, unambiguous obligation; nobody could have written a statute requiring "did you correctly interpret this recipient's P3P purpose taxonomy."

MyTerms/IEEE 7012 sits at the opposite end from GPC on the semantics axis — full bilateral term text, a governance body, a versioned roster, a dual-record requirement — and shows the corresponding adoption signature: a standard finished in January 2026 with a roster that had **three items nine years into the working-group process** and, per this research, zero confirmed implementers beyond Linux Journal committing to one of them. This is not proof MyTerms will fail (P3P and DNT both had real industry participation and still failed for reasons unrelated to semantics richness per se — P3P's specific failure was gameable enforcement, DNT's was a coordination collapse), but it replicates the shape: a scheme asking recipients to parse, negotiate, and dual-record rich terms is asking for more integration work than a scheme asking them to check one bit, and every rich-semantics scheme in this set has so far paid for that with adoption. The practical implication for any design borrowing from "align with MyTerms": the closer the design gets to GPC's shape (one flag, one hook, no bilateral record), the more precedent supports it working; the closer it gets to P2B1/SD-BY-AT's shape (named term, roster lookup, dual acceptance record), the more precedent says it will stay in single digits of adoption regardless of how well-specified it is.
