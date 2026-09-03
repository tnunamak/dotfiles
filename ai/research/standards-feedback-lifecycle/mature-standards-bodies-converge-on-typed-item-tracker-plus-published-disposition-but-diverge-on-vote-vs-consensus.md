---
title: "Mature standards bodies (W3C, HL7 FHIR, IETF, OpenID Foundation) all run public review through a typed-item tracker that resolves to a published disposition record, but split sharply between consensus-based (W3C/IETF) and formal-vote (FHIR/OpenID) closure, and none merge strategic/cross-cutting input into the same tracker as discrete comments"
date: 2026-08-29
topic: standards-feedback-lifecycle
tags: [standards-bodies, w3c, ietf, hl7-fhir, openid-foundation, comment-disposition, ballot-reconciliation, errata, horizontal-review, public-comment-period]
status: draft
sources: [w3c-disco, w3c-process-doc, w3c-webplatform-workflow, w3c-horizontal-review-guide, w3c-tag-design-reviews, w3c-errata-mailing-list, hl7-jira-ballot-process, hl7-au-ballot-resolution, hl7-fhir-ballot-intro, hl7-fmg-r5-not-ready, hl7-fmm-maturity, ietf-rfc8874, ietf-rfc8875, ietf-rfc7282-humming, ietf-last-call-guidance, ietf-bof-role, ietf-rfc2418, rfc-errata-how-to-verify, rfc-errata-process-draft, openid-review-announcements-sample]
source_session: 8b2c8ac0-a286-48e1-b140-253d6b93668c
---

<!--
Prior-art sweep for a small standards lab (4 maintainers, ~80 heterogeneous feedback
items) designing a public comment period. Scope: report what mature bodies DO, not
design recommendations for the lab.
-->

## CLAIMS

### W3C — Disposition of Comments

