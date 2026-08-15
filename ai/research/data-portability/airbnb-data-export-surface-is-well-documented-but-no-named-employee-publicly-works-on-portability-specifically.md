---
title: "Airbnb's user-facing data-export surface (DYD, DSAR, formats) is well documented publicly, but no named Airbnb employee is publicly tied to data portability/export specifically — only privacy-engineering and data-protection-platform work"
date: 2026-08-12
topic: data-portability
tags: [airbnb, dsar, gdpr, ccpa, privacy-engineering, consent-management, data-classification, entangled-data, lfdt, pdpp]
status: draft
sources: [usenix-pepr24-epilepsia, airbnb-help-2273, airbnb-help-3255, airbnb-help-2862, dpc-airbnb-2023, airbnb-personal-data-classification, airbnb-privacy-first-connections, usenix-pepr23-mohapatra, usenix-borem-security24, usenix-pepr26-borem]
source_session: 8b2c8ac0-a286-48e1-b140-253d6b93668c
---

## CLAIMS

- Airbnb's Privacy Engineering team publicly presented "Consent Management at Airbnb" at USENIX PEPR '24 (June 2024), co-authored by Aziel Epilepsia (Software Engineer, Airbnb Privacy Engineering, focused on user consent and data subject rights) and Fernando Rubio (Software Engineer, Airbnb Privacy Engineering, focused on Privacy UX / client-side tooling for consent and storage). [usenix-pepr24-epilepsia]
- Airbnb's consumer "download your data" flow (Account > Privacy > Request your personal data) offers three export formats: HTML, JSON, and Excel (.xlsx), delivered as a time-limited-download .zip; JSON is explicitly positioned as the machine-readable/portability-oriented format. [airbnb-help-3255]
- Airbnb's documented personal-data export categories span 30+ areas including profile info, messages, reservations, payment history/instruments, listings (host-only), ID verification, telemetry/inferred-interest signals, and payments ledger data; some data (e.g. call recordings) requires a separate additional-information request in certain jurisdictions. [airbnb-help-3255]
- Airbnb's privacy-rights flow requires identity verification (potentially government ID) before fulfilling a request, and supports an authorized-agent path and a non-user request path. [airbnb-help-2273]
- Ireland's Data Protection Commission (DPC), Airbnb's lead GDPR supervisory authority, issued a formal reprimand (not a fine) on 21 June 2023 and a related 20 July 2023 decision finding Airbnb infringed Article 5(1)(c) data minimisation by requiring a copy of government ID to verify identity for a DSAR/erasure request, and infringed Article 15(1) by not providing all personal data in the first DSAR response. [dpc-airbnb-2023]
- Airbnb's Host Privacy Standards (a legal/SCC document) list the categories of guest data hosts receive to fulfill a reservation: guest profile, full name(s) of all guests, cancellation history, phone number, and trip-coordination messages — establishing that reservation records are inherently two-party (guest+host) data. [airbnb-help-2862]
- That same Host Privacy Standards document does NOT describe any dual-verification or expiring-download-link mechanism specifically for DSAR fulfillment of entangled reservation data — it only sets EU-UK/Switzerland cross-border SCC transfer terms and Article 32 security obligations for hosts processing guest data. [airbnb-help-2862]
- Airbnb's engineering blog ("Personal data classification," author Sam Kim et al.) describes an internal Personal Data Taxonomy Council and a three-tier classification scheme (critical/personal/public) used to annotate and govern personal data across Airbnb's data stores, feeding an in-house Data Protection Platform detection service. [airbnb-personal-data-classification]
- Airbnb's engineering blog ("Privacy-first connections," author Joy Jing) describes an explicit architectural split between "User" (the full internal record: name, email, phone, account details) and "Profile" (the public-facing subset), used to scope what's shared with co-guests in social features — a pattern directly relevant to scoping what counts as "the user's data" for export. [airbnb-privacy-first-connections]
- A separate multi-part engineering series, "Automating data protection at scale," authored by Elizabeth Nammour, documents Airbnb's Data Protection Platform, including database-export pipelines (MySQL→Hive), IDL-based data-classification annotation enforcement, and automated PR-based remediation for misclassified fields — infrastructure adjacent to, but distinct from, the consumer-facing export/DSAR flow. [source: web search summary of medium.com/airbnb-engineering/automating-data-protection-at-scale-part-3, not independently fetched due to 403 bot-block]
- A PEPR '23 talk titled "Building Export Ecosystem: From DSAR Automation to Privacy Center" (DYD/EYD/Privacy Center architecture) was presented by Pankaj Mohapatra of Uber, NOT Airbnb — ruled out as an Airbnb lead despite topical similarity. [usenix-pepr23-mohapatra]
- Arthur Borem (University of Chicago PhD candidate; prior work at Data Transfer Initiative, Asana, Lyft) co-authored USENIX Security '24 "Data Subjects' Reactions to Exercising Their Right of Access," an empirical study of users exploring their own DSAR exports from Amazon, Facebook, Google, Spotify, and Uber (not Airbnb), finding exports are overwhelming/hard-to-understand as JSON. [usenix-borem-security24]
- Arthur Borem is scheduled to present "Dismantling the Barriers to Personal Data Portability" at USENIX PEPR '26 alongside Lisa Dusseault, CTO of the Data Transfer Initiative — he is not an Airbnb employee. [usenix-pepr26-borem]
- No public evidence was found of Airbnb participating in the Data Transfer Project (DTP) / Data Transfer Initiative (DTI) adapter ecosystem (searched dtinit.org compendium PDF and GitHub org; no Airbnb-specific adapter or member mention surfaced).
- No public evidence was found of any named Airbnb employee speaking at IAPP or QCon specifically on data portability/export (searches returned only unrelated Airbnb speakers, e.g. a Staff Engineer on resilience/incident-response topics, not privacy).

