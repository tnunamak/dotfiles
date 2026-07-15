---
title: "User-controlled personal-data protocols (UMA, Solid, DataPortability.org, Locker/Singly, Mydex, HAT) failed adoption for a shared set of reasons — no regulatory forcing function, no durable demand-side consumer, required platform cooperation — while SMART on FHIR and UK Open Banking succeeded by pairing a legal mandate with a conformance regime"
date: 2026-06-24
topic: data-portability
tags: [uma, solid, personal-data-stores, data-portability, smart-on-fhir, open-banking, standards-adoption, prior-art]
status: draft
sources: [kantara-uma1, uma2-grant, wso2-uma, forgerock-uma, hie-of-one, uma-core, arxiv-uma, richer-uma2, inrupt-techcrunch, inrupt-axios, odi-solid, latka-inrupt, odi-symposium, solid-forum-adoption, verborgh-pods, dodds-solid, demartin-solid, newstack-solid, chrissaad, adweek-dataportability, oreilly-locker, forbes-locker, allthingsd-singly, mydex-paper, mydex-companies-house, dataswift-site, snyk-hatjs, smart-fhir-descope, openbanking-roadmap]
---

## CLAIMS

- UMA (User-Managed Access) is a Kantara Initiative OAuth 2.0-based protocol for party-to-party authorization (resource owner sets policies letting a *different* party get async access). UMA 1.0 was approved as a Kantara Recommendation 2015-03-23 (announced 2015-05-05); UMA 2.0 published February 2018 as two specs — "UMA Grant for OAuth 2.0 Authorization" (core) and optional "Federated Authorization for UMA 2.0" — edited by Eve Maler (ForgeRock). Implementers included ForgeRock, Gluu, MITREid Connect, Atricore, Node-UMA, Keycloak, WSO2 Identity Server. [kantara-uma1] [uma2-grant] [wso2-uma] [forgerock-uma]
- UMA is purely an authorization/access-control protocol: it standardizes resource registration, the permission-ticket flow, and token issuance/introspection, and explicitly scopes OUT the resource data model, the query/read API, and any collection/ingestion story — the UMA core spec states resource partitioning and "whether the resource server has a programmatic API or serves up simple web pages" are "outside the scope of this specification." An academic analysis notes UMA "does not prescribe any interaction between multiple ASs," so cross-AS federation is not delivered out of the box. [uma-core] [arxiv-uma]
- UMA never broadened for reasons partly orthogonal to that data-model gap: a heavier 5-party model vs. plain OAuth's 2–3 parties; UMA 1.0's assumption that a requesting party could already get a token from the resource owner's AS broke in a healthcare pilot for sharing *outside* an institution (documented by UMA contributor Justin Richer); its own maintainers found much 1.0 flexibility was unused dead weight (object/list-typed extension points flattened to strings/numbers, and the AAT token type dropped entirely in 2.0); and it was presented to the IETF OAuth WG at IETF 104 (March 2019) but never taken up by IETF. [richer-uma2] [uma-core]
- Adrian Gropper's HIE of One built a patient-centered health-record reference implementation on a self-sovereign UMA Authorization Server — real-world confirmation UMA's authorization pattern is usable for personal-data consent, but it stayed a pilot/reference implementation rather than a deployed institutional standard. [hie-of-one]
- Solid (Tim Berners-Lee; Pods, Linked Data, WebID) is commercialized by Inrupt, which raised a $30M Series A in December 2021 (led by Forte Ventures; Akamai, Glasswing, Allstate, Minderoo among participants) on ~$225K prior-year revenue. In October 2024 the Open Data Institute became steward of the Solid project; Inrupt pivoted to AI-memory framing and a "Data Wallet" preview (Sept 2024). Low-confidence aggregator data (Latka) put Inrupt around $3.2M ARR / $9.6M valuation in a 2025 snapshot. [inrupt-techcrunch] [inrupt-axios] [odi-solid] [latka-inrupt] [odi-symposium]
- Solid's adoption blockers, sourced to named Solid-community practitioners: a business-model conflict (it needs the data-holding platform to expose a Pod, or the user to self-host — GAFAM have no incentive) [solid-forum-adoption]; no standardized app-facing API contract — Verborgh: "the Solid Protocol is not a Web API — rather, it allows and requires each individual app to decide where and how they store Linked Data," so apps can't reliably reuse each other's data [verborgh-pods]; access control historically applied per-Pod rather than per-resource, pushing users to multiple Pods [dodds-solid]; and "log in with Solid" onboarding is cited by De Martin as "the single most important issue holding Solid back." [demartin-solid] [newstack-solid]
- DataPortability.org (founded Nov 2007) peaked Jan 2008 when Google, Facebook, and Plaxo joined, but membership meant only "engaging in the conversation," it shipped no technical spec of its own, and it was out-competed when Facebook shipped the proprietary Facebook Connect; listed as permanently closed. [chrissaad] [adweek-dataportability]
- The Locker Project (BSD OSS by Jeremie Miller, XMPP originator) let users collect their "digital wake" via connectors/"synclets," funded by Singly (founded 2010; Venrock, True Ventures, TechStars); hit v1.0 Oct 2011 with Facebook/LinkedIn/Twitter/Fitbit/RunKeeper/Instagram connectors — the closest historical analog to a connector-based personal-data collection model. Singly pivoted away from the open platform by end-2012 and was acquired by Appcelerator in August 2013 with "only a few customers"; the failure mode was no durable demand-side consumer of the collected data. [oreilly-locker] [forbes-locker] [allthingsd-singly]
- Mydex CIC (founded 2007, Edinburgh) structured as a Community Interest Company for "trustworthy by design" signaling (asset lock, 35% dividend cap); was an early GOV.UK Verify identity provider but was not carried into the next framework after ~2017; its own 2021 strategy paper explicitly does "not expect or plan for large-scale adoption in the short term," describing deliberate incremental cluster-by-cluster growth. The CIC dividend cap also foreclosed venture scaling — a direct trust-vs-growth-capital trade-off. [mydex-paper] [mydex-companies-house]
- Hub-of-All-Things (HAT) / Dataswift originated as a UK Research Councils-funded academic project (2013), launched as HAT Foundation Feb 2016, raised a £1.8M seed (Sept 2019, IQ Capital-led), and cycled through rebrands (Dataswift → Dataswyft) and pivots toward a "self-sovereign data wallet"/"AI memory" framing; its `@dataswift/hat-js` npm package showed no releases in 12+ months at the search date, indicating it never reached meaningful third-party developer traction despite 10+ years of runway. [dataswift-site] [snyk-hatjs]
- SMART on FHIR succeeded because the 21st Century Cures Act (2016) directed a "universal API" for patient data access and ONC's 2020 Interoperability Final Rule *named SMART* as that API and made SMART support a certification requirement for Health IT Modules (May 2020); by 2022 over two-thirds of US hospitals reported FHIR-API patient access, and Epic/Cerner-Oracle/Allscripts ship SMART as a compliance necessity. [smart-fhir-descope]
- UK Open Banking succeeded because the CMA's 2016 market investigation legally mandated the nine largest banks (CMA9, >90% of accounts) to build common APIs (a voluntary approach was rejected because the firms "had both the ability and incentive to frustrate it"), created Open Banking Ltd to run pass/fail conformance monitoring with published certificates and escalation to CMA Directions, and reached near-100% CMA9 conformance, 11.3M+ monthly active users, and a >£4B ecosystem by mid-2024, emulated in ~60 jurisdictions. [openbanking-roadmap]

