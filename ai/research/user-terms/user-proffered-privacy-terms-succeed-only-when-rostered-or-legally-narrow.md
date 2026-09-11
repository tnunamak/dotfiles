---
title: "User-proffered privacy terms have succeeded only as small rosters or narrow signals with an external enforcement hook"
date: 2026-09-03
topic: user-terms
tags: [privacy, myterms, ieee-7012, gpc, dnt, p3p]
status: draft
sources: [ieee-7012, me2b-pilot, gpc-ca, sephora, p3p, dnt, dpv-23]
source_session: unknown
---

## CLAIMS

- IEEE 7012-2025 makes the person the first party, uses standard-form agreements in a neutral roster, places party-to-party negotiation outside scope, and requires both parties to sign and retain matching records. [ieee-7012]
- The located Me2B/Internet Safety Labs pilot exercised one hard-coded business agreement with one business and four moderated participants; its report says the sample cannot support generalization, and the business judged support for many policies likely untenable. [me2b-pilot]
- California requires covered businesses to treat a qualifying browser signal such as GPC as a valid sale/share opt-out; the Sephora settlement imposed a $1.2 million payment and an obligation to honor GPC. [gpc-ca] [sephora]
- W3C obsoleted P3P after reporting support on fewer than 6% of the top 10,000 sites and no current interpreting user agents. W3C retired DNT, and browser vendors later removed it after sites largely ignored it and the bit created fingerprinting surface. [p3p] [dnt]
- DPV 2.3 now lists `STANDARD-IEEE-7012`; the bridge is not stranded. DPV remains a W3C Community Group report, not a W3C Standard. [dpv-23]

## SOURCES

**ieee-7012**
URL: https://standards.ieee.org/ieee/7012/7192/
Accessed: 2026-09-03
Quote: "Party-to-party negotiations over terms of an agreement are outside the scope of this standard."

**me2b-pilot**
URL: https://internetsafetylabs.org/wp-content/uploads/2022/06/spotlight-report-6-ieee-p7012-pilot-project-report.pdf
Accessed: 2026-09-03
Quote: "The number of participants is too small to generalize."

**gpc-ca**
URL: https://oag.ca.gov/privacy/ccpa
Accessed: 2026-09-03
Quote: "it must be honored by covered businesses as a valid consumer request"

**sephora**
URL: https://oag.ca.gov/news/press-releases/attorney-general-bonta-announces-settlement-sephora-part-ongoing-enforcement
Accessed: 2026-09-03

**p3p**
URL: https://www.w3.org/TR/P3P/
Accessed: 2026-09-03
Quote: "fewer than 6% of the 10,000 most frequently visited websites support P3P"

**dnt**
URL: https://www.w3.org/TR/tracking-dnt/
Accessed: 2026-09-03

**dpv-23**
URL: https://w3id.org/dpv/
Accessed: 2026-09-03
Quote: "Currently it provides the extension STANDARD-IEEE-7012"

## SYNTHESIS

The decisive variable is not expressive power. GPC gained legal force by carrying one narrow meaning into a regime with compulsory response and enforcement. P3P and DNT lacked that combination. IEEE 7012 sensibly caps evaluation cost with standard forms, but its only located transaction evidence exposes the recipient review burden. For protocol design, copy the roster, exact-version, two-party-signature, and matching-record invariants. Do not describe IEEE as a negotiation protocol, and do not infer adoption from publication.
