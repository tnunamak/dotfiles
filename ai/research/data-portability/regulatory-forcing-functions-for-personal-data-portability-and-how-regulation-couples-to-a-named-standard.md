---
title: "Regulatory forcing functions for personal-data portability vary sharply in strength; DMA Article 6(9) is a live mandate with no technical standard, while the two success precedents (SMART on FHIR, UK Open Banking) each paired an outcome mandate with an industry-authored standard adopted by reference plus a second enforcement lever"
date: 2026-07-06
topic: data-portability
tags: [dma, eu-data-act, gdpr, cfpb-1033, open-banking, smart-on-fhir, open-finance, cdr, regulation, prior-art]
status: draft
sources: [dma-6-9, ec-gatekeepers, scida-dma, dti-blog, ec-data-act, gdpr-art20, edpb-wp242, com2020-264, cfpb-1033, cfpb-fdx, bpi-1033, cfpb-anpr, onc-g10, jamia-smart, argonaut-hitn, hhs-oig-blocking, cma-order-2017, fca-fs254, duaa-2025, pib-aa, prs-dpdp, anpd-index, cdr-review]
---

## CLAIMS

- DMA (Regulation (EU) 2022/1925) Article 6(9) obliges designated gatekeepers to give end users and user-authorized third parties effective portability of user-provided and activity-generated data, including continuous and real-time access, free of charge — the only DMA provision mandating an outbound continuous/real-time portability channel (distinct from the Art. 5(2)/6(2) data-use *restrictions*). As of research, 7 gatekeepers / 23 core platform services are designated (Alphabet, Amazon, Apple, Booking.com, ByteDance, Meta, Microsoft). [dma-6-9] [ec-gatekeepers]
- At the March 2024 first-compliance deadline no gatekeeper shipped a purpose-built Article 6(9) API; all retrofit GDPR-era export tooling (Google/Amazon/Booking.com/TikTok "Data Portability API", Apple Account Data Transfer API, LinkedIn Member Data Portability), with Meta only unifying DYI/TYI into "Export Your Information" ~2 years later. No Commission enforcement action or specification proceeding has ever targeted Article 6(9) specifically, though the Commission has opened prescriptive Art. 6(7)/6(11) proceedings (Apple Sept 2024, Google Jan 2026) — showing it can mandate technical specificity but has chosen not to for portability. [scida-dma]
- The Data Transfer Initiative (dtinit.org; Founding Members Apple, Google, Meta) has engaged with Article 6(9) but explicitly declines to build or endorse one shared technical standard: "designated gatekeepers have developed... interfaces... not reliant on a shared data model or open source code base... There is no silver bullet for data portability, now or in the future." Its Data Transfer Project is reserved for narrower verticals (photo/playlist). Net: DMA 6(9) is a live, unfilled standards gap. [dti-blog]
- EU Data Act (Regulation (EU) 2023/2854) entered into force 11 Jan 2024, applies from 12 Sept 2025 (Art. 3(1) "access by design" delayed to 12 Sept 2026); Arts. 3–5 require connected-product/related-service data be made available to the user (and a user-designated third-party "data recipient") free, in a structured/commonly-used/machine-readable format, "continuously and in real-time where technically feasible" — more prescriptive than DMA 6(9). Art. 5(3) bars DMA gatekeepers from being eligible data recipients (anti-circularity). Interoperability provisions are Arts. 33–36 (not the draft-stage "28–30"). Technical specification is deferred to CEN/CENELEC/ETSI under Commission Mandate M/614 (accepted 7 July 2025; 4 EN + 3 TS called for), of which only EN 18235-1:2026 (terminology, March 2026) is published — interoperability Part 3 due May 2027. [ec-data-act]
- GDPR Article 20 underdelivered by design: Recital 68 states the right "should not create an obligation for controllers to adopt or maintain processing systems which are technically compatible" (interoperability encouraged, not required); the right covers only actively-provided data (WP242), and 20(2) direct transfer applies only "where technically feasible." The Commission's own 2020 evaluation (COM(2020) 264) named "Unused Potential of Data Portability Rights" as a problem, and its later fix was to legislate elsewhere (Data Act, DMA), not amend Article 20. [gdpr-art20] [edpb-wp242] [com2020-264]
- US CFPB Section 1033 rule (finalized 22 Oct 2024, 12 CFR Part 1033) mandates "developer interfaces" but delegates the technical standard to a CFPB-recognition process for industry standard-setting bodies; on 8 Jan 2025 CFPB recognized the Financial Data Exchange (FDX) as the first such body (through Jan 2030). The rule was challenged same-day (BPI et al., E.D. Ky.); CFPB under new leadership reversed position (23 May 2025, "the Rule is unlawful and should be set aside"), then petitioned to stay and re-do the rulemaking; issued an ANPR (Aug 2025) questioning the "authorized third party" mechanism; and in late Oct 2025 the court issued a preliminary injunction enjoining enforcement (finding "representative" likely means fiduciary-type, undercutting third-party access). As of 2026-07-06 the rule is enjoined, not vacated. [cfpb-1033] [cfpb-fdx] [bpi-1033] [cfpb-anpr]
- US state privacy laws (CCPA/CPRA, Colorado CPA — capped twice/year, Virginia VCDPA, Connecticut CTDPA) all use GDPR-Art.-20-style "to the extent technically feasible" language satisfied by one-shot exports; none mandate a technical portability standard or continuous-access API. [cfpb-1033]
- ONC's 2020 Cures Act Final Rule ratified a bottom-up standard by reference: 45 CFR 170.315(g)(10) explicitly names "HL7 FHIR Release 4, Version 4.0.1: R4" plus the SMART App Launch Framework and FHIR Bulk Data Access. The lineage: ONC-funded SMART (~2010, $15M to Boston Children's/Harvard) → SMART ported onto FHIR contributing OAuth2 "SMART App Launch" (2013) → industry-initiated/funded Argonaut Project under HL7 (2014, Epic/Cerner/athenahealth/etc., "completely private sector initiated and funded, not an ONC edict" per Micky Tripathi) built the US Core profiles → ONC ratified the mature standard by name (2020). Enforcement is two-pronged: certification (binds vendors) + the separate information-blocking prohibition (binds providers/HIEs, penalties up to $1M/violation for developers/HIEs from 1 Sept 2023, CMS payment disincentives for providers from 1 July 2024). [onc-g10] [jamia-smart] [argonaut-hitn] [hhs-oig-blocking]
- UK Open Banking: the CMA Retail Banking Market Investigation Order 2017 did not specify a technical standard — it mandated an institutional process (Part 2, Art. 10: providers "shall... set up an entity (the 'Implementation Entity') that will agree, consult upon, implement, maintain and make widely available, without charge open and common banking standards"). Chronology: CMA final report 9 Aug 2016 → CMA9 voluntarily incorporate Open Banking Ltd Sept 2016 → OBIE drafts the standard from scratch Oct–Dec 2016 → Order formally made 2 Feb 2017 → Read/Write go-live 13 Jan 2018. PSD2 gave the EU-wide legal access right + security floor (RTS on SCA) but mandated no API technology; the CMA Order compelled one common API. Governance is mid-transition: JROC has been wound down (FCA FS25/4, Aug 2025) with the FCA named lead regulator; no permanent successor entity exists in final form yet. [cma-order-2017] [fca-fs254]
- Australia CDR: rolled out banking (2020) then energy; a July 2024 Strategic Review found only 0.31% of bank customers had an active data-sharing arrangement at end-2023 against ~AU$1.5B compliance spend, prompting a reset (expansion to non-bank lending/BNPL, +AU$88.8M funding), not abandonment; action initiation legislated 2024. [cdr-review]
- India's enacted DPDP Act 2023 has no data-portability right (a deliberate removal from the 2018/2019 drafts); the real precedent is the RBI-regulated Account Aggregator framework under DEPA (live since Sept 2021), a three-party model issuing a cryptographically signed, time-bound, purpose-bound "consent artifact," with 17 licensed AAs / 2.2B accounts enabled / 112.34M users linked (2 Sept 2025) — but FIP/FIU participation is voluntary. Brazil's Open Finance Brasil (BCB+CMN resolutions, phased, ~95% coverage target) is FAPI/OAuth2/OIDC-based, OpenID-Foundation-certified, with granular scoped consent and ~171M active authorizations — grown from a financial-regulator mandate, not LGPD (whose Art. 18 portability is unregulated by ANPD). UK's Data (Use and Access) Act 2025 is a per-sector enabling framework (each sector gets its own interface body), producing N sectoral standards rather than one. [pib-aa] [prs-dpdp] [anpd-index] [duaa-2025]

