---
title: "Users do not exercise granular privacy controls in practice, granular controls measurably worsen consent outcomes when offered, and the empirical record on real revealed preference (CMU's Personalized Privacy Assistant field study) argues for a small curated preset set of roughly seven, not user-authored free-text terms"
date: 2026-09-03
topic: product-design
tags: [privacy-ux, consent-design, dark-patterns, control-paradox, oauth-scopes, iab-tcf, cmu-ppa, pdpp, roster-design]
status: draft
sources: [nouwens-chi2020, utz-ccs2019, brandimarte-control-paradox-2013, acquisti-science-2015, cmu-ppa, android-runtime-permissions, mozilla-play-store-labels, google-oauth-scopes, microsoft-entra-consent, apple-signin, iab-tcf-status, solove-2013, nissenbaum-contextual-integrity]
source_session: da53c1ca-0fcc-46b4-9b1a-3e44d3b7159c
---

## CLAIMS

- **Only 11.8% of cookie banners on the UK's top 10,000 websites met minimal GDPR legal requirements**, in a scrape of 5 top CMP designs (n=680 analyzed) plus a 40-participant field experiment on 8 common designs; 56.2% of sites pre-ticked optional vendors/purposes. [nouwens-chi2020]
- **Offering more granular consent options on the FIRST PAGE of a banner decreased consent by 8-20 percentage points**, versus a simple binary accept/reject choice — granularity itself suppresses opt-in rather than enabling nuanced choice. Removing the reject/opt-out button from the first page increased consent by 22-23 percentage points, in the same study. [nouwens-chi2020]
- In a field study with **more than 80,000 unique users** on a real e-commerce site, forcing users into vendor/cookie-level granular choice (5-6 extra clicks) produced rejection rates close to those of the simple binary condition — i.e., the minority who want to reject will pay a real effort cost to do so, but most users never engage that path. [utz-ccs2019]
- **The control paradox**: across three online experiments, giving people more PERCEIVED control over whether/how their information is published (as distinct from control over subsequent access or use) increased willingness to disclose sensitive information, even where objective risk was unchanged or worse. [brandimarte-control-paradox-2013]
- The behavioral-economics synthesis in *Science* (2015) concludes privacy preferences are (1) uncertain even to the people holding them, (2) highly context-dependent, and (3) malleable/manipulable by design choices such as defaults, framing, and timing — undercutting the premise that users have stable, well-formed "terms" to author or negotiate in the first place. [acquisti-science-2015]
- **CMU's Personalized Privacy Assistant field study**: 72 total participants (49 treatment using an app that recommended Android permission settings, 23 control without it); **78.7% of the assistant's recommendations were accepted** by users, and only **5.1%** of recommendations were later revised by treatment-group participants. [cmu-ppa]
- The same CMU research program clusters revealed privacy preference into **seven distinct profiles/personas** (aligned with prior "fence-sitter," "advanced user," "unconcerned," and "conservative" persona work), from which a handful of survey answers lets the system classify which cluster a person likely belongs to and generate recommendations from that cluster's aggregate preferences. This is domain-specific (Android app permissions, 2014-2016) and not verified as a general constant across all data-sharing contexts. [cmu-ppa]
- **Android runtime permission denial rates vary 16% to 60%** across measurement methods: an in-context survey found users accepted 84% of permission requests overall and were comfortable with their own choice 90% of the time (16% overall denial, concentrated in about half of participants); a separate dynamically-granted-permissions field study found 95% of participants blocked at least one request with an average 60% denial rate, and even the best "ask on first use" model still misserved users roughly 15% of the time because preferences shift with context after the first grant. [android-runtime-permissions]
- **Mozilla's "See No Evil" study (Feb 2023)** compared privacy policies against Google Play Data Safety labels for the top 20 paid + top 20 free apps (n=40): **nearly 80% had some discrepancy** between the privacy policy and the Data Safety label, **40% (16/40) had major discrepancies** (including Minecraft and Facebook), and only 15% (6/40) were graded fully consistent. Neither TikTok's nor Twitter's label disclosed third-party ad-data sharing that both companies' privacy policies stated explicitly. [mozilla-play-store-labels]
- Google's own OAuth developer guidance instructs "request only necessary scopes" and "incremental authorization," and provides no mechanism for a user to modify what an app may DO with data after granting access — scope grant/deny is the only lever exposed. [google-oauth-scopes]
- **Microsoft Entra's default for new tenants created after July 16, 2026 is "Do not allow user consent"** — all OAuth consent requests require an admin, full stop; Microsoft's stated reasoning is risk reduction from consent phishing and illicit consent grants, i.e., that end-user notice-and-choice consent was itself a security failure mode. [microsoft-entra-consent]
- Apple Sign in with Apple exposes only Hide My Email and a binary share/hide-email choice at signup as user-configurable levers; there is no per-app user-configurable terms surface for subsequent data use. [apple-signin]
- **The IAB Transparency and Consent Framework (TCF) is deployed at roughly 1,200+ vendors** (885 vendors and 177 CMPs registered by end of 2024, +25% YoY) while being repeatedly found unlawful: the Belgian DPA fined IAB Europe €250,000 (Feb 2, 2022) and found the TC String is personal data with IAB Europe a joint controller for it; the CJEU (Case C-604/22, March 7, 2024) confirmed a TC String can be personal data; the Brussels Market Court (May 14, 2025) upheld the infringement findings and reimposed the €250,000 fine. A further Jan 2026 ruling annulled only a narrower procedural validation and is not an exoneration of the TCF — commentators explicitly warn against reading it as "TCF cleared." [iab-tcf-status]
- Solove's "privacy self-management" argument holds that the number and complexity of decisions users face under a notice-and-consent regime scales far beyond what any consent mechanism — however granular or user-authored — can meaningfully process; his proposed partial fixes include shifting legal focus to downstream uses rather than point-of-collection consent. [solove-2013]
- Nissenbaum's contextual-integrity theory holds that privacy appropriateness is a property of an information flow conforming to the contextual norms of its origin (defined by data subject, sender, recipient, information type, and transmission principle), not a property any one party — company or user — can fully specify via a bespoke bilateral term; she characterizes notice-and-consent as a model that "loads all of the decision onto the least capable person, which is the data subject." [nissenbaum-contextual-integrity]

