---
title: "Well-regarded protocol explainers use analogy only as reinforcement after a plain definition, never as a substitute, and RFC 6749's parenthetical role gloss is the only device that serves non-experts and implementers in the same words"
date: 2026-08-04
topic: standards-body-sites
tags: [technical-writing, protocol-explainers, analogy, mixed-audience, rfc, w3c]
status: draft
sources: [rfc6749, mcp-intro, solid-about, rfc9110, did-core, rfc7322, whatwg-html, x402, stripe-docs]
source_session: 3b96351e-94ac-42b8-b12a-e4c8684dabf6
---

## CLAIMS

- Of eight studied protocol/spec openings, only ONE (MCP) uses an analogy, and it lands in the third sentence AFTER a plain definition has already been given. RFC 9110, RFC 6749, DID Core, Matrix and Stripe use no analogy at all. [mcp-intro][rfc9110][rfc6749][did-core]
- The strongest dual-audience sentence-level device found is RFC 6749's PARENTHETICAL ROLE GLOSS: define roles abstractly, then re-instantiate every role in one concrete sentence with the formal term in parentheses. A non-expert reads a sentence about photos; an implementer harvests four role names from identical words. [rfc6749]
- The RFC 6749 printing-service passage is NOT a cold open, contrary to how it is usually cited. It lands fourth, after the abstract problem statement, a five-bullet harms list, and the access-token mechanism. It functions as a decoder ring for terms already defined, and copying it as an opener loses the mechanism that makes it work. [rfc6749]
- Solid's rucksack analogy breaks on custody and on copying: a hosted Pod is not carried by the user, and an app that reads a resource receives a retainable copy, so "the rest stays private" is true while what was opened cannot be un-opened. [solid-about]
- Solid's "file system for the Web" analogy largely survives scrutiny because it is near-literal (LDP-style resource storage over HTTP), and it is the only place on the site naming products a reader recognizes (Adobe Acrobat, Chrome). [solid-about]
- MCP's USB-C analogy survives ten seconds and breaks under load: USB-C implies "if it fits, it works", whereas an MCP payload is natural-language tool descriptions a model may misread, and USB-C carries no trust boundary equivalent to an untrusted MCP server. [mcp-intro]
- IETF and W3C disagree verbatim on the abstract's audience. RFC 7322 s4.3 requires an overview "to give a technically knowledgeable reader" the function of the document; the W3C Manual of Style says "write it for a non-technical audience". Both design the abstract as detachable because it is republished out of context. [rfc7322][whatwg-html]
- There is NO named convention for "a spec landing page that serves a non-expert in the first screen". The convention that exists is the non-normative introduction, marked with the literal line "This section is non-normative", which licenses ordinary prose inside a normative document. [whatwg-html]
- The anti-marketing device for mixed audiences is an explicit Audience section that names the tradeoff and REDIRECTS unsuited readers, rather than pandering to them. [whatwg-html]
- The enumerated-harms list is the strongest shared move across RFC 6749 (five bullets), DID Core (six clauses) and x402 (five annotated steps): each replaces a persuasive adjective with a countable list. [rfc6749][did-core][x402]
- Words-to-first-recognizable-concrete-noun varies by two orders of magnitude and tracks document type, not quality: Stripe 3 ("payments"), x402 8, DID Core s1 13 ("telephone numbers"), MCP 26 ("files"), Solid About 26 ("mortgage applications"), RFC 9110 ~95 ("Web"), RFC 6749 ~250 ("photos"). [stripe-docs][x402][did-core][mcp-intro][solid-about][rfc9110][rfc6749]
- A structural constraint generalizes beyond any one protocol: every everyday object carries exactly ONE enforcement regime (doors/windows/sieves are enforced by physics; permission slips/prescriptions/protective orders by consequence). Any system mixing enforced and merely-declared terms is therefore mis-served by every available metaphor, because the metaphor necessarily flattens the two classes.

## SOURCES