## SOURCES

**dma-6-9**
URL: https://www.eu-digital-markets-act.com/Digital_Markets_Act_Article_6.html
Accessed: 2026-07-06
Quote: "Secondary mirror of the statutory text; EUR-Lex unreachable this session — high confidence on substance, medium on exact wording pending direct EUR-Lex re-check."

**ec-gatekeepers**
URL: https://digital-markets-act.ec.europa.eu/gatekeepers-portal_en
Accessed: 2026-07-06

**scida-dma**
URL: https://scidaproject.com/2026/04/02/dma-compliance-reports-in-year-three-reading-between-the-many-lines/
Accessed: 2026-07-06
Quote: "Per-company compliance-report URLs not independently re-verified; spot-check Meta's ~2-year lag before external quoting."

**dti-blog**
URL: https://dtinit.org/blog/ (incl. 2024/03/26 "Progress towards real world portability solutions" and 2026/02/24 "Putting a price on portability")
Accessed: 2026-07-06
Quote: "designated gatekeepers have developed... interfaces... not reliant on a shared data model or open source code base... There is no silver bullet for data portability, now or in the future."

**ec-data-act**
URL: https://digital-strategy.ec.europa.eu/en/policies/data-act
Accessed: 2026-07-06
Quote: "Article numbering (33–36), Art. 5(3) anti-circularity, and M/614 status flagged for direct EUR-Lex / CEN-CENELEC re-verification before external citation."

