---
title: "Machine-readable usage policies enforce behavior only inside controlled processing boundaries"
date: 2026-09-03
topic: usage-control
tags: [odrl, xacml, idsa, gaia-x, catena-x, drm]
status: draft
sources: [odrl, xacml, idsa, dssc, catena-x, sticky, drm]
source_session: unknown
---

## CLAIMS

- ODRL defines policy representation and evaluation; a profile-aware processor that does not recognize the referenced profile must stop processing. It does not create an enforcement runtime. [odrl]
- XACML separates the policy administration, decision, information, and enforcement points; correct handling of obligations can require a bilateral agreement between the policy administrator and enforcement point. [xacml]
- IDSA similarly places evaluation in a PDP and interception in a PEP. Its usage-control documentation distinguishes preventive interception from detective monitoring. [idsa]
- The EU Data Spaces Support Centre states that ODRL defines vocabulary, not how policies are interpreted or enforced. Current Catena-X guidance says usage policies are not technically enforced and depend on applications plus legal framework agreements. [dssc] [catena-x]
- IDSA-related sticky-policy research states that the enforcement mechanism must itself be trusted. The W3C DRM workshop separated language, semantics, trust, and hardware/software enforcement and found no end-to-end interoperable solution in the systems surveyed. [sticky] [drm]

## SOURCES

**odrl**
URL: https://www.w3.org/TR/2018/REC-odrl-model-20180215/
Accessed: 2026-09-03
Quote: "it MUST stop processing the policy"

**xacml**
URL: https://docs.oasis-open.org/xacml/3.0/xacml-3.0-core-spec-os-en.html
Accessed: 2026-09-03
Quote: "bilateral agreement between a PAP and the PEP"

**idsa**
URL: https://docs.internationaldataspaces.org/ids-knowledgebase/ids-ram-4/layers-of-the-reference-architecture-model/3-layers-of-the-reference-architecture-model/3_4_process_layer/3_4_6_policy_enforcement
Accessed: 2026-09-03

**dssc**
URL: https://blueprint.dssc.eu/?business=regulatory-compliance&pane=business&service=business-and-org-tools
Accessed: 2026-09-03
Quote: "ODRL defines policy vocabulary, not how to interpret or enforce policies."

**catena-x**
URL: https://eclipse-tractusx.github.io/docs-kits/kits/supply-chain-disruption-notification-kit/software-development-view/policies/
Accessed: 2026-09-03
Quote: "Currently, the usage policies aren't technically enforced but based on a legal framework agreements."

**sticky**
URL: https://link.springer.com/chapter/10.1007/978-3-030-93975-5_8
Accessed: 2026-09-03
Quote: "the enforcement mechanism itself is trusted"

**drm**
URL: https://www.w3.org/2000/12/drm-ws/workshop-report.html
Accessed: 2026-09-03

## SYNTHESIS

Policy expression, mutual acceptance, and enforcement are separate layers. A reference monitor can enforce access and a controlled runtime can enforce bounded operations. Once plaintext exits that boundary, a policy becomes a contractual, audit, or regulatory claim unless every relevant processor is instrumented and trusted. A protocol must label this boundary honestly; attaching ODRL or another “sticky” document cannot extend the reference monitor by declaration.
