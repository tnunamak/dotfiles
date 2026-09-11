---
title: "The only machine-readable personal-data consent objects that reached real national scale are regulator-defined and recipient-authored, with the user able only to narrow, accept, or decline — India's Account Aggregator (450M+ cumulative consents, 700K/day) is the largest, running on a closed 5-code purpose taxonomy, while GDPR Art. 20 direct transmission, DMA Art. 6(9), CFPB 1033, and FHIR Consent all produced near-zero real usage despite being law"
date: 2026-09-03
topic: protocols
tags: [account-aggregator, rebit, sahamati, dpdp, consent-artefact, purpose-codes, uk-open-banking, cdr-australia, gdpr-article-20, eu-data-act, cfpb-1033, fhir-consent, hipaa, consent-regimes, pdpp]
status: draft
sources: [aa-rebit-spec, aa-purpose-codes, aa-sahamati-scale, aa-dvara-critique, dpdp-rules-timeline, gdpr-art20, eu-data-act-art13-mct, uk-open-banking-scale, cdr-australia-reset, cfpb-1033-status, fhir-consent-vs-smart, hipaa-164-508]
source_session: da53c1ca-0fcc-46b4-9b1a-3e44d3b7159c
---

<!--
Mechanical transformation of /home/tnunamak/code/pdpp/local/research/_deep-0903/area3-regulated.md
into corpus format. No new research performed.
-->

## CLAIMS