**gdpr-art20**
URL: https://gdpr-info.eu/art-20-gdpr/
Accessed: 2026-07-06
Quote: "should not create an obligation for controllers to adopt or maintain processing systems which are technically compatible"

**edpb-wp242**
URL: https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-right-data-portability-under-regulation-2016679_en
Accessed: 2026-07-06

**com2020-264**
URL: https://www.europarl.europa.eu/RegData/docs_autres_institutions/commission_europeenne/com/2020/0264/COM_COM(2020)0264_EN.pdf
Accessed: 2026-07-06

**cfpb-1033**
URL: https://www.consumerfinance.gov/rules-policy/regulations/1033/ ; https://www.ecfr.gov/current/title-12/chapter-X/part-1033
Accessed: 2026-07-06

**cfpb-fdx**
URL: https://files.consumerfinance.gov/f/documents/cfpb_standard-setter-decision-and-order-of-recognition-fdx_2025-01.pdf
Accessed: 2026-07-06

**bpi-1033**
URL: https://bpi.com/section1033/
Accessed: 2026-07-06

**cfpb-anpr**
URL: https://www.federalregister.gov/documents/2025/08/22/2025-16139/personal-financial-data-rights-reconsideration
Accessed: 2026-07-06

**onc-g10**
URL: https://www.healthit.gov/isp/svap-reference-standard/ss-170315g10-standardized-api-patient-and-population-services
Accessed: 2026-07-06
Quote: "Names 'HL7 FHIR Release 4, Version 4.0.1: R4, October 30, 2019, including Technical Correction #1, November 1, 2019' plus SMART App Launch + FHIR Bulk Data Access."

