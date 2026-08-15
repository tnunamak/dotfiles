---
title: "Protocol and standards sites cap page content well above 1080px (median 1312 at a 1920 viewport, a third uncapped) and keep heading-plus-sentence lists in a single column even with room for two, reserving multi-column grids for link cards"
date: 2026-08-14
topic: standards-body-sites
tags: [layout, docs-sites, measure, responsive, pdpp-site, information-design]
status: verified
sources: [w3c-standards, w3c-get-involved, ietf-process, ietf-participate, mcp-spec, mcp-contribute, mcp-intro, matrix-spec, matrix-contribute, openapi, openapi-community, oauth-net, activitypub, opentelemetry-community, otel-docs, cncf-community, k8s-contribute, k8s-docs, rust-governance, nodejs-about, deno-manual, astro-docs, sqlite, letsencrypt-docs, tailscale-community, proton-community, cloudflare-docs, cloudflare-plans, stripe-docs, stripe-pricing, betterstack-docs, betterstack-uptime, mdn-grid, github-docs-workflow]
source_session: b74defed-7075-46ee-9496-cdf4b082dd4d
---

<!--
Measured live with Playwright at a 1920x1000 viewport on 2026-08-14, not read
from CSS or documentation. "Shell" = widest bounded content container (an
element whose computed max-width is neither `none` nor `100%`); pages with no
such element are recorded as uncapped/full-viewport. "Prose" = width of the
first <p> carrying >90 characters. Grid detection = computed
`display: grid` with >=2 non-zero columns, >=380px wide, >=70px tall, >=2
visible children; "link card" = >=80% of direct children are or contain <a>.
-->

## CLAIMS

### Container width

- 16 of 24 surveyed pages bound their content in a container with an explicit
  max-width; the remaining 8 run the full 1920 viewport. Among the 16 that cap,
  the median shell is 1312px, the minimum 864px and the maximum 1904px.
  [survey-2026-08-14]
- Only 2 of those 16 capped pages cap at or below 1080px: OAuth.net (960) and
  Deno's manual (864). [oauth-net] [deno-manual]
- Measured shells at 1920: W3C 1312 [w3c-standards] [w3c-get-involved], IETF
  1300 [ietf-process] [ietf-participate], ActivityPub 1288 [activitypub],
  Matrix spec full-viewport [matrix-spec], OpenAPI 1425 [openapi]
  [openapi-community], MCP 1472 [mcp-spec] [mcp-contribute], CNCF 1200
  [cncf-community], Kubernetes full-viewport [k8s-contribute] [k8s-docs], Rust
  1152 [rust-governance], Astro 1152 [astro-docs], Let's Encrypt 1280
  [letsencrypt-docs], Tailscale 1440 [tailscale-community], Proton 1776
  [proton-community], OpenTelemetry full-viewport [opentelemetry-community]
  [otel-docs], SQLite 1904 [sqlite], Node.js full-viewport [nodejs-about].
- Prose measure is bounded independently of the shell and is typically far
  narrower: W3C 504, OpenAPI 610/504, Astro 482, Let's Encrypt 576, IETF 800,
  ActivityPub 800, Proton 810, Node.js 880, OAuth.net 936, Kubernetes
  contribute 963, Matrix spec 976, OpenTelemetry 976. A wide shell therefore
  does not imply a wide reading measure. [survey-2026-08-14]
- Documentation surfaces pin their nav rail to the viewport edge while the same
  site's marketing pages sit in a centred container: Cloudflare's docs header
  logo sits at x=24 against x=224 on its plans page [cloudflare-docs]
  [cloudflare-plans]; Stripe's marketing logo sits at x=432 [stripe-pricing].
  The masthead moving between the two surfaces is normal for this class, not a
  defect. [cloudflare-docs] [cloudflare-plans]

### Multi-column grids vs. single-column stacks

- 24 multi-column blocks were found across the 24 pages. 17 of them are link
  cards (>=80% of items are links); 6 are prose grids (mostly non-link, >=8
  words per item). [survey-2026-08-14]
- Every multi-column block on MCP's pages is entirely links: 3 of 3 items on
  the introduction page, 1 of 1 on a second block there, and 10 of 10 SDK
  entries on the contributing page. [mcp-intro] [mcp-contribute]
- Prose grids do exist and are not rare enough to call anomalous: Kubernetes
  docs home (3 columns, 9 items, 23 words/item), Deno manual (3 columns, 3
  items, 23 words/item), Let's Encrypt docs (2 columns, 2 items, 51 words/item;
  and a second 2-column block with 2 items, 13 words/item and **zero** links),
  Proton community (2 columns, 50 and 334 words/item). [k8s-docs] [deno-manual]
  [letsencrypt-docs] [proton-community]
- The sites with zero multi-column grids are not merely lacking the content —
  they have comparable repeated heading-plus-sentence units and render them as
  a single column in blocks wide enough for two: IETF participate (4 items, 17
  words/item, 1300px block) [ietf-participate], Kubernetes contribute (7 items,
  28 words/item, 1204px block; and 3 items, 16 words/item, 944px)
  [k8s-contribute], W3C get involved (5 items, 25 words/item, 711px; and 3
  items, 8 words/item, 619px) [w3c-get-involved], OpenTelemetry community (19
  items, 18 words/item, 1220px; plus two more at 976px) [opentelemetry-community],
  Rust governance (3 items, 8 words/item, 1152px) [rust-governance].
- OpenTelemetry keeps a 19-item list whose items are 15/19 links in a single
  column at 1220px — link-ness alone does not force a grid. [opentelemetry-community]

