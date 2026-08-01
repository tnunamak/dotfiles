---
title: "How leading orgs present one complex technical system to executives + engineers + non-technical stakeholders: the Martini Glass narrative structure, the C4 zoom levels, 2-level progressive disclosure, and layered docs — no one has done it from a single URL"
date: 2026-04-08
topic: knowledge-management
tags: [technical-communication, progressive-disclosure, c4-model, narrative-visualization, docs-as-product, design-systems]
status: draft
sources: [segel-heer, stripe-markdoc, cloudflare-ref-arch, apple-hig, linear-method, nng-progressive-disclosure, c4-model, tufte, owasp-threat-modeling, plaid-directed-graph, illustrated-tls, geist, primer, polaris, radix, shadcn, spectrum]
source_session: 019d2ace-04a3-7242-85e8-1f49ff7813e5
---

## CLAIMS

- No researched organization has built a single URL that serves simultaneously as an interactive reference implementation AND a CEO-level presentation artifact; the closest precedents each cover only part (Illustrated TLS 1.3 is educational not runnable; Plaid Link shares a data model across surfaces but the surfaces are separate; Stripe builds from shared Markdoc content but renders separate URLs). [illustrated-tls][plaid-directed-graph][stripe-markdoc]
- Segel & Heer (2010) identify three narrative structures for complex data visualization — author-driven (linear), reader-driven (exploratory), and the Martini Glass hybrid that starts with a guided narrative then opens into free exploration — the last mapping directly onto a mixed executive/engineer audience. [segel-heer]
- NN/g research finds progressive disclosure yields ~30-50% faster initial task completion while maintaining 70-90% feature discoverability, but designs beyond 2 disclosure levels typically have low usability because users get lost moving between levels. [nng-progressive-disclosure]
- Stripe treats documentation with the same rigor as the product: a layered artifact strategy (product pages / API reference / quickstarts / guides), personalization over segmentation (inject the user's real API keys into samples), and a three-column layout (nav / explanation / live code) that lets audiences self-select depth. [stripe-markdoc]
- Cloudflare builds three explicit tiers — Reference Architectures (strategic, for CTOs/architects), Design Guides (prescriptive, for practitioners), Implementation Guides (tactical, for engineers) — each with an explicit "intended audience" section. [cloudflare-ref-arch]
- Apple's HIG defaults to invisible simplicity (App Transport Security is just on) and unfolds explanation only when exceptions are needed, organized by progressive abstraction (Platforms > Foundations > Patterns > Components > Inputs > Technologies). [apple-hig]
- The Linear Method's principles include "simple first, then powerful," "don't invent terms," "short specs are more likely to be read," and "one really good way of doing things" (opinionated defaults over flexibility). [linear-method]
- Simon Brown's C4 model defines four zoom levels — System Context (executives/non-technical), Container (architects/tech leads), Component (developers), Code (implementers) — with the key rule to never mix levels in one diagram; each level is a complete self-contained view. [c4-model]
- Edward Tufte's layering-and-separation principle uses visual encoding (color, weight, position) to create independently-readable layers, and his small-multiples pattern repeats one visualization across categories so readers can compare without being overwhelmed. [tufte]
- OWASP DFD/STRIDE notation is the closest existing visual language for protocol/trust visualization: five symbol types (External Entity, Process, Data Store, Data Flow, Trust Boundary), trust boundaries as dashed zones, deliberately minimal so "anyone on the team can read." [owasp-threat-modeling]
- Plaid's protobuf-defined workflow directed graph runs production, powers the internal no-code editor, and drives live traffic visualization from one data model — there is no separate "diagram" layer. [plaid-directed-graph]
- Zero of the surveyed SLVP-tier design systems (Vercel Geist, shadcn/ui, Shopify Polaris, Adobe Spectrum, Radix, Material 3, Ant Design v5) document a dedicated marketing Hero component; they document primitives (typography, color, spacing, buttons, cards, layouts) while heroes live in a block/recipe ecosystem layer (e.g. shadcn.io has 64 hero variations); Ant Design removed `PageHeader` from core in v5, relocating it to a separate pro-components library. [geist][shadcn][polaris][spectrum][radix]
- Measured at 1440×900, leading docs/design-system sidebar outer rails cluster in a 256-300px band (median ~288px) with none below 256px; design-system sidebars are not made narrower than docs sidebars — short labels are handled by breathing the inner content column inward and using larger nav type (16px), not by shrinking the rail; the dominant responsive pattern is stepped fixed rail widths per breakpoint (content column and typography go fluid, the rail does not). [geist][primer][polaris][radix][shadcn][spectrum]

## SOURCES

**segel-heer**
URL: http://vis.stanford.edu/files/2010-Narrative-InfoVis.pdf
Accessed: 2026-04-08

**stripe-markdoc**
URL: https://stripe.dev/blog/markdoc
Accessed: 2026-04-08

**cloudflare-ref-arch**
URL: https://developers.cloudflare.com/reference-architecture/
Accessed: 2026-04-08

**apple-hig**
URL: https://developer.apple.com/design/human-interface-guidelines
Accessed: 2026-04-08

**linear-method**
URL: https://linear.app/method/introduction
Accessed: 2026-04-08

**nng-progressive-disclosure**
URL: https://www.nngroup.com/articles/progressive-disclosure/
Accessed: 2026-04-08

**c4-model**
URL: https://c4model.com/
Accessed: 2026-04-08

**tufte**
URL: https://www.edwardtufte.com/book/envisioning-information/
Accessed: 2026-04-08

**owasp-threat-modeling**
URL: https://owasp.org/www-community/Threat_Modeling_Process
Accessed: 2026-04-08

**plaid-directed-graph**
URL: https://plaid.com/blog/a-new-architecture-for-plaid-link-server-driven-ui-with-directed-graphs/
Accessed: 2026-04-08

**illustrated-tls**
URL: https://tls13.xargs.org/
Accessed: 2026-04-08

**geist**
URL: https://vercel.com/geist/introduction
Accessed: 2026-04-10

**primer**
URL: https://primer.style/product/primitives/color/
Accessed: 2026-04-10

**polaris**
URL: https://polaris.shopify.com/foundations
Accessed: 2026-04-10

**radix**
URL: https://www.radix-ui.com/primitives/docs/overview/introduction
Accessed: 2026-04-10

**shadcn**
URL: https://ui.shadcn.com/docs
Accessed: 2026-04-10

**spectrum**
URL: https://spectrum.adobe.com/page/color-system/
Accessed: 2026-04-10

## SYNTHESIS

To serve executives, engineers, and non-technical stakeholders from one artifact, the strongest composite is: a Martini Glass structure (a ~60-90s guided "stem" narrative that opens into a fully explorable "bowl"), stacked on C4's discipline of never mixing zoom levels in one view, capped at NN/g's 2-level progressive-disclosure limit for the primary view (deeper mechanics belong on a separate spec/design surface). The shared credibility argument across audiences is aliveness — a live running system beats slides for investors and beats a static spec for engineers — which is why Plaid's "the graph that runs the system is the graph that gets visualized" is the reusable move. Five interactive-protocol-reference paradigms exist (step-through simulation, byte-level forensic narrative à la Illustrated TLS, schema-driven exploration, visual system management, public "how it works" explainer); only the byte-level forensic narrative demonstrably serves multiple competency levels from one URL. On design-system packaging: document primitives in the core system and put marketing compositions (heroes) in a clearly-separated "sections" layer, matching the shadcn ecosystem split. On chrome: keep sidebar rails in the 256-300px mainstream band, step them at breakpoints, and prefer visual continuity across site chrome over optimizing empty space for short labels.