**jamia-smart**
URL: https://academic.oup.com/jamia/article/23/5/899/2379865
Accessed: 2026-07-06

**argonaut-hitn**
URL: https://www.healthcareitnews.com/news/argonaut-project-building-success-fhir-implementation-guide
Accessed: 2026-07-06
Quote: "It's completely private sector initiated and funded, not an ONC edict." (Micky Tripathi)

**hhs-oig-blocking**
URL: https://oig.hhs.gov/reports/featured/information-blocking/
Accessed: 2026-07-06

**cma-order-2017**
URL: https://www.gov.uk/government/publications/retail-banking-market-investigation-order-2017/the-retail-banking-market-investigation-order-2017
Accessed: 2026-07-06
Quote: "Providers shall... set up an entity (the 'Implementation Entity') that will agree, consult upon, implement, maintain and make widely available, without charge open and common banking standards..."

**fca-fs254**
URL: https://www.fca.org.uk/publications/feedback-statements/fs25-4-design-future-entity-open-banking
Accessed: 2026-07-06
Quote: "The National Payments Vision (NPV) named the FCA as the lead regulator to progress open banking. JROC has been wound down."

**duaa-2025**
URL: https://www.legislation.gov.uk/ukpga/2025/18/contents/enacted
Accessed: 2026-07-06

**pib-aa**
URL: https://www.pib.gov.in/PressReleasePage.aspx?PRID=2162953&reg=48&lang=2
Accessed: 2026-07-06

**prs-dpdp**
URL: https://prsindia.org/billtrack/digital-personal-data-protection-bill-2023
Accessed: 2026-07-06

**anpd-index**
URL: https://www.gov.br/anpd/pt-br/acesso-a-informacao/institucional/atos-normativos/regulamentacoes_anpd
Accessed: 2026-07-06

**cdr-review**
URL: https://www.ausbanking.org.au/wp-content/uploads/2024/07/CDR-Strategic-Review_July-2024.pdf
Accessed: 2026-07-06

## SYNTHESIS

The regulatory landscape for personal-data portability splits into weak "right on paper" hooks and strong "mandate + named standard + enforcement" precedents. GDPR Article 20 is the negative control: a general right that explicitly declined to require interoperability (Recital 68) and converged on one-shot export dashboards; US state privacy laws copy this shape. DMA Article 6(9) is the strongest *open* hook — a live, binding obligation for continuous/real-time/free third-party-authorized access — precisely because no technical standard exists and the one industry body positioned to build one (DTI) has explicitly declined to converge; the EU Data Act's interoperability track (Arts. 33–36) is the second-best because a formal CEN/CENELEC standardization process (M/614) is already underway with most deliverables unfinished. The two success precedents share a four-part shape that the failures lacked: (1) the regulator mandates an *outcome or institutional process*, not the spec itself; (2) a standard is authored either by a multi-year industry/academic effort (FHIR/Argonaut) or a newly-mandated industry body under a hard clock (OBIE, ~4–5 months to first draft); (3) the regulator locks it in *by reference* (45 CFR 170.315(g)(10) naming FHIR R4 by exact version; OBIE's standard as the de facto PSD2 compliance path); and (4) a *second, independent enforcement lever* reaches parties the primary rule can't (information-blocking's CMS disincentives beyond vendor certification; FCA/PSD2 authorization beyond the CMA9). Adoption-by-reference has never happened faster than ~18 months (OBIE, only because of a hard deadline + day-one full funding) and usually takes years (FHIR ~2010–2020) — and every case required proven running implementations, a neutral multi-stakeholder governance body with competing implementers, a conformance/certification suite, and precise version pinning before a regulator would name the standard in binding text. Note: several EU/US/India/Brazil primary-source domains were fetch-blocked at research time; the highest-stakes statutory-wording and article-numbering claims are flagged in SOURCES for direct re-verification before any external-facing use.