---
title: "India Account Aggregator proves machine-readable consent objects can operate at national scale when regulation fixes the parties, fields, and duties"
date: 2026-09-03
topic: consent-regimes
tags: [india, account-aggregator, consent, open-banking, cdr, fhir]
status: draft
sources: [rbi-aa, india-usage, dpdp, uk-ob, au-cdr, fhir]
source_session: unknown
---

## CLAIMS

- India's Account Aggregator framework requires a signed electronic consent artefact containing the customer, data, purpose, recipients, dates, Account Aggregator identity, and revocation support; the artefact must be loggable, auditable, and verifiable. [rbi-aa]
- On 2025-09-02 India's Ministry of Finance reported 112.34 million users with linked accounts, 2.2 billion enabled accounts, 112 entities acting as both data providers and users, 56 provider-only entities, and 410 user-only entities. [india-usage]
- India's DPDP Act creates registered Consent Managers through which a person can give, manage, review, and withdraw consent. The 2025 Rules add an interoperable platform and seven-year accessible, machine-readable records, but the relevant rule begins only on 2026-11-13. [dpdp]
- UK Open Banking mandates dashboards for viewing and revoking ongoing consent; operator telemetry for 2025 reports 24 billion successful API calls, 351 million payments, and 16.5 million non-deduplicated user connections. [uk-ob]
- Australia's CDR mandates recipient and holder dashboards and easy withdrawal. Regulator evidence shows broad bank coverage but Treasury later cited limited uptake and high compliance cost. [au-cdr]
- FHIR R5 Consent separates computable policy basis, human-readable policy text, verification, parties, purpose, period, data, and nested permit/deny provisions. [fhir]

## SOURCES

**rbi-aa**
URL: https://www.rbi.org.in/scripts/BS_ViewMasDirections.aspx?id=10598
Accessed: 2026-09-03
Quote: "capable of being logged, audited and verified"

**india-usage**
URL: https://www.pib.gov.in/PressReleasePage.aspx?PRID=2162953&lang=1&reg=3
Accessed: 2026-09-03
Quote: "112.34 million users having already linked their accounts"

**dpdp**
URL: https://www.meity.gov.in/static/uploads/2025/11/53450e6e5dc0bfa85ebd78686cadad39.pdf
Accessed: 2026-09-03

**uk-ob**
URL: https://www.openbanking.org.uk/insights/open-banking-in-2025-now-part-of-the-uks-everyday-financial-life/
Accessed: 2026-09-03

**au-cdr**
URL: https://www.oaic.gov.au/consumer-data-right/consumer-data-right-guidance-for-business/privacy-obligations/consumer-consent%2C-authorisation-and-dashboards
Accessed: 2026-09-03

**fhir**
URL: https://hl7.org/fhir/consent-definitions.html
Accessed: 2026-09-03

## SYNTHESIS

The successful pattern is not open-ended private negotiation. A regulator defines a bounded domain, participant roles, a minimum consent schema, authentication, revocation, audit, and liability. The consent intermediary executes that framework. India AA is the strongest adoption precedent for PDPP, while Australia's weaker uptake warns that mandated coverage does not prove demand. FHIR offers the cleanest field separation: authorization evidence should not collapse purpose, legal basis, notice, agreement, and enforcement into one URI.
