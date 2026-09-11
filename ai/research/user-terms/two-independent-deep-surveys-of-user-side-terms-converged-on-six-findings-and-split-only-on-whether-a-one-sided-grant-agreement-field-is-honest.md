---
title: "Two independently-run deep surveys of user-side data terms converged on six findings and disagreed on exactly one thing — whether a grant may record `accepted_at` for an agreement only one party ever signed"
date: 2026-09-03
topic: user-terms
tags: [privacy, myterms, ieee-7012, consent-records, oauth, rar, agent-verification, pdpp]
status: draft
sources: [synthesis, claude-report, codex-report, narrow-report, judge, pib-aa, sahamati-aa, idsa-uc, ieee-7012]
source_session: unknown
---

<!--
This entry records the RECONCILIATION of two same-day independent surveys, not their
findings. The findings themselves are in the four sibling entries listed under
SYNTHESIS — read those for the landscape. Read this one when you want to know which
of two disagreeing reports to believe, or how much a same-brief convergence is worth.
-->

## CLAIMS

- Two agents given the same brief and no access to each other's work produced landscape maps that agreed on six load-bearing findings: no scheme letting an individual author arbitrary terms ever reached scale; the shape that scaled is a regulator-defined, recipient-authored object the user only narrows; terms must be rostered not arbitrary; post-transfer usage control does not exist; LLMs do not remove the free-text constraint; and IEEE 7012 excludes party-to-party negotiation. They also independently agreed on the same four mistakes to avoid. [synthesis] [claude-report] [codex-report]
- They independently derived the same matching rule for combining a client's declared acceptable terms with an owner's chosen term: exact identifier-and-version set intersection at the owner's authorization server, fail-closed on empty intersection, with semantic similarity advisory only. Neither proposed subsumption or conflict detection; both named ODRL/ABAC equivalence-mapping as the space to stay out of. [synthesis] [claude-report] [codex-report]
- Their one substantive disagreement was whether a v0.1 protocol should carry an optional grant-level `agreement` reference. The better-supported position is the negative one, and its reason is semantic rather than about timing: a one-sided record carrying `proffered_by` plus `accepted_at` cannot establish client authority, mutual assent, the exact incorporated text, or matching retention by both parties, so recording `accepted_at` alone asserts a bilateral fact the protocol cannot prove. [codex-report] [synthesis]
- The pro-field report's own gating conditions ("at least one client willing to declare which terms it accepts") were unmet, so its recommendation resolved to the same action as the against-field report. **A confidence-number gap between two reports is not always a disagreement** — one report's 0.7 was about whether to build a client terms-declaration at all, the other's 0.90 about how to design one conditional on building it. Read what the number is attached to before treating the gap as conflict. [synthesis]
- Two apparently conflicting adoption figures for India's Account Aggregator are not in conflict: 450M+ cumulative consents / 294M+ linked accounts (Sahamati, the sector's own industry body, mid-2026) versus 112.34m users-with-linked-accounts / 2.2bn enabled accounts (India's Ministry of Finance via PIB, 2025-09-02) differ in date and denominator. Prefer the government figure where a number is load-bearing. [sahamati-aa] [pib-aa]
- Two apparently conflicting status labels for Australia's CDR compose rather than conflict: "99% of household bank deposits covered but low uptake" and "a 2024 reset that re-permitted bundled consent, narrowed mandatory scope and dropped the dark-pattern ban" are the same story told from supply and demand sides — a regulator moving toward the closed/bundled shape after high coverage failed to produce use. [codex-report] [claude-report]
- Both reports independently returned the same negative on targeted search: no OAuth-family deployment anywhere carries a policy or terms artifact inside an issued grant or introspection response, and no client anywhere declares which user-side terms it accepts. Two independent negatives on the same question are worth more than one. [claude-report] [codex-report]
- Both independently corrected the same three errors in an earlier same-day narrow report and its judge: counter-offers are a DPV community-extension concept, not IEEE 7012 (which excludes negotiation); the DPV `STANDARD-IEEE-7012` extension is listed in DPV 2.3 and not stranded; and RFC 9396 §5's unknown-field rejection governs the client's *request*, so it is no argument for a grant-side field. All three errors in the original ran in the direction of that report's own recommendation. [synthesis] [narrow-report] [judge]
- The IDSA usage-control quote that both reports lean on ("cannot guarantee enforcement once data leaves the connector or domain of the data provider") was extracted from a 5.7MB PDF by a fetch summariser in one pass and not hand-verified character-by-character. Verify before quoting it in anything published. [idsa-uc]

## SOURCES

**synthesis**
URL: `~/code/pdpp/local/research/USER-TERMS-SYNTHESIS-0903.md`
Accessed: 2026-09-03
Note: the reconciliation of the two reports below, written for the PDPP owner. Landscape map by model, direct answers with confidence numbers, PDPP implications, disagreements with the earlier narrow pair, open questions.

**claude-report**
URL: `~/code/pdpp/local/research/USER-TERMS-DEEP-CLAUDE-0903.md` (raw findings in `local/research/_deep-0903/area{1..7}-*.md`)
Accessed: 2026-09-03

**codex-report**
URL: `~/code/pdpp/local/research/USER-TERMS-DEEP-CODEX-0903.md`
Accessed: 2026-09-03

**narrow-report**
URL: `~/code/pdpp/local/research/TERMS-PRIOR-ART-0903.md`
Accessed: 2026-09-03

**judge**
URL: `~/code/pdpp/local/TERMS-JUDGE-0903.md`
Accessed: 2026-09-03

**pib-aa**
URL: https://www.pib.gov.in/PressReleasePage.aspx?PRID=2162953&lang=1&reg=3
Accessed: 2026-09-03
Quote: "112.34m users with linked accounts; 2.2bn enabled accounts" (India Ministry of Finance, 2025-09-02)

**sahamati-aa**
URL: Sahamati / RBI Account Aggregator ecosystem metrics, mid-2026 (cited in claude-report)
Accessed: 2026-09-03
Quote: "450M+ cumulative consents; ~700,000/day; 1,020 FIUs, 176 FIPs, 17 live AAs; 294M+ linked accounts"

**idsa-uc**
URL: IDSA Usage Control position paper (cited in both reports); https://link.springer.com/chapter/10.1007/978-3-030-93975-5_8
Accessed: 2026-09-03
Quote: "cannot guarantee enforcement once data leaves the connector or domain of the data provider" — PDF-extracted, NOT hand-verified.

**ieee-7012**
URL: https://standards.ieee.org/ieee/7012/7192/
Accessed: 2026-09-03
Quote: party-to-party negotiation is outside scope; the chosen agreement "shall be signed electronically by both parties or their agents, and a matching record shall be kept by both sides"

## SYNTHESIS

The reusable finding is methodological. Running the same research brief twice, independently, on different models, cost roughly double and bought three things a single pass cannot: (1) six findings whose agreement is evidence rather than assertion, because neither agent could have anchored on the other; (2) two independent negatives on the same targeted search, which is the only way an absence claim gets any weight; and (3) one genuine disagreement, isolated and small enough to adjudicate on its merits — and it turned out to be the actual decision at hand. A single report would have delivered whichever side of that split its author happened to land on, with a confidence number and no way to see the other position existed.

Two traps this reconciliation surfaced, both of which look like conflicts and are not. **Confidence numbers attached to different questions** — 0.7 "should we build it" versus 0.90 "how should it be designed if built" — read as a 20-point disagreement and are not one. **Adoption figures with different denominators and dates** read as a factual conflict and are not; the useful move is not to pick the bigger number but to ask which source is the industry body for the sector it reports on.

When the reports did genuinely split, the tiebreaker that worked was not confidence, recency, or thoroughness: it was which argument survives the other side's best case. One report argued "don't add the field yet, no client is asking" (a timing argument that expires the moment a client appears); the other argued "the field as specified asserts a bilateral fact from one party's record" (a semantic argument that survives). Prefer the objection that does not have an expiry date.

For the domain finding itself — the landscape, the adoption record, the enforcement reality — read the four sibling entries produced the same day, not this one: `protocols/user-proffered-terms-schemes-fail-in-proportion-to-how-much-semantics-they-carry-...`, `protocols/only-regulator-defined-recipient-authored-consent-objects-reached-national-scale-...`, `protocols/post-transfer-usage-control-is-not-real-...`, and `user-terms/user-proffered-privacy-terms-succeed-only-when-rostered-or-legally-narrow.md`.
