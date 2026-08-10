---
title: "Third-party integration directories (Home Assistant, n8n, simple-icons) vendor small flat SVGs of others' brand logos under a 'nominative fair use, identification only, no endorsement' legal posture, and treat a deterministic monogram+color as the correct default/fallback state rather than an edge case"
date: 2026-08-07
topic: connectors
tags: [icons, branding, trademark, licensing, integration-directory, fallback-ui]
status: draft
sources: [ha-brands, simple-icons-disclaimer, ha-tos, apache-2.0, n8n-node-icons, nominative-fair-use, monogram-fallback]
source_session: 627ae800-2569-4a3c-ab6b-c270004d0e47
---

## CLAIMS

- home-assistant/brands is a single centralized repo (not per-integration, not fetched live from the brand's own site) holding small flat SVG/PNG logos, organized as `core_integrations/<domain>/` and `custom_integrations/<domain>/`, served via a static CDN (brands.home-assistant.io) that Home Assistant clients hit at runtime rather than bundling the images into the app itself. [ha-brands]
- Home Assistant's icon-serving CDN returns a 404 for a missing/unrequested integration icon on the plain (non-`/_/`-prefixed) URL path; there is a separate fallback-image-serving URL variant. Absence of an icon is therefore a normal, expected, unstyled-by-default state at the infra layer, with client-side styling responsible for making that state look intentional. [ha-brands]
- As of HA 2026.3.0, custom integrations can ship their OWN brand icon bundled with the integration; the backend checks for a bundled asset FIRST and only falls back to proxying the centralized Brands CDN if none is found — this was a deliberate de-bottlenecking move away from requiring every icon to go through the central repo's PR/approval process. [ha-brands]
- home-assistant/brands explicitly disclaims trademark ownership in its README: "All product names, trademarks, and registered trademarks in the images ... are property of their respective owners... used ... strictly for identification purposes only." [ha-brands]
- Home Assistant's own Terms of Service state the site grants no license to reproduce or use Home Assistant's or any third party's trademarks, and separately notes third-party trademarks used on the site "may belong to third parties." [ha-tos]
- Home Assistant's codebase is Apache 2.0, which explicitly does NOT grant trademark/trade-name usage rights beyond what's needed to reasonably/customarily describe the origin of the work, and disclaims all warranties including non-infringement — risk is explicitly pushed to the redistributor. [apache-2.0]
- simple-icons distributes ~3,000+ brand SVGs as an npm package / CDN (jsDelivr, unpkg), with the underlying SVG markup released CC0, but its own LICENSE.md states the CC0 waiver does NOT extend to trademarks: "No trademark or patent rights held by Affirmer are waived, abandoned, surrendered, licensed or otherwise affected by this document." [simple-icons-disclaimer]
- simple-icons maintains a standalone DISCLAIMER.md, links a per-icon license/brand-guidelines field in its data file, states it "cannot be held responsible for any legal activity raised by a brand," and provides a formal brand-owner removal-request channel (email) — evidence that brand-owner takedown requests are a known, planned-for occurrence, not hypothetical. [simple-icons-disclaimer]
- n8n does NOT centralize third-party node icons in one audited repo the way Home Assistant does. Its own docs instruct node authors to save the target service's own SVG logo directly into the node's folder (e.g., "save the SendGrid SVG logo from here as ...svg") — sourcing is decentralized, per-integration-author, and undocumented as to licensing review. [n8n-node-icons]
- Nominative fair use (US, Ninth Circuit-originated, adopted more broadly) permits referencing another's trademark/logo without a license when: (1) the product/service can't be readily identified without it, (2) only as much of the mark is used as necessary for identification, and (3) nothing implies sponsorship or endorsement by the mark holder. Courts scrutinize actual LOGO use (vs. word-mark-only use) more closely than plain-text references, and a stylized logo can separately raise copyright (not just trademark) issues distinct from the trademark question. [nominative-fair-use]
- A documented real-world analog accepted as nominative fair use: a service provider displaying multiple insurers' logos on its own site to indicate "we work with this insurer" — structurally identical to a self-hosted data-portability tool showing "we support login to this third-party service." [nominative-fair-use]
- Deterministic monogram-plus-generated-color (1-2 initial letters, color derived from a stable seed/name, not random-per-render) is the converged fallback pattern across GitHub, Slack, Google Workspace, DiceBear's "initials" style, ui-avatars.com, shadcn/ui's Avatar component, and Uber's Base design system — every one of these systems treats "no image available" as a first-class default rendering path, not an error state, and none leave a blank/empty avatar. [monogram-fallback]

## SOURCES

**ha-brands**
URL: https://github.com/home-assistant/brands
Accessed: 2026-08-07
Quote: "All product names, trademarks and registered trademarks in the images in this repository, are property of their respective owners. All images in this repository are used by the Home Assistant project to identify the products and companies who created them and are for identification purposes only."

**simple-icons-disclaimer**
URL: https://github.com/simple-icons/simple-icons/blob/master/DISCLAIMER.md ; https://app.unpkg.com/simple-icons@15.21.0/files/LICENSE.md
Accessed: 2026-08-07
Quote: "No trademark or patent rights held by Affirmer are waived, abandoned, surrendered, licensed or otherwise affected by this document."

**ha-tos**
URL: https://www.home-assistant.io/tos/
Accessed: 2026-08-07
Quote: "use of the Website grants no right or license to reproduce or otherwise use any Home Assistant or third-party trademarks."

**apache-2.0**
URL: https://www.home-assistant.io/developers/license/
Accessed: 2026-08-07
Quote: "does not grant permission to use the trade names, trademarks, service marks, or product names of the Licensor, except as required for reasonable and customary use in describing the origin of the Work"

**n8n-node-icons**
URL: https://docs.n8n.io/integrations/creating-nodes/build/programmatic-style-node/
Accessed: 2026-08-07
Quote: "Save the SendGrid SVG logo from here as friendGrid.svg in nodes/FriendGrid/"

**nominative-fair-use**
URL: https://en.wikipedia.org/wiki/Nominative_use ; https://www.inta.org/fact-sheets/fair-use-of-trademarks-intended-for-a-non-legal-audience/
Accessed: 2026-08-07
Quote: "the product or service in question is not readily identifiable without use of the trademark; ... only so much of the mark as is reasonably necessary to identify the product or service; ... the user must do nothing that would suggest sponsorship or endorsement by the trademark holder."

**monogram-fallback**
URL: https://www.dicebear.com/styles/initials/ ; https://www.shadcn.io/patterns/avatar-standard-2 ; https://hey.georgie.nu/avatar-initials/
Accessed: 2026-08-07
Quote: "Initials is a text-based vector avatar style that renders one or two large letters centered on a solid colored square"

## SYNTHESIS

For a self-hosted, source-available product like PDPP, the strongest-precedent design is NOT "vendor nothing" and NOT "vendor everything eagerly" — it's Home Assistant's exact shape: (1) an OPTIONAL, per-integration-declared icon slot that defaults to absent, (2) a deterministic monogram+color fallback that is a first-class good-looking state (not a degraded one), and (3) icons that ARE vendored are small flat SVGs used strictly for identification, with a clear "trademarks belong to their respective owners, used for identification only" disclaimer — mirroring both HA's brands README and simple-icons' DISCLAIMER.md almost verbatim. Nominative fair use is real legal cover for this specific use case (self-hosted tool identifying which third-party services it can connect to, not implying endorsement), but it is a fact-specific affirmative defense, not blanket immunity — logos (vs. word marks) get more judicial scrutiny, and simple-icons' existence of a formal brand-owner-removal-request channel shows takedown requests are a planned-for operational reality, not a hypothetical. The practical takeaway for PDPP: only hand-vendor a handful of icons (from a CC0/public-domain-declared source like simple-icons, not scraped from brand press kits), keep the manifest field optional so the other 37+ connectors gracefully render via monogram, and write the same "identification purposes only, no endorsement, trademarks are their owners'" disclaimer into the icon component or docs.
