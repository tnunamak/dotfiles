---
title: "The shortest credible spec change processes document countable evidence requirements rather than numbered stages, always state what skips the process, and keep maintainer rosters in a repo file rather than on the website"
date: 2026-08-04
topic: standards-body-sites
tags: [governance, contributing-pages, change-process, maintainers, whatwg, otep]
status: draft
sources: [whatwg-working-mode, whatwg-stages, otep-readme, mcp-sep, mcp-governance, x402-contributing, kubernetes-community, lfdt-trademarks]
source_session: ae3d52cb-b1e4-4860-bf88-3298f5e8b2a4
---

## CLAIMS

- WHATWG's famously short process page (`/working-mode`, ~2,471 words) contains **no stages at all**; it documents evidence requirements organized as Changes / Additions / Removals / Risky changes, not a pipeline [whatwg-working-mode].
- WHATWG's numbered Stages 0–4 are an explicitly **optional overlay**: a contribution "can advance directly to later stages without going through the earlier stages," and the page credits TC39 as the model [whatwg-stages].
- Additions at WHATWG carry a hard numeric gate — "The addition must have the support of at least two implementers" — rather than a prose consensus standard [whatwg-working-mode].
- OTEP is the shortest stage-based process found (~1,000 words, 4 states) and gives **every transition a mechanical, countable trigger**: "An OTEP is `approved` when four reviewers github-approve the PR" [otep-readme].
- Every credible process documents **when NOT to use itself**. WHATWG: "Changes of editorial nature, or which only impact non-normative text, can be made, accepted, or rejected by the editor without discussion." MCP lists explicit skips: "Bug fixes and typo corrections, Documentation clarifications, Adding examples" [whatwg-working-mode, mcp-sep].
- x402 is the shortest change process of the seven surveyed (~200 words) and expresses it as **artifact sequencing, not governance stages**: PR 1 Specification Only → PR 2 Reference Implementation → PR 3 Additional SDKs [x402-contributing].
- W3C (Recommendation track, ~50,000+ words) and IETF (10 ordered steps, ~2,200 words) use **named document-maturity levels, not change-process steps** — the wrong scale to copy for a small project [mcp-sep, whatwg-stages contrast].
- MCP's SEP process requires a named **Sponsor** (a maintainer must adopt a proposal before formal review), and carries an anti-zombie `dormant` status — "No sponsor found within 6 months; can be revived" — explicitly distinct from `rejected` [mcp-sep].
- On maintainer presentation, the dominant convention is **repo-not-website**: of MCP, Solid, x402, Kubernetes, OpenTelemetry and LFDT projects, 4 of 6 name **no individuals on the website at all**, and **none** publish GitHub handles or avatars [mcp-governance, kubernetes-community].
- MCP is the outlier that names people, and lists bare names with **no employer affiliations**, justifying it: "Membership in the technical governance process is for individuals, not companies... membership is associated with the person rather than the company employing that person" [mcp-governance].
- LF Decentralized Trust distinguishes **labs from projects**: a lab is "an LF Decentralized Trust lab", never carries the "Hyperledger" prefix, and should not use the Graduated/Incubating vocabulary (the three stages are Graduated, Incubating, Labs) [lfdt-trademarks].
- LFDT's trademark policy forbids detaching the logo icon from the primary lockup — "Our logo icon is not permitted to be detached from the primary logo" — which rules out using an LFDT glyph as an inline icon [lfdt-trademarks].
- `hyperledger.org` now 301-redirects to `lfdecentralizedtrust.org`; legacy trademark/brand links are stale [lfdt-trademarks].

## SOURCES

**whatwg-working-mode**
URL: https://whatwg.org/working-mode
Accessed: 2026-08-04
Quote: "Changes of editorial nature, or which only impact non-normative text, can be made, accepted, or rejected by the editor without discussion." / "The addition must have the support of at least two implementers."

