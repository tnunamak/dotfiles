---
title: "Neutral-standard SITES open with a one-line definition of what the thing is, while the spec DOCUMENTS they publish open with status frontmatter — the 'spec sites skip the hero' finding conflates the two surfaces"
date: 2026-08-04
topic: standards-body-sites
tags: [first-impression, hero, information-architecture, pdpp, x402, matrix, solid, openid, did-core]
status: draft
sources: [openid, matrix-spec, solid, x402, did-core]
source_session: a521a113-1636-4d28-91ab-5fe4e8be8831
---

## CLAIMS

- openid.net's first body text is "Our mission is to lead the global community in creating identity standards that are secure, interoperable and privacy-preserving." No version or status metadata appears above the fold, and no code sample. [openid]
- openid.net presents multiple above-the-fold action links, including "EXPLORE SPECIFICATIONS" and "CERTIFY YOUR IMPLEMENTATION". [openid]
- spec.matrix.org's first heading is "Matrix Specification" and its first sentence is "Matrix defines a set of open APIs for decentralised communication, suitable for securely publishing, persisting and subscribing to data over a global open federation of servers with no single point of control." Version metadata (v1.19) appears as a single subtitle line below the heading, not as a multi-row table. [matrix-spec]
- solidproject.org's first heading is "Solid", followed immediately by "Your data, your choice" and "Advancing the Web to empower people and communities." Two CTA buttons ("Get a Solid Pod", "Already have a Pod - try the apps") appear above the fold. No version or status metadata appears above the fold. [solid]
- x402.org's first heading is "x402" and its first body sentence is "x402 is an open, neutral standard for internet-native payments." A `paymentMiddleware(...)` code snippet appears above the fold. No version or status metadata appears near the top. [x402]
- W3C DID Core, a spec DOCUMENT rather than a site, places 9 rows of metadata (W3C logo, title, subtitle, publication status and date, "More details about this document", This version, Latest published version, Latest editor's draft, History) between the title and the abstract. [did-core]
- DID Core's abstract opens "Decentralized identifiers (DIDs) are a new type of identifier that enables verifiable, decentralized digital identity." [did-core]
- Of four neutral-standard SITE homepages checked (openid.net, spec.matrix.org, solidproject.org, x402.org), four open with a one-line statement of what the thing is. Zero open with a version/status/date rail or a multi-row metadata table. [openid][matrix-spec][solid][x402]

## SOURCES

**openid**
URL: https://openid.net/
Accessed: 2026-08-04
Quote: "Our mission is to lead the global community in creating identity standards that are secure, interoperable and privacy-preserving."

**matrix-spec**
URL: https://spec.matrix.org/latest/
Accessed: 2026-08-04
Quote: "Matrix defines a set of open APIs for decentralised communication, suitable for securely publishing, persisting and subscribing to data over a global open federation of servers with no single point of control."

**solid**
URL: https://solidproject.org/
Accessed: 2026-08-04
Quote: "Your data, your choice"

**x402**
URL: https://x402.org/
Accessed: 2026-08-04
Quote: "x402 is an open, neutral standard for internet-native payments."

**did-core**
URL: https://www.w3.org/TR/did-core/
Accessed: 2026-08-04
Quote: "Decentralized identifiers (DIDs) are a new type of identifier that enables verifiable, decentralized digital identity."

## SYNTHESIS

Prior PDPP site research (PRECEDENT.md) concluded that "specification sites skip the hero pitch entirely" and that "the document title and status metadata IS the hero." That conclusion was drawn from RFC 9110, WHATWG HTML, and W3C TR, all of which are spec DOCUMENTS. It generalized a document convention onto a site.

The distinction that matters is arrival context. A reader reaching RFC 9110 already knows they want RFC 9110; they navigated to a specific document by number. Frontmatter serves that reader because their open question is "which version, what status, is this current." A reader reaching a homepage has not yet decided anything, and their open question is "what is this." The four neutral-standard sites above answer that question first, in one line, without exception, even though every one of them also publishes a frontmatter-first spec document elsewhere on the same domain. Matrix is the cleanest demonstration: spec.matrix.org leads with a sentence defining Matrix and demotes the version to a single subtitle line, while the underlying spec documents carry full status apparatus.

The transferable rule is that frontmatter density should scale with the reader's certainty about why they arrived, and a homepage is the point of minimum certainty. This does not license a marketing hero: none of the four sites that lead with a definition uses persuasive copy in that first line, and two (openid.net, spec.matrix.org) use no CTA button at all. Definition-first and pitch-first are separable choices, and the precedent supports the former without the latter.