- W3C's core review-comment mechanism is the "Disposition of Comments" (DoC) document: a Working Group publishes it to record how every comment received during a review period (Last Call / Wide Review / AC Review) was addressed. [w3c-process-doc]
- The item taxonomy is tracked per-issue with four annotation fields: `ACTION` (Reject/Accept), `CHANGE-TYPE` (None/Editorial/Substantive), `RESOLUTION` (the WG's decision text), `COMMENTER-RESPONSE` (whether the commenter accepted or rejected the resolution). [w3c-disco]
- Tooling: "DisCo" is a purpose-built XSLT-based generator. Workflow: annotate issues in the WG's Tracker with a consistent title prefix (e.g. "Last Call Comment: ..."), pull an XML dump via the Tracker API, run it through the DisCo XSLT template (parameterized by work title/stage/product), and render to HTML — producing the polished DoC document directly from tracker metadata rather than hand-compiled. [w3c-disco]
- A separate, independently observed W3C triage pattern (accessibility guideline reviews) sorts incoming comments into: typographical/formatting errors, editorial comments, and substantive comments — with substantive further split into new issue / old issue with new argument / old issue with old argument. [w3c-webplatform-workflow]
- The substantive/editorial distinction is load-bearing procedurally, not just descriptive: in the W3C Process Document itself, whether a charter change is "substantive" vs "editorial" determines whether it needs full Advisory Committee review or can be approved by Team Decision alone. [w3c-process-doc]
- Formal requirement gate: wide review must be demonstrated before a document can advance to Candidate Recommendation, be updated as a CR Snapshot, or become a Recommendation. Reviewers are urged to comment as early as possible because "Working Groups are often reluctant to make substantive changes to a mature document." [w3c-horizontal-review-guide]
- Disagreement/escalation: if a WG advances a document despite a horizontal group's objection, a horizontal group MAY file a Formal Objection; the W3C Council (top technical architecture body) adjudicates. Even if the WG proceeds, guidance is to leave the issue open in the horizontal group's own repo rather than closing it — "some issues may take years to get resolved, but that doesn't mean those should be forgotten." [w3c-horizontal-review-guide]
- Post-publication corrections use a separate, lighter artifact: an "errata" page per Recommendation, listing corrections classified Substantive or Editorial, in reverse-chronological order, linked from the Recommendation itself. Substantive errata are not normative until approved via a formal "Call for Review of Proposed Corrections" (and, if adopted, folded into an edited Recommendation within 6 months); most WGs in practice publish "WG-approved errata" informally without going through the fully formal process. [w3c-errata-mailing-list]
- Final published artifact: (a) the Disposition of Comments document itself (a per-issue table: comment → change-type → resolution → commenter response), consumed by the Director/Team at the transition-request stage; (b) post-publication, a standing errata page linked from the spec.

### W3C — non-discrete / cross-cutting input (Q2)

- W3C's answer to "input that isn't a discrete comment" is horizontal (wide) review, run through five dedicated, topic-owned repos/queues separate from the spec's own comment tracker: TAG architecture review (`w3ctag/design-reviews`), accessibility (`a11y-request`), internationalization (`i18n-request`), privacy (`w3cping/privacy-request`), security (`w3c/security-request`). [w3c-horizontal-review-guide]
- A spec seeking review opens a single tracking "meta-issue" in its own repo (e.g. "Wide review tracker") that fans out links to the five horizontal-group issues, so cross-cutting review status is visible without commingling with per-line-item spec comments. [w3c-horizontal-review-guide]
- Groups do self-assessment before requesting horizontal review (e.g. filling out the Security/Privacy Self-Review Questionnaire, writing a Privacy Considerations section) — a pre-filter that keeps low-effort requests out of the horizontal groups' queues. [w3c-horizontal-review-guide]
- Charter-level strategic concerns get their own separate instrument: charter refinement and AC Review of a *charter* (not a spec) has its own Disposition of Comments, structurally identical in form to a spec's DoC but scoped to scope-of-work/governance questions rather than technical text. [w3c-process-doc]

### HL7 FHIR — ballot reconciliation

- Mechanism: HL7 freezes a specification version, opens a scheduled ballot window, and registered balloters (a) submit line-item feedback into Jira ("Specification Feedback" project per product family: FHIR, CDA, V2, Other) and (b) cast one overall ballot vote (affirmative / negative / abstain) on the whole specification. [hl7-jira-ballot-process]
- Item taxonomy (Jira issue types): **Change Request** (can carry a negative vote), **Technical Correction**, **Comment**, **Question** (the latter three can only be voted affirmative — they cannot by themselves make a ballot negative). A negative overall ballot vote requires at least one Change Request with a substantive comment; "Negative Ballot line item without Comment" is disallowed/ignored. [hl7-jira-ballot-process]
- Voting is per-item as well as per-ballot: a balloter can vote "affirmative with comment" on an individual item (endorse the spec but still flag something), not only unconditional approval. [hl7-jira-ballot-process]
- Resolution/disposition taxonomy applied by the sponsoring Work Group during reconciliation: **Persuasive** (change made as requested), **Persuasive with Modification** (change made, but differs from what was asked), **Not Persuasive** (no change, rationale given), **Not Persuasive with Modification** (WG disagrees but makes an unrelated/clarifying change anyway), **Not Related** (out of ballot scope), **Considered – No Action Required**, **Considered for Future Use** (deferred, stays "outstanding" for a future release), **Duplicate** (resolved via the other ticket), **Referred and Tracked** (needs more input, held open). [confirmed via multiple: hl7-jira-ballot-process, hl7-au-ballot-resolution]
- Workflow/tooling for volume management: WGs use Jira's grouping/scheduling fields to "block vote" — batching related, typically low-controversy items for one collective resolution rather than resolving item-by-item; chairs invent ad hoc groupings (by topic, by call, by WGM). [hl7-jira-ballot-process]
- Closure mechanic: after reconciliation, a balloter who cast a negative vote is invited to withdraw it once they've seen how their line items were resolved; negative votes can be "un-voted" any time before ballot close. The overall ballot only truly fails if unresolved/unwithdrawn negatives remain past the close. [hl7-jira-ballot-process]
- Final published artifact: the ballot's Jira project itself (searchable, filterable per-item disposition with vote tallies, e.g. "12-0-0"), referenced from ballot desk/spreadsheet reconciliation views; there is no separate prose "disposition of comments" document analogous to W3C's — Jira *is* the artifact of record.

### HL7 FHIR — pre-ballot quality gate / non-comment input (Q2/Q3 combined)

- FHIR has an explicit maturity model (FMM) gating what may even go to formal ballot: e.g., FMM level 3 requires 10 distinct ballot comments from 3 different organizations already logged; content not meeting maturity bars is steered toward "incubator" Implementation Guides rather than the ballot track. [hl7-fmm-maturity]
- FHIR's Management Group (FMG) has precedent for pulling planned content from a ballot cycle wholesale when it judges the material "not ready" (e.g., R5 content that could not be completed in time was deferred rather than balloted under-baked) — this is a pre-ballot gate exercised by the governing body, not a per-item disposition. [hl7-fmg-r5-not-ready]
- Readiness checklist requirement: an Implementation Guide must be handed to its sponsoring Work Group at least 3 weeks before ballot opens, with a mandatory 1-2 week WG QA/approval window and (where applicable) a Connectathon test report (target: ≥3 independent systems exercising ~80% of the guide) before the content is allowed into the ballot at all. [hl7-fmm-maturity]
- Net effect: FHIR's answer to "strategic readiness" concerns is a pre-ballot admission gate (maturity model + WG sign-off + connectathon evidence) enforced by the FMG, not a ballot-tracker item type — strategic/adoption-readiness concerns are resolved before the tracker opens, rather than inside it.

### IETF — Last Call, datatracker, GitHub issues, errata

- Last Call is explicitly the *final* review stage; comments go to a dedicated `last-call@ietf.org` list, and IETF guidance directs purely editorial/typo comments to authors/chairs/AD only, while substantive technical comments get moved to the WG's own list for resolution. [ietf-last-call-guidance]
- No formal voting: consensus is judged by the WG chair (and later confirmed by the document shepherd and IESG) via "rough consensus," gauged informally through "humming" (RFC 7282) rather than counted votes. Critically, the hum doesn't resolve anything by itself — an issue is only closed when it has actually been addressed to the chair's judgment; a single unaddressed substantive objection blocks consensus regardless of numeric support. [ietf-rfc7282-humming]
- Responsibility chain for tracking that every comment was actually handled: WG chairs ensure rough consensus is followed (RFC 7221); the document shepherd separately re-confirms all WG-raised issues were addressed before submission; the IESG is responsible for confirming Last-Call-raised issues were addressed before approval. There is no single canonical "disposition of comments" artifact — the mailing list thread is treated as the authoritative record ("regardless of tools... the mailing list discussion is the single source of truth"). [ietf-last-call-guidance]
- Where GitHub is used (optional per WG, RFC 8874), the recommended label taxonomy is: `editorial` (no substantive effect — editors resolve at their discretion) vs. `design` (affects implementations/interop — requires WG consensus to close); process-state labels `editor-ready` / `proposal-ready` / `has-consensus` track an issue's path from proposed fix to WG-blessed fix; `future`/`next-version` defers; `invalid` and `blocked` describe non-actionable or externally-gated issues. Chairs typically reserve applying/closing the `design` label to themselves so substantive issues can't be silently editor-closed. [ietf-rfc8874]
- Errata (post-RFC-publication corrections) are a wholly separate track from Last Call, with 4 states: **Reported** (unverified) → **Verified** (accepted, but the RFC text itself is not republished/patched — the erratum is linked alongside it) / **Rejected** (redundant or wrong) / **Held for Document Update** (valid but deferred to the next full revision, e.g. because the errata process itself cannot legally alter a normative artifact like a YANG module revision). Technical errata are adjudicated by the stream owner (for IETF-stream RFCs, typically the responsible AD); editorial errata by the RFC Editor. [rfc-errata-how-to-verify]
- Charters/BOFs (the pre-document, strategic-direction layer) run on an entirely separate track from Last Call: proposed charters go through IAB "Internal Review" then community "External Review" (via ietf-announce), with joint IAB/IESG calls specifically to weigh in on whether a proposed area of work is architecturally/strategically sound — this is structurally never a Last-Call comment. [ietf-bof-role]

### OpenID Foundation — public review periods

- Mechanism: a fixed **45-day public review period** (per IPR policy) on a proposed Implementer's Draft, open to anyone (non-members can read/comment via the WG mailing list; only paid members vote later). [openid-review-announcements-sample]
- After the review period, if the WG judges no unresolved issues remain, a **voting period** opens (commonly 14 days, sometimes 7, with early voting allowed a week before the formal start) in which only OpenID Foundation members cast a formal approve/reject vote. [openid-review-announcements-sample]
- If issues surface during review that the WG believes require a text change, the WG republishes a revised draft (visibly changelogged, e.g. "draft -47... incorporating feedback received during the review period including...") — there is no discrete per-comment disposition record published; the *diff between draft N and N+1*, described in the announcement prose, functions as the disposition. [openid-review-announcements-sample]
- Non-normative-only revisions do not reset the 45-day clock; a materially normative change does. Overlapping reviews of specs "in the same family" can be explicitly superseded by a newer combined review announcement rather than run in parallel. [openid-review-announcements-sample]
- Errata get an analogous but separate "Public Review Period of Proposed Errata" process — same 45-day/vote structure as an Implementer's Draft, but scoped to the errata list, not the base spec. [openid-review-announcements-sample]
- OpenID's public-facing artifact of record is the sequence of dated blog announcements on openid.net themselves (each stating: what's being reviewed, review window, what changed since the last draft, and — post-vote — the approval outcome), not a separate reconciliation document.