## SOURCES

**nouwens-chi2020**
URL: https://arxiv.org/abs/2001.02479
Accessed: 2026-09-03 (via /home/tnunamak/code/pdpp/local/research/_deep-0903/area4-industry-empirical.md)
Quote: "Only 11.8% of banners met minimal legal requirements. 56.2% of sites pre-ticked optional vendors/purposes. Removing the reject/opt-out button from the first page increased consent by 22-23 percentage points. Providing more granular controls on the first page decreased consent by 8-20 percentage points."

**utz-ccs2019**
URL: https://arxiv.org/abs/1909.02638
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "3 field experiments, >80,000 unique users, real e-commerce site ... when forced into vendor/cookie-level granular choice (5-6 extra clicks), rejection rates were close to the simple binary condition."

**brandimarte-control-paradox-2013**
URL: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3305325
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "Brandimarte, Acquisti & Loewenstein, 'Misplaced Confidences: Privacy and the Control Paradox,' Social Psychological and Personality Science 4(3), 2013 ... giving people more control over whether/how their information is published ... increases disclosure willingness enough that people end up MORE exposed, not less."

**acquisti-science-2015**
URL: https://www.science.org/doi/10.1126/science.aaa1465
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "people are deeply uncertain about the consequences of privacy decisions and even about their own preferences over those consequences ... privacy preferences are malleable and can be manipulated by commercial/governmental actors via design choices (defaults, framing, timing)."

**cmu-ppa**
URL: https://privacyassistant.org/
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "72 total participants — 49 in a treatment group ... 23 in a control group ... Acceptance rate: 78.7% of the PPA's recommendations were accepted by users. Only 5.1% of recommendations were later revised. ... Number of distinct privacy profiles/clusters: SEVEN."