## SOURCES

**usenix-pepr24-epilepsia**
URL: https://www.usenix.org/conference/pepr24/presentation/epilepsia
Accessed: 2026-08-12
Quote: "Aziel is a Software Engineer in the Airbnb Privacy Engineering team. He currently focuses on Privacy service technical problems regarding user consent and data subject rights. Fernando is a software engineer on the Airbnb privacy engineering team..."

**airbnb-help-2273**
URL: https://www.airbnb.com/help/article/2273
Accessed: 2026-08-12
Quote: "In some instances, you can request a portable copy of your personal information. When you submit a request, you can select a structured, commonly-used, and machine-readable format."

**airbnb-help-3255**
URL: https://www.airbnb.com/help/article/3255
Accessed: 2026-08-12
Quote: "You have a choice of selecting between the HTML format, the excel format, or the JSON format when making your request... The data file is available for download for a limited time only."

**airbnb-help-2862**
URL: https://www.airbnb.com/help/article/2862
Accessed: 2026-08-12
Quote: "the categories of data may include the Guest's profile and full name, the full name of any additional Guests (if entered), the Guest's cancellation history, Guest's phone number, any other information the Guest chooses to share, and additional information to assist with coordinating the trip including messages exchanged with the Guest"

**dpc-airbnb-2023**
URL: https://www.dataprotection.ie/en/dpc-guidance/law/decisions-made-under-data-protection-act-2018/inquiryinto-airbnb-ireland-uc-july2023
Accessed: 2026-08-12 (via search summary; not directly fetched)
Quote: "found that Airbnb's request that the complainant verify their identity by submission of a copy of their ID constituted an infringement of the principle of data minimisation under Article 5(1)(c)... Airbnb infringed Article 15(1) of the GDPR at the time of first processing the complainant's access request by not providing the complainant with access to all of their personal data"

**airbnb-personal-data-classification**
URL: https://medium.com/airbnb-engineering/personal-data-classification-2d816d8ea516
Accessed: 2026-08-12 (via search summary; direct fetch 403-blocked)
Quote: "Airbnb has established a Personal Data Taxonomy Council to define the taxonomy for personal data and to refine it over time"

**airbnb-privacy-first-connections**
URL: https://medium.com/airbnb-engineering/privacy-first-connections-empowering-social-experiences-at-airbnb-d7dec59ef960
Accessed: 2026-08-12 (via search summary; direct fetch 403-blocked)
Quote: "'User' represents the complete, internal record Airbnb holds about a user... A 'Profile,' on the other hand, includes only a subset of information about a User and is their public-facing representation."

**usenix-pepr23-mohapatra**
URL: https://www.usenix.org/system/files/pepr23_slides-mohapatra.pdf
Accessed: 2026-08-12
Quote: "PEPR '23 Building Export Ecosystem From DSAR Automation to Privacy Center — Pankaj Mohapatra, Software Engineer, Uber"

**usenix-borem-security24**
URL: https://www.usenix.org/system/files/usenixsecurity24-borem.pdf
Accessed: 2026-08-12 (via search summary)
Quote: "33 participants explored their own data from Amazon, Facebook, Google, Spotify, or Uber, articulating questions they hoped to answer using the exports"

**usenix-pepr26-borem**
URL: https://www.usenix.org/conference/pepr26/presentation/borem
Accessed: 2026-08-12 (via search summary)
Quote: "Dismantling the Barriers to Personal Data Portability" — Arthur Borem with Lisa Dusseault (CTO, Data Transfer Initiative)

## SYNTHESIS

For anyone prepping to meet "someone who works on data exports at Airbnb": the two
most credible named candidates found are Aziel Epilepsia and Fernando Rubio, both
publicly identified (via a 2024 USENIX PEPR talk bio, not LinkedIn-only inference) as
Airbnb Privacy Engineering software engineers whose stated focus areas are consent and
data-subject-rights (Epilepsia) and privacy UX / client-side consent tooling (Rubio).
Confidence: moderate — this is a conference-bio-level match on team and remit (privacy
engineering, data subject rights), not a confirmed match on the specific "data exports"
sub-team. A third name, Elizabeth Nammour, authored Airbnb's internal Data Protection
Platform blog series, which is data-classification/export-pipeline infrastructure
adjacent to but distinct from the consumer DSAR/export flow — lower confidence as a
"data exports" match than the consent-talk pair.

Two false leads worth flagging explicitly so they aren't re-chased: (1) the PEPR '23
"Building Export Ecosystem" talk is Uber's, not Airbnb's, despite matching search terms
closely; (2) Arthur Borem/DTI is the strongest DSAR-portability voice in the corpus but
has no Airbnb affiliation — he's grounding material for the "industry DSAR literature"
angle, not a WHO candidate.

The regulatory record (Irish DPC, June/July 2023) is the strongest concrete evidence of
Airbnb's DSAR practice under scrutiny: a formal reprimand for over-collecting ID to
verify DSAR requesters, and for an incomplete first DSAR response. That's a specific,
citable pain point ("we had to redesign our verification-vs-minimization tradeoff after
a regulator reprimand") that a real Airbnb privacy/export engineer would likely know
firsthand.

The claim that Airbnb's DSAR process has a "dual verification requirement" and
"expiring download link" specifically for reservation-entangled two-party data did NOT
hold up against direct reading of Airbnb's own Host Privacy Standards page — that page
only covers cross-border SCC terms, not a described fulfillment mechanism. Treat that
specific claim as unconfirmed/likely-fabricated by an earlier AI-search synthesis step;
it was not re-asserted in the CLAIMS above. The general "reservation data is two-party"
fact IS confirmed directly from Airbnb's own document.