## SOURCES

**w3c-disco**
URL: https://www.w3.org/2006/07/SWD/RDFa/disco
Accessed: 2026-08-29
Quote: "CHANGE-TYPE: [None|Editorial|Substantive] ... COMMENTER-RESPONSE: [Accept|Reject]"

**w3c-process-doc**
URL: https://www.w3.org/policies/process/ ; https://www.w3.org/policies/process/drafts/issues-20211102
Accessed: 2026-08-29
Quote: "the Call for Review of a new or modified charter must include a disposition of comments received during the charter refinement process, highlighting any issues that were closed despite sustained objections."

**w3c-webplatform-workflow**
URL: https://webplatform.github.io/docs/WPD/Annotations/Workflows/Spec_Review/
Accessed: 2026-08-29
Quote: "a triage team sorts the comments into categories including typographical/formatting errors, editorial comments, and substantive comments"

**w3c-horizontal-review-guide**
URL: https://w3c.github.io/guide/documentreview/ ; https://tag.w3.org/workmode/design-reviews/
Accessed: 2026-08-29
Quote: "Before a document gets advanced to Candidate Recommendation... the W3C Process requires a Group to show that the specification has received wide review."

**w3c-tag-design-reviews**
URL: https://tag.w3.org/workmode/design-reviews/
Accessed: 2026-08-29