### Table width relative to prose

- Docs sites do not give tables a large outset from the prose measure. Stripe
  renders a table at 797px against 799px of prose (flush); GitHub at 720
  against 720 (flush); MDN outsets by 77px (768 against 691). [stripe-docs]
  [github-docs-workflow] [mdn-grid]

## SOURCES

**survey-2026-08-14**
Method: Playwright, chromium, viewport 1920x1000, `waitUntil: domcontentloaded`
plus a 3s settle. Aggregate figures computed across all pages listed below.
Accessed: 2026-08-14

**w3c-standards**
URL: https://www.w3.org/standards/
Accessed: 2026-08-14

**w3c-get-involved**
URL: https://www.w3.org/get-involved/
Accessed: 2026-08-14

**ietf-process**
URL: https://www.ietf.org/process/
Accessed: 2026-08-14

**ietf-participate**
URL: https://www.ietf.org/participate/
Accessed: 2026-08-14

**mcp-spec**
URL: https://modelcontextprotocol.io/specification/2025-06-18
Accessed: 2026-08-14

**mcp-contribute**
URL: https://modelcontextprotocol.io/development/contributing
Accessed: 2026-08-14

**mcp-intro**
URL: https://modelcontextprotocol.io/introduction
Accessed: 2026-08-14

**matrix-spec**
URL: https://spec.matrix.org/latest/
Accessed: 2026-08-14

**matrix-contribute**
URL: https://matrix.org/docs/development/
Accessed: 2026-08-14

**openapi**
URL: https://www.openapis.org/
Accessed: 2026-08-14

**openapi-community**
URL: https://www.openapis.org/community
Accessed: 2026-08-14

**oauth-net**
URL: https://oauth.net/2/
Accessed: 2026-08-14

**activitypub**
URL: https://www.w3.org/TR/activitypub/
Accessed: 2026-08-14

**opentelemetry-community**
URL: https://opentelemetry.io/community/
Accessed: 2026-08-14

**otel-docs**
URL: https://opentelemetry.io/docs/
Accessed: 2026-08-14

**cncf-community**
URL: https://www.cncf.io/community/
Accessed: 2026-08-14

**k8s-contribute**
URL: https://kubernetes.io/docs/contribute/
Accessed: 2026-08-14

**k8s-docs**
URL: https://kubernetes.io/docs/home/
Accessed: 2026-08-14

**rust-governance**
URL: https://www.rust-lang.org/governance
Accessed: 2026-08-14

**nodejs-about**
URL: https://nodejs.org/en/about
Accessed: 2026-08-14

**deno-manual**
URL: https://docs.deno.com/runtime/
Accessed: 2026-08-14

**astro-docs**
URL: https://docs.astro.build/en/getting-started/
Accessed: 2026-08-14

**sqlite**
URL: https://sqlite.org/index.html
Accessed: 2026-08-14

**letsencrypt-docs**
URL: https://letsencrypt.org/docs/
Accessed: 2026-08-14

**tailscale-community**
URL: https://tailscale.com/community
Accessed: 2026-08-14

**proton-community**
URL: https://proton.me/community
Accessed: 2026-08-14

**cloudflare-docs**
URL: https://developers.cloudflare.com/workers/get-started/guide/
Accessed: 2026-08-14

**cloudflare-plans**
URL: https://www.cloudflare.com/plans/
Accessed: 2026-08-14

**stripe-docs**
URL: https://docs.stripe.com/currencies
Accessed: 2026-08-14

**stripe-pricing**
URL: https://stripe.com/pricing
Accessed: 2026-08-14

**betterstack-docs**
URL: https://betterstack.com/docs/uptime/start/
Accessed: 2026-08-14

**betterstack-uptime**
URL: https://betterstack.com/uptime
Accessed: 2026-08-14

**mdn-grid**
URL: https://developer.mozilla.org/en-US/docs/Web/CSS/grid-template-columns
Accessed: 2026-08-14

**github-docs-workflow**
URL: https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions
Accessed: 2026-08-14

## SYNTHESIS

Two separable decisions get conflated as "how wide should the page be," and the
survey answers them differently.

**Shell width** is close to unanimous: 1080px is at the bottom of the
distribution, and a third of the class doesn't cap at all. Widening the shell
costs nothing legibility-wise because prose carries its own much narrower
measure (482-976px here) — the extra shell width becomes margin and figure
room, not line length. A site whose docs surface is full-bleed while its
marketing pages cap tightly will visibly shift the whole page, masthead
included, when a reader clicks between them.

**Column count for prose lists** is not unanimous, and an earlier version of
this research overstated it. The honest reading is that both forms are
attested, but they cluster: multi-column blocks in this class are predominantly
link cards (17 of 24), prose grids appear mainly in product docs and docs hubs
(Deno, Proton, Kubernetes docs home, Let's Encrypt), and the standards and
governance bodies specifically — W3C, IETF, OpenTelemetry, Rust, Kubernetes'
own contribute page — keep comparable lists stacked even when the block is wide
enough for two columns. The discriminator that survives scrutiny is not
"grids are only for links" (Let's Encrypt has a zero-link prose grid) but
"among standards/governance pages, the stack is the convention, and the
strongest evidence is that these sites have the content and the room and still
choose one column."

Method caution: absence of a grid is weak evidence on its own. It only became
informative after separately confirming that the zero-grid sites *have*
repeated heading-plus-sentence units in wide-enough blocks. Any future
re-run should keep that second pass — the first pass alone supports a much
more confident conclusion than the data actually licenses.