## SOURCES

**kantara-uma1**
URL: https://kantarainitiative.org/uma-v1-0-call-to-implement/
Accessed: 2026-06-24

**uma2-grant**
URL: https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-grant-2.0.html
Accessed: 2026-06-24

**wso2-uma**
URL: https://wso2.com/library/article/2018/12/a-quick-guide-to-user-managed-access-2-0/
Accessed: 2026-06-24

**forgerock-uma**
URL: https://www.forgerock.com/about-us/press-releases/forgerock-joins-key-industry-and-government-leaders-in-launching-new-kantara-initiative-work-group-to-foster-global-adoption-of-the-user-managed-access-uma-standard
Accessed: 2026-06-24

**hie-of-one**
URL: https://en.wikipedia.org/wiki/HIE_of_One ; https://healthblawg.com/2018/08/gropper-hie-one.html
Accessed: 2026-06-24
Quote: "HIE of One facts cited via search-engine snippets quoting Wikipedia, not a live Wikipedia fetch (domain-blocked at research time) — one hop less verified."

**uma-core**
URL: https://docs.kantarainitiative.org/uma/rec-uma-core.html
Accessed: 2026-06-24
Quote: "any such partitioning by the resource server or owner is outside the scope of this specification"

**arxiv-uma**
URL: https://arxiv.org/pdf/2411.05622
Accessed: 2026-06-24

**richer-uma2**
URL: https://justinsecurity.medium.com/uma-2-0-437c293c3283
Accessed: 2026-06-24

**inrupt-techcrunch**
URL: https://techcrunch.com/2021/12/09/tim-berners-lee-inrupt-fundraise/
Accessed: 2026-06-24

**inrupt-axios**
URL: https://www.axios.com/2021/12/10/inrupt-internet-data-control-tim-berners-lee
Accessed: 2026-06-24