**w3c-errata-mailing-list**
URL: https://www.w3.org/2010/WebCGM21-errata.html ; https://lists.w3.org/Archives/Public/public-webcgm-wg/2007Oct/0002.html
Accessed: 2026-08-29
Quote: "errata are numbered, classified as Substantive or Editorial... substantive corrections are proposed by the responsible Working Group and are not considered normative until approved by a Call for Review of Proposed Corrections"

**hl7-jira-ballot-process**
URL: https://confluence.hl7.org/spaces/HL7/pages/19136734/Jira+Ballot+Process ; https://confluence.hl7.org/spaces/HL7/pages/19136742/Coordinating+Ballot+Submissions
Accessed: 2026-08-29
Quote: "Technical Corrections, Comments and Questions may only be voted affirmative, and change requests may be voted affirmative or negative"

**hl7-au-ballot-resolution**
URL: https://confluence.hl7australia.com/display/AFR/Ballot+and+Resolution+Process
Accessed: 2026-08-29
Quote: "Not Related: The comment does not fall within the scope of the ballot... Duplicate: The proposal is substantially the same as another comment"

**hl7-fhir-ballot-intro**
URL: https://build.fhir.org/ballot-intro.html
Accessed: 2026-08-29

**hl7-fmg-r5-not-ready**
URL: (search-derived; HL7 R5 ballot cycle history) 
Accessed: 2026-08-29
Quote: "the work required to actually prepare R5 was bigger than estimated... because the content would not be ready, FMG decided that R5 would not be balloted in that cycle"