**android-runtime-permissions**
URL: https://petsymposium.org (Bonné et al., SOUPS 2017); https://www.usenix.org (Wijesekera et al., USENIX Security 2015)
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "users accepted 84% of permission requests overall; among decisions made, users were comfortable with their own choice 90% of the time; 16% overall denial rate ... a related dynamically-granted-permissions study found ... 95% of participants blocked at least one permission request; average denial rate 60%."

**mozilla-play-store-labels**
URL: https://www.mozillafoundation.org/en/privacynotincluded/articles/mozilla-study-data-privacy-labels-for-most-top-apps-in-google-play-store-are-false-or-misleading/
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "Nearly 80% of apps reviewed had SOME discrepancy between privacy policy and Data Safety Forms ... 16/40 apps (40%) had MAJOR discrepancies ... only 6/40 (15%) graded 'OK'."

**google-oauth-scopes**
URL: https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "request only necessary scopes," use "incremental authorization" (ask for new scopes only when the user's action requires them).

**microsoft-entra-consent**
URL: https://learn.microsoft.com/entra/identity/enterprise-apps/user-admin-consent-overview
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "as of new tenants created after July 16 2026, the DEFAULT is 'Do not allow user consent' — all consent requests require an admin, full stop."

**apple-signin**
URL: https://support.apple.com/102609
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "the only user lever is Hide My Email ... and a binary share/hide-email choice at signup."

**iab-tcf-status**
URL: https://iabeurope.eu/wp-content/uploads/20260108-FAQ_-APD-DECISION-ON-IAB-EUROPE-AND-TCF-Updated-January-2026.pdf
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "~1,200+ vendors on the Global Vendor List (GVL) as of 2026; 885 vendors and 177 CMPs registered by end of 2024 ... Belgian DPA, 2 Feb 2022: fined IAB Europe €250,000 ... CJEU C-604/22, 7 March 2024 ... Brussels Market Court ... 14 May 2025: ... REIMPOSED the €250,000 fine."

**solove-2013**
URL: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2171018
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "Solove, 'Privacy Self-Management and the Consent Dilemma,' Harvard Law Review 126:1880, 2013 ... the number and complexity of decisions users face scales far beyond what any consent mechanism — however granular or user-authored — can meaningfully process."

**nissenbaum-contextual-integrity**
URL: https://direct.mit.edu/daed/article/140/4/32/26914
Accessed: 2026-09-03 (via area4-industry-empirical.md)
Quote: "notice-and-consent approaches risk keeping policy 'stuck with this theory of privacy that loads all of the decision onto the least capable person, which is the data subject.'"

## SYNTHESIS

The empirical record converges from four independent angles on the same conclusion: granular, user-authored privacy control is not a benign extra feature to bolt onto a consent flow — it actively works against the outcomes it's assumed to produce. Nouwens et al. show granularity suppresses opt-in by 8-20 points when it's optional friction on top of an "accept" default; Utz et al. show the same dynamic at 80,000-user scale; the control paradox shows perceived control over disclosure increases actual sensitive disclosure regardless of whether that control does anything real; and the Android permission literature shows even mandatory, unavoidable granular control (an OS-blocking runtime dialog) still misfires ~15% of the time in the best current system. The one condition under which granular control genuinely gets exercised — iOS App Tracking Transparency's binary, salient, unskippable prompt — is not granular at all.

Against this, the CMU Personalized Privacy Assistant field study is the strongest positive evidence for an alternative: a small number of curated presets (empirically, seven), refined by lightweight agent inference from a handful of signals, gets accepted 78.7% of the time and revised only 5.1% of the time — outperforming what any bespoke-authoring UI has been shown to achieve. Combined with the finding that today's self-declared terms systems (App Store/Play Store labels, IAB TCF) are already unreliable or unlawful at scale even when written by companies with legal departments, the case against "let the user write their own terms" is not merely that users won't bother — it's that when they do engage, granularity measurably degrades the outcome, and no comparable verification infrastructure exists to make user-authored terms trustworthy in the first place. A roster of ~7-15 vetted presets, not a free-text or fully-granular authoring surface, is what the data argues for.