**odi-solid**
URL: https://theodi.org/news-and-events/blog/solids-next-chapter-returning-the-web-to-its-people-first-roots/
Accessed: 2026-06-24

**latka-inrupt**
URL: https://getlatka.com/companies/inrupt.com
Accessed: 2026-06-24
Quote: "Low-confidence aggregator data (self-reported, uneven reliability) — treat ARR/valuation as directional only."

**odi-symposium**
URL: https://theodi.org/news-and-events/news/announcing-the-solid-symposium-2026/
Accessed: 2026-06-24

**solid-forum-adoption**
URL: https://forum.solidproject.org/t/how-could-solid-be-one-day-broadly-adopted/4853
Accessed: 2026-06-24
Quote: "Why would any of the big internet companies (GAFAM and others) start adopting Solid, since the vast majority of them have a business model based on user data?"

**verborgh-pods**
URL: https://ruben.verborgh.org/blog/2022/12/30/lets-talk-about-pods/
Accessed: 2026-06-24
Quote: "the Solid Protocol is not a Web API — rather, it allows and requires each individual app to decide where and how they store Linked Data"

**dodds-solid**
URL: https://blog.ldodds.com/2024/03/12/baffled-by-solid/
Accessed: 2026-06-24

**demartin-solid**
URL: https://noeldemartin.com/blog/why-solid
Accessed: 2026-06-24
Quote: "the single most important issue holding Solid back"

**newstack-solid**
URL: https://thenewstack.io/the-developer-case-for-using-tim-berners-lees-solid/
Accessed: 2026-06-24

**chrissaad**
URL: https://www.chrissaad.com/workblog/2008/12/an-update-on-the-data-portability-landscape
Accessed: 2026-06-24

**adweek-dataportability**
URL: https://www.adweek.com/digital/facebook-and-data-portability-qa-with-dataportabilityorg-chairperson-chris-saad/
Accessed: 2026-06-24

**oreilly-locker**
URL: http://radar.oreilly.com/2011/02/singly-locker-project-telehash.html
Accessed: 2026-06-24

**forbes-locker**
URL: https://www.forbes.com/sites/smcnally/2011/10/19/jeremie-miller-and-the-locker-project-at-1-0/
Accessed: 2026-06-24

**allthingsd-singly**
URL: https://allthingsd.com/20130822/appcelerator-buys-api-connector-singly/
Accessed: 2026-06-24

**mydex-paper**
URL: https://mydex.org/resources/papers/AchievingTransformationAtScale/AchievingTransformationatScaleMydexCIC-2021-04-14.pdf
Accessed: 2026-06-24

**mydex-companies-house**
URL: https://find-and-update.company-information.service.gov.uk/company/SC319767
Accessed: 2026-06-24

**dataswift-site**
URL: https://dataswift.webflow.io/about/about-dataswift
Accessed: 2026-06-24

**snyk-hatjs**
URL: https://snyk.io/advisor/npm-package/@dataswift/hat-js
Accessed: 2026-06-24

**smart-fhir-descope**
URL: https://www.descope.com/learn/post/smart-on-fhir
Accessed: 2026-06-24

**openbanking-roadmap**
URL: https://www.openbanking.org.uk/news/cma-confirms-full-completion-of-open-banking-roadmap-unlocking-a-new-era-of-financial-innovation/
Accessed: 2026-06-24

## SYNTHESIS

The personal-data-protocol graveyard shares a small set of failure modes: (1) no supply-side forcing function — all were voluntary standards/consortia with no regulator compelling the incumbents holding the data; (2) no durable demand-side actor — DataPortability.org, Locker/Singly, and HAT all failed for want of a consumer that wanted the data once collected; (3) for UMA specifically, no data model or query interface (scoped out by design), so there was nothing for a demand-side ecosystem to build against beyond the auth dance; and (4) required platform cooperation — Solid most acutely, since it needs the platform to expose a Pod or the user to fully migrate, in direct conflict with ad-supported business models. The two success cases (SMART on FHIR, UK Open Banking) share the opposite shape: a regulator with enforcement power over the specific incumbents, a legal mandate (not a voluntary standard), an explicit conformance/certification regime with a pass/fail tool and public certificates, and real consequences for non-conformance. UMA is worth separating from the pack: its scope discipline (authorization-only) was a defensible design choice, and its own maintainers' later simplifications show a healthy spec-evolution process — the record-model/query gap it left is exactly the layer a data-portability standard would need to pair with an OAuth-family authorization core (analogous to how SMART on FHIR pairs OAuth with the FHIR data model). The load-bearing lesson: a well-documented single-implementation spec is historically indistinguishable from a well-documented single product; multi-vendor adoption of a personal-data standard has, in every observed case, required either a regulatory mandate + conformance regime or a pre-existing industry consortium that converged the standard before any regulator named it.