**hl7-fmm-maturity**
URL: https://confluence.hl7.org/spaces/FHIR/pages/91980748/F+-+Submission+for+Ballot+or+Publication
Accessed: 2026-08-29
Quote: "FMM 3 requires formal balloting with 10 distinct comments from 3 organizations"

**ietf-rfc8874**
URL: https://www.rfc-editor.org/rfc/rfc8874.html
Accessed: 2026-08-29
Quote: "editorial: Issues with no substantive effect... design: Issues affecting implementations or interoperability; require working group consensus"

**ietf-rfc8875**
URL: https://www.rfc-editor.org/rfc/rfc8875.html
Accessed: 2026-08-29

**ietf-rfc7282-humming**
URL: https://www.rfc-editor.org/rfc/rfc7282
Accessed: 2026-08-29
Quote: "it's not the hum that ends things, it's that the issues have been addressed"

**ietf-last-call-guidance**
URL: https://ietf.org/blog/last-call-guidance-community/ ; https://datatracker.ietf.org/doc/statement-iesg-last-call-guidance-to-the-community-20210416/
Accessed: 2026-08-29
Quote: "regardless of the tools and processes used, including issue trackers, the mailing list(s) discussion is the single source of truth for determining if all comments have been considered"

**ietf-bof-role**
URL: https://www.iab.org/role/evaluating-new-work-proposals/ ; https://www.rfc-editor.org/info/rfc2418/
Accessed: 2026-08-29

**ietf-rfc2418**
URL: https://www.rfc-editor.org/info/rfc2418/
Accessed: 2026-08-29

**rfc-errata-how-to-verify**
URL: https://www.rfc-editor.org/how-to-verify/ ; https://errata.rfc-editor.org/
Accessed: 2026-08-29
Quote: "Reported: unverified. Verified: edited as necessary and verified. Rejected: redundant or incorrect, discarded. Held for Document Update: not a necessary update now, but should be considered in future revisions."

**rfc-errata-process-draft**
URL: https://datatracker.ietf.org/doc/draft-rpc-errata-process/
Accessed: 2026-08-29

**openid-review-announcements-sample**
URL: https://openid.net/public-review-period-for-proposed-openid-federation-1-1-final-specifications/ ; https://openid.net/public-review-period-for-proposed-second-implementers-draft-of-openid-for-verifiable-presentations-specification/ ; https://openid.net/public-review-period-for-errata-to-openid-connect-for-identity-assurance-1-0/
Accessed: 2026-08-29
Quote: "this review period will be followed by a fourteen-day voting period during which OpenID Foundation members will vote on whether to approve this draft"

## SYNTHESIS

**Comparison table — item taxonomy**