**rfc6749**
URL: https://www.rfc-editor.org/rfc/rfc6749.html
Accessed: 2026-08-04
Quote: "For example, an end-user (resource owner) can grant a printing service (client) access to her protected photos stored at a photo-sharing service (resource server), without sharing her username and password with the printing service. Instead, she authenticates directly with a server trusted by the photo-sharing service (authorization server), which issues the printing service delegation-specific credentials (access token)."

**mcp-intro**
URL: https://modelcontextprotocol.io/docs/getting-started/intro
Accessed: 2026-08-04
Quote: "Think of MCP like a USB-C port for AI applications. Just as USB-C provides a standardized way to connect electronic devices, MCP provides a standardized way to connect AI applications to external systems."

**solid-about**
URL: https://solidproject.org/about
Accessed: 2026-08-04
Quote: "It's a bit like carrying all your data in a rucksack (backpack) with lots of pockets. To access the data, different apps can only open the pocket you allow them to open, rather than taking the whole rucksack. The rest stays private."

**rfc9110**
URL: https://www.rfc-editor.org/rfc/rfc9110.html
Accessed: 2026-08-04
Quote: "The Hypertext Transfer Protocol (HTTP) is a stateless application-level protocol for distributed, collaborative, hypertext information systems."

**did-core**
URL: https://www.w3.org/TR/did-1.0/
Accessed: 2026-08-04
Quote: "As individuals and organizations, many of us use globally unique identifiers in a wide variety of contexts. They serve as communications addresses (telephone numbers, email addresses, usernames on social media), ID numbers (for passports, drivers licenses, tax IDs, health insurance), and product identifiers (serial numbers, barcodes, RFIDs)."

**rfc7322**
URL: https://www.rfc-editor.org/rfc/rfc7322.txt
Accessed: 2026-08-04
Quote: "Every RFC must have an Abstract that provides a concise and comprehensive overview of the purpose and contents of the entire document, to give a technically knowledgeable reader a general overview of the function of the document."

**whatwg-html**
URL: https://html.spec.whatwg.org/multipage/introduction.html
Accessed: 2026-08-04
Quote: "This document is probably not suited to readers who do not already have at least a passing familiarity with web technologies, as in places it sacrifices clarity for precision, and brevity for completeness. More approachable tutorials and authoring guides can provide a gentler introduction to the topic."

**x402**
URL: https://www.x402.org/
Accessed: 2026-08-04
Quote: "It absolves the Internet's original sin by natively making payments possible between clients and servers, creating win-win economies that empower agentic payments at scale."

**stripe-docs**
URL: https://docs.stripe.com/payments
Accessed: 2026-08-04
Quote: "Use Stripe to start accepting payments."

## SYNTHESIS

The reusable rule is ordering, not vocabulary: **definition first, analogy only as reinforcement, and never analogy as substitute for definition.** Seven of eight sources skip analogy entirely and lose nothing. When reaching for a metaphor to explain a protocol, the default should be to try dropping it and check whether plain language plus a concrete situation suffices; it usually does.

The most valuable transferable device is the parenthetical role gloss, because it is the only pattern found that serves both audiences in the SAME words rather than in sequence or in separate documents. Its power comes from position (after the roles are defined, as a decoder ring), so it should not be lifted to the top of a page.

The analogy-flattening constraint is the finding most likely to recur. Any protocol that distinguishes machine-enforced terms from merely-declared policy commitments (OAuth scope compliance, PDPP retention/purpose, most consent systems) cannot be honestly described by a physical metaphor, because our stock of access metaphors comes from places and objects that have a single, uniform enforcement mode. When a spec normatively forbids flattening those categories, a flattening metaphor is a non-conformant rendering of the system, not merely an imprecise one. In that situation a concrete SITUATION with real nouns beats any metaphor: it shows asymmetric enforcement by putting the enforced and the declared in adjacent sentences, and it has nothing to over-extend.

Practical caution for future work: the failure modes of a mission-y explainer are two distinct things worth separating. Vagueness (saying nothing checkable) is recoverable; overclaiming (saying something checkable that is false, e.g. "Solid ensures people maintain control" over behavior it cannot constrain) is more dangerous precisely because it reads as concrete.