- **India's Account Aggregator (AA) framework, governed by the RBI NBFC-AA API Specification v2.0.0 and mediated by ReBIT/Sahamati, is the largest confirmed machine-readable personal-data consent system found in this survey.** At RBI's recognition of Sahamati as Self-Regulatory Organisation (mid-2026): 1,120+ live regulated financial entities, 176 FIPs, 1,020 FIUs, 17 operational AAs, 450M+ consent requests fulfilled, 294M+ linked accounts, 290M+ monthly data shares. [aa-sahamati-scale]
- Sahamati's FY26 report (published 24 June 2026) states: ~3.8 crore (38 million) financial products/services facilitated in FY26; **45+ crore (450M+) cumulative consents**; 500+ crore (5B+) cumulative data fetches; **>7 lakh (700,000) consents processed daily**; 5.96 crore (~60M) Personal Finance Management users, growing at a 164% CAGR since FY23. As of March 2025, cumulative consents were ~140M (Dec 2024 baseline) — roughly tripling to 450M+ within 18 months. [aa-sahamati-scale]
- **The ReBIT Consent Artefact (`ConsentDetail`) is a fully specified, digitally-signed machine-readable object** with fields including `consentMode` (VIEW | STORE | QUERY | STREAM), `fetchType` (ONETIME | PERIODIC), `consentTypes` (PROFILE, SUMMARY, TRANSACTIONS), `fiTypes`, `DataConsumer`/`DataProvider` identity, `Customer` (`customer_identifier@AA_identifier`), `Purpose {code, refUri, text, Category}`, `FIDataRange {from, to}`, `DataLife {unit, value}` (retention), `Frequency`, `DataFilter`, and an AA digital signature that FIP/FIU must validate. [aa-rebit-spec]
- **The AA purpose taxonomy is a closed, five-code enumeration** defined by Sahamati (sahamati.org.in/purpose-codes/): Category 1 "Personal Finance" → code 101 (wealth management service), code 102 (spending patterns/budget/reporting); Category 2 "Financial Reporting" → code 103 (aggregated statement); Category 3 "Account Query and Monitoring" → code 104 (explicit consent for monitoring of accounts), code 105 (explicit one-time consent for accounts). [aa-purpose-codes]
- **The user's only levers under AA are narrow, accept, or decline — not counter-propose.** When an FIU requests data, the request (data types, purpose, duration, frequency) appears in the user's AA app; the user can approve, approve-with-a-narrower-scope (fewer accounts, shorter date range, subset of data types, via the `DataFilter`/scope fields), or reject. The user cannot counter-propose different purposes, retention (`DataLife`), or add their own conditions — the FIU sets the initial terms; revocation is available at any time post-grant, unilaterally, without contacting the FIU. This is structurally the recipient-drafts/user-narrows shape, the opposite of a consumer-originates-terms model. [aa-purpose-codes]
- **Dvara Research's critique (India's leading fintech-policy research org) finds technical compliance and substantive consent quality diverge sharply**: most customers do not read or comprehend consent artefacts before consenting; the behavioral mechanism is not illiteracy but passive deference — users give the artefact "a cursory glance" and are "pre-programmed to accept," with urgency ("hot state," e.g. loan contexts) overriding deliberation. Effects are most severe for lower-income, less-educated, first-generation digital-finance users. Net assessment: the AA framework's premise of explicit, informed, revocable consent is **formally satisfied but substantively hollow** for a large share of users — a consent-fatigue dynamic paralleling cookie-banner fatigue elsewhere. [aa-dvara-critique]
- **India's DPDP Act 2023 Consent Manager regime — a separate, not-yet-operative mechanism — has a confirmed three-phase rollout**: Rules notified 13 November 2025 (Phase 1: definitions, Board constitution); Phase 2 (13 November 2026): Consent Manager registration opens, unregistered entities barred from operating from this date; Phase 3 (13 May 2027): core operative rules (notice, consent, security, breach reporting, retention, children's data) take effect. Consent Managers must be "data-blind" intermediaries, barred from acting as data fiduciary/processor for the same data principals. [dpdp-rules-timeline]
- **GDPR Article 20(2)'s direct controller-to-controller transmission right is qualified by "where technically feasible"** — an EU-legislature-created loophole with no deadline or effort obligation to build interoperability; a controller can lawfully refuse direct transmission simply by asserting its systems aren't interoperable with the destination, and there is no reciprocal obligation on the receiving controller. WP29 Guidelines WP242 rev.01 (adopted 5 April 2017) recommended industry develop "a common set of interoperable standards and formats," but this remains aspirational and largely unrealized. No evidence of meaningful direct-transmission uptake was found. [gdpr-art20]
- **The EU Data Act's Model Contractual Terms (MCTs)** were published as a Commission Recommendation on 20 November 2025 — delayed from the Art. 41 statutory deadline of 12 September 2025 — comprising four templates (Data Holder→User, User→Data Recipient, Data Holder→Data Recipient, Data Sharer→Data Recipient). Art. 13's unfair-terms regime, applicable to contracts concluded after 12 September 2025, defines a general fairness test ("grossly deviates from good commercial practice"), a blacklist of automatically-void terms (e.g. excluding liability for intent/gross negligence, giving one party sole right to interpret contract terms), and a rebuttable greylist (e.g. unilateral short-notice termination, unilateral price adjustment). [eu-data-act-art13-mct]
- **UK Open Banking is the strongest-adoption regulated consent regime in raw volume terms outside India's AA**: June 2026 monthly API traffic hit a record 2.81 billion calls (cumulative API calls passed 100 billion), while user connections registered a 4.2% monthly decline to 18.81 million in the same month — a traffic-up/users-down divergence OBL flagged without further comment. Full-year 2025: 24 billion API calls (+27% YoY), 16.5 million user connections by Dec 2025 (+36% YoY from 12.1M), ~80% of API traffic Account Information Services. Adoption penetration: "one in five" UK consumers/businesses using Open Banking as of May 2025, up from "one in 17" in March 2021. [uk-open-banking-scale]
- **Australia's Consumer Data Right (CDR) is the clearest failure/reset signal in this survey.** Assistant Treasurer Stephen Jones (9 Aug 2024) called CDR "a good idea, badly executed," announcing a reset that: permitted bundling multiple consents into a single user action (a simplification/weakening of per-purpose granularity, moving opposite to GDPR's granularity principle); dropped a considered principles-based ban on dark patterns in favor of non-binding guidance; narrowed mandatory-sharing scope for several product categories (2025 draft rules) and capped transaction-history requests at 2 years; introduced a Standards Assessment Framework explicitly capping the number of rule-change releases per year (a deliberate slow-down mechanism). The only concrete adoption figures found are from an ACCC submission dated 14 August 2024: 149 active CDR representative arrangements across 8 accredited data recipients, 41 total accredited data recipients — with no updated 2025/2026 headline figure found, itself a contrast signal against Sahamati's continuously-updated dashboard. [cdr-australia-reset]
- **The US's only close analog to AA/CDR/Open Banking as a legally mandated financial-data-portability-with-consent regime, CFPB Section 1033, is currently non-operative.** Finalized October 2024 with phased compliance beginning 1 April 2026 for the largest providers; immediately challenged in court; the CFPB itself (under an administration change) sought to vacate/set aside its own rule; a court instead granted a preliminary injunction enjoining CFPB from enforcing the rule while it completes reconsideration. On 22 August 2025, CFPB published an Advance Notice of Proposed Rulemaking reopening core questions (definition of "representative" third parties, whether data providers can charge fees, adequacy of data-security standards), receiving 13,981 comments. As of this research, the rule is "enjoined and under reconsideration" — the April 2026 compliance date passed without becoming a binding trigger, described by counsel as "a rule that exists on paper, but not in practice." [cfpb-1033-status]
- **HL7 FHIR's Consent resource is confirmed unnecessary for the core SMART on FHIR OAuth authorization flow** — the R5 spec states there is "no need for the consent resource as part of the SMART on FHIR Authorization process"; SMART's actual mechanism is OAuth 2.0 scopes, not the Consent resource. Evidence points to near-zero production use of the FHIR Consent resource as a structured artifact, in sharp contrast to SMART scopes, which are genuinely ubiquitous wherever FHIR APIs exist across every major US EHR vendor. R5 itself lags R4 in production — US regulation (ONC certification, US Core IG) remains anchored to R4. [fhir-consent-vs-smart]
- **HIPAA §164.508's Authorization requirements are a legally mandated content spec for a human-readable consent document, not a machine-readable schema** — no HIPAA-standard JSON/XML consent object exists. Required elements: description of the PHI to be used/disclosed; who may disclose and who may receive it; purpose of the use/disclosure; expiration date or event; signature and date. Mandatory statements also required: revocation right (may revoke in writing at any time, with a limited carve-out where authorization was a condition of obtaining insurance coverage); conditioning notice (whether treatment/payment/enrollment is conditioned on signing); re-disclosure warning (PHI may be re-disclosed by the recipient and lose HIPAA protection). This is the oldest "required fields for a consent artifact" regime surveyed, dating to the original Privacy Rule (2000-2003), but it specifies document content, not a schema. [hipaa-164-508]