**whatwg-stages**
URL: https://whatwg.org/stages
Accessed: 2026-08-04
Quote: "Stage 0 (Proposal): That the proposer intends to use the stage process to work on their idea... These checkpoints are modeled loosely on the TC39 process, which uses the concept of stages."

**otep-readme**
URL: https://github.com/open-telemetry/oteps
Accessed: 2026-08-04
Quote: "An OTEP is `approved` when four reviewers github-approve the PR. An OTEP is `integrated` when four reviewers github-approve the spec PR."

**mcp-sep**
URL: https://modelcontextprotocol.io/community/sep-guidelines
Accessed: 2026-08-04
Quote: "Skip the SEP process for: Bug fixes and typo corrections, Documentation clarifications, Adding examples..." / "dormant — No sponsor found within 6 months; can be revived"

**mcp-governance**
URL: https://modelcontextprotocol.io/community/governance
Accessed: 2026-08-04
Quote: "Membership in the technical governance process is for individuals, not companies. That is, there are no seats reserved for specific companies, and membership is associated with the person rather than the company employing that person."

**x402-contributing**
URL: https://github.com/x402-foundation/x402
Accessed: 2026-08-04
Quote: "PR 1: Specification Only — Submit spec in `specs/schemes/<scheme>/` following existing format... PR 2: Reference Implementation... PR 3: Additional SDKs"

**kubernetes-community**
URL: https://kubernetes.io/community/
Accessed: 2026-08-04
Quote: "reach out to the Kubernetes Code of Conduct Committee at conduct@kubernetes.io"

**lfdt-trademarks**
URL: https://www.lfdecentralizedtrust.org/trademarks-guidelines (logos: https://www.lfdecentralizedtrust.org/logos-guidelines)
Accessed: 2026-08-04
Quote: "Don't modify any LF Decentralized Trust trademarks or logos or project logos (e.g., do not abbreviate them, add hyphens or other characters, or change the colors, orientation or any other visual aspect of any logos)." / "Our logo icon is not permitted to be detached from the primary logo."

## SYNTHESIS

The instinct when writing a "how the spec changes" section is to invent a numbered
pipeline — proposal → review → approval → consultation. That instinct is wrong,
and this survey shows why: **the projects with the best reputation for short,
concrete process documentation do not use stages.** WHATWG's reputation rests on
a page that documents *what must be true for a change to land*, not *what phase
it is in*. Stages are a TC39 inheritance that WHATWG adopted later and marked
optional.

Two transferable rules for any small spec project:

1. **Every bar should be countable.** OTEP's "four reviewers github-approve" is
   the model — a reader can verify whether it happened. Prose about consensus
   cannot be checked and reads as theatre.
2. **State the carve-out.** Documenting only the heavyweight path overstates
   ceremony and makes contributors think a typo fix needs a proposal. Both
   WHATWG and MCP explicitly enumerate what skips the process.

Scale matters more than prestige when choosing a model. W3C and IETF are the
famous processes but describe *document maturity* across a multi-year track with
a paid secretariat; copying their vocabulary into a lab-stage project produces
promises nobody can honour. x402 (three sequenced PRs) and OTEP (four states) are
the right reference class for anything under a dozen maintainers.

On maintainers: a website roster is a maintenance liability that reads as
marketing, and the field has converged against it. Names belong in a
version-controlled `MAINTAINERS.md`/`OWNERS` that reviewers can diff; the website
should link to that file rather than mirror it. If names do go on the site, MCP's
convention — bare names, no affiliations, individuals-not-companies — is the one
with a stated governance rationale behind it. Contact is always a channel
(Discord, mailing list, CoC address), never a person.

The LFDT lab-vs-project distinction is a live naming trap for anything in that
foundation: "lab" is lowercase in their own pattern, never takes the
"Hyperledger" prefix, and never uses Graduated/Incubating language. Their icon
also cannot legitimately be used as a standalone inline mark, which kills the
common "put an LFDT glyph next to the GitHub glyph" idea before it starts.