| Body | Discrete-item types | Substantive/editorial split? | Closure mechanism | Published artifact |
|---|---|---|---|---|
| W3C | Untyped "comment" (Tracker issue) | Yes — explicit `CHANGE-TYPE` field (None/Editorial/Substantive), procedurally load-bearing (governs charter-approval route) | Consensus (Director/Team judgment) + horizontal-group sign-off; Formal Objection escalates to Council | Disposition of Comments doc (per review) + standing errata page (post-publication) |
| HL7 FHIR | 4 typed tickets: Change Request, Technical Correction, Comment, Question | Not editorial/substantive — instead a 9-way resolution taxonomy (Persuasive / Persuasive-w/-Mod / Not Persuasive / Not-Persuasive-w/-Mod / Not Related / Considered-No-Action / Considered-Future / Duplicate / Referred-Tracked) | Formal per-item AND per-ballot vote (affirmative/negative/abstain), negative-withdrawal after reconciliation | The Jira project itself (no separate prose document) |
| IETF | Untyped mailing-list comment; optional GitHub issue with `editorial`/`design` labels | Yes — `editorial` vs `design` (=substantive), same conceptual split as W3C, expressed as GitHub labels not a formal doc field | Rough consensus (chair judgment, "humming" as sense-check, not a vote); shepherd + IESG re-confirm | No single document — mailing list thread is the system of record; separate Errata DB (4-state) for post-publication |
| OpenID Foundation | Untyped review-period feedback (mailing list) | Implicit only — normative vs non-normative distinguishes whether the 45-day clock resets | Formal member vote (14-day, sometimes 7-day, period) after WG judges review "clean" | Sequence of dated blog announcements per draft revision (diff-as-disposition), no per-comment ledger |

**Comparison table — non-discrete/cross-cutting input (Q2) and pre-review backlog (Q3)**

| Body | Where strategic/cross-cutting input lives | Pre-review backlog handling |
|---|---|---|
| W3C | Horizontal review: 5 separate topic-owned repos (TAG/a11y/i18n/privacy/security), fanned out from a single "wide review" meta-issue in the spec's own repo; charter-level concerns get their own separate charter DoC | Not directly evidenced; W3C's continuous Tracker model (comments accrue from first publication onward) means there is no separate "internal" vs "public" tracker to merge — the same Tracker instance is live pre- and post- Last Call |
| HL7 FHIR | Pre-ballot maturity gate (FMM levels + WG sign-off + connectathon evidence) run by the FHIR Management Group — strategic readiness is resolved by refusing to ballot un-ready content, not inside the ballot tracker | Same Jira "Specification Feedback" project spans pre-ballot and ballot life; immature content is moved to separate incubator IGs rather than merged into the ballot backlog |
| IETF | Charter/BOF track (IAB Internal Review → community External Review → joint IAB/IESG calls) — structurally separate from Last Call and never enters last-call@ or the WG GitHub tracker | GitHub issues, when used, are opened continuously from WG adoption onward (RFC 8874); no evidence of a distinct "seed from internal backlog into Last Call" event — again, one continuous tracker |
| OpenID Foundation | No separate cross-cutting channel found; strategic/adoption concerns appear to be absorbed into ordinary WG mailing-list discussion pre-review, then either fixed (revised draft) or left as the WG's judgment call to proceed to vote | Same WG mailing list carries pre-review and public-review discussion; the 45-day "public" period is a formal window layered onto an already-open list, not a separate tracker merged in |

**Cross-body pattern worth flagging (descriptive, not a recommendation):** every body studied uses exactly ONE continuous tracker/list that spans pre-review and public-review — none of them run a separate "internal" comment system that gets merged into a "public" one at review-open. The public review period is a formal deadline/gate layered onto a tool that was already accepting input. Strategic/cross-cutting concerns are handled by routing them to an entirely different venue (W3C horizontal review repos, IETF charter/BOF track, FHIR's pre-ballot maturity gate) rather than by tagging them differently within the same comment tracker — the separation is by venue, not by a label inside one shared queue. The one partial exception is IETF's GitHub label scheme (`editorial` vs `design`), which does tag substantive-vs-not within a single tracker, closest in spirit to W3C's `CHANGE-TYPE` field.