## SOURCES

**aa-rebit-spec**
URL: https://specifications.rebit.org.in/artefacts/NBFC-AA_API_Specification_v2.0.0.pdf
Accessed: 2026-09-03
Quote: NBFC-AA API Specification v2.0.0 — `ConsentDetail` fields include `consentMode` (VIEW/STORE/QUERY/STREAM), `fetchType` (ONETIME/PERIODIC), `consentTypes`, `fiTypes`, `DataConsumer`/`DataProvider`, `Customer` (`customer_identifier@AA_identifier`), `Purpose {code, refUri, text, Category}`, `FIDataRange {from, to}`, `DataLife {unit, value}`, `Frequency`, `DataFilter`, AA digital signature.

**aa-purpose-codes**
URL: https://sahamati.org.in/purpose-codes/
Accessed: 2026-09-03
Quote: Five-code purpose taxonomy — Category 1 Personal Finance (101 wealth management, 102 spending patterns/budget/reporting), Category 2 Financial Reporting (103 aggregated statement), Category 3 Account Query and Monitoring (104 explicit consent for monitoring, 105 explicit one-time consent).

**aa-sahamati-scale**
URL: https://sahamati.org.in (SRO recognition materials, FY26 report published 24 June 2026)
Accessed: 2026-09-03
Quote: 1,120+ live regulated financial entities, 176 FIPs, 1,020 FIUs, 17 operational AAs, 450M+ consent requests fulfilled, 294M+ linked accounts, 290M+ monthly data shares. FY26: ~3.8 crore financial products/services facilitated, 45+ crore cumulative consents, 500+ crore cumulative data fetches, >7 lakh consents processed daily, 5.96 crore PFM users at 164% CAGR since FY23.

**aa-dvara-critique**
URL: https://dvararesearch.com (consent-artefact comprehension critique)
Accessed: 2026-09-03
Quote: Users give the artefact "a cursory glance" and are "pre-programmed to accept"; consent formally satisfied but substantively hollow for a large share of users, especially lower-income/less-educated/first-generation digital-finance users.

**dpdp-rules-timeline**
URL: https://dpdpa.com (DPDP Act/Rules text)
Accessed: 2026-09-03
Quote: Rules notified 13 November 2025; Phase 2 (13 Nov 2026) opens Consent Manager registration, unregistered entities barred from operating; Phase 3 (13 May 2027) brings core operative rules (notice, consent, security, breach reporting, retention, children's data) into force.

**gdpr-art20**
URL: https://gdpr-info.eu/art-20-gdpr/
Accessed: 2026-09-03
Quote: Art. 20(2) — right to have data transmitted directly controller-to-controller "where technically feasible." WP29 WP242 rev.01 (adopted 5 April 2017) recommends industry-developed interoperable standards, aspirational only.

**eu-data-act-art13-mct**
URL: https://eu-data-act.com ; https://data-act-law.eu (Art. 13 text); Commission MCT Recommendation (20 Nov 2025)
Accessed: 2026-09-03
Quote: Art. 13(3) general fairness test — a term is unfair if it "grossly deviates from good commercial practice in data access and use, contrary to good faith and fair dealing." MCTs published as a Recommendation 20 November 2025, delayed from the 12 September 2025 statutory deadline.

**uk-open-banking-scale**
URL: https://www.openbanking.org.uk (Impact Reports)
Accessed: 2026-09-03
Quote: June 2026 monthly API traffic hit 2.81 billion calls (+4.4% MoM), cumulative calls passed 100 billion; user connections declined 4.2% MoM to 18.81 million same month. Full-year 2025: 24 billion API calls (+27% YoY), 16.5 million user connections by Dec 2025 (+36% YoY).

**cdr-australia-reset**
URL: https://www.accc.gov.au ; Ashurst/CEDA event coverage, 9 August 2024
Accessed: 2026-09-03
Quote: Stephen Jones: CDR is "a good idea, badly executed." Only concrete adoption figures found: ACCC submission, 14 August 2024 — 149 active CDR representative arrangements across 8 accredited data recipients, 41 total accredited data recipients.

**cfpb-1033-status**
URL: https://www.consumerfinance.gov ; https://www.federalregister.gov (1033 ANPR, 22 August 2025)
Accessed: 2026-09-03
Quote: Rule finalized October 2024, phased compliance from 1 April 2026; preliminary injunction enjoining CFPB enforcement pending reconsideration; ANPR published 22 August 2025 received 13,981 comments; described by counsel as "a rule that exists on paper, but not in practice."

**fhir-consent-vs-smart**
URL: https://hl7.org/fhir/consent.html (R5 spec)
Accessed: 2026-09-03
Quote: "no need for the consent resource as part of the SMART on FHIR Authorization process" — SMART's actual mechanism is OAuth 2.0 scopes, not Consent.

**hipaa-164-508**
URL: 45 CFR §164.508 (via accountablehq.com / legalclarity.org summaries)
Accessed: 2026-09-03
Quote: Required Authorization elements — description of PHI, who may disclose/receive, purpose, expiration date/event, signature and date; mandatory revocation-right, conditioning-notice, and re-disclosure-warning statements.

## SYNTHESIS

The clearest pattern across every regulated consent regime surveyed is that **scale correlates with the recipient authoring terms within a closed, regulator-controlled taxonomy, and the user's role being reduced to narrow/accept/decline rather than propose or negotiate.** India's Account Aggregator is the largest system in the survey by a wide margin (450M+ cumulative consents, growing ~700K/day) and is also the most rigidly closed: five numeric purpose codes covering the entire national financial-data ecosystem, an FIU-drafted request the user can only narrow or reject, and no counter-proposal mechanism of any kind. UK Open Banking's raw traffic (2.81B calls/month) is larger still, but on a comparably closed permission-enum model. Both are recipient-proposes/user-narrows systems, and both are the strongest adoption stories in the survey.

Every regime that tried to give the individual a more expressive or more negotiated role produced dramatically less real usage, or none. GDPR Art. 20's direct-transmission right — the closest EU analog to letting an individual actually redirect their own data on their own terms — has an explicit "technically feasible" escape hatch and, per the assembled evidence, produced no meaningful uptake in eight years; the EU's own response was not to strengthen Art. 20 but to write entirely new, more prescriptive regimes (Data Act, DMA) alongside it. CFPB 1033 — the US's most direct attempt at a Consumer-Data-Right-style mandate — is enjoined and non-operative as of this research, despite having passed its own compliance deadline. Australia's CDR is a documented reset-in-progress specifically because five years of operation produced low uptake and high compliance cost; notably, part of the reset was to simplify by *permitting bundled consent*, i.e., moving toward the AA/Open-Banking shape (fewer, coarser consent actions) rather than away from it. FHIR Consent as a structured resource is close to unused in production despite being fully specified for a decade, precisely because SMART's simpler scope-based mechanism satisfies the same functional need without asking anyone to model a bespoke consent object.

The oldest regimes in the set (HIPAA §164.508, and by extension COPPA/UK AADC, not detailed in the claims above but consistent with the pattern) never attempted a machine-readable object at all — they mandate document *content*, leaving the artifact itself as paper/PDF. This suggests a three-tier taxonomy for "how prescriptive can a consent regime get and still see real usage": (1) mandate content only, no schema — universal but manual (HIPAA); (2) mandate a schema with a closed, regulator-owned taxonomy and narrow-only user agency — the two regimes that actually scaled (AA, UK Open Banking); (3) mandate or permit a schema with open-ended purpose text and genuine bilateral negotiation or direct-transfer rights — GDPR Art. 20, CFPB 1033, FHIR Consent — none of which achieved comparable real-world usage. Any design that wants machine-readable consent at real scale should treat tier 2's shape (closed taxonomy, recipient drafts, user narrows/accepts/declines/revokes) as the empirically supported target, and should treat "let the user author or negotiate the terms" as a design choice with no successful large-scale precedent in this survey — not a reason to avoid it, but a claim that needs its own evidence rather than borrowed credibility from AA's numbers, since AA's scale comes from doing the opposite.

Dvara Research's critique is the one counterweight worth keeping close: even AA's formal-compliance success coexists with evidence that most users don't read or meaningfully engage with the artifact they're approving. This suggests the "scale" figures above measure adoption of the plumbing, not evidence that users are meaningfully exercising informed consent — a distinction any design citing AA's 450M+ number as a success story should carry forward explicitly rather than launder into "consent worked here."
