---
title: "Successful spec/protocol projects (Kubernetes KEP, Rust RFC, TC39, Python PEP) separate item kinds via a numbered epistemic-maturity ladder, push all pre-formal strategy discussion to a forum outside the issue tracker, and use countable/bot-driven triage labels rather than scoring frameworks to keep noise down"
date: 2026-08-29
topic: spec-team-triage-and-proposal-lifecycles
tags: [triage, kep, tc39, rfc, pep, github-projects, linear, prioritization, maturity-ladder, standards-bodies]
status: draft
sources: [k8s-kep-process, k8s-kep-template, k8s-issue-triage-guide, k8s-triage-party, rust-rfc-book, rust-internals-pre-rfc, rust-compiler-priorities, tc39-process-doc, tc39-how-we-work, pep0001, gh-projects-v2-fields, gh-issue-fields, synclinear, w3c-github-labels, w3c-issue-labels-wiki, csswg-contributing, nodejs-tsc-charter, mlflow-issue-triage, nomad-issue-labels, rice-critique]
source_session: unknown
---

## CLAIMS

**Maturity ladders (Q1)**

- Kubernetes KEPs use a required `status` field with exactly these states: `provisional` (SIG has accepted the work must be done, still being defined), `implementable` (approvers approved for implementation), `implemented`, `deferred` (proposed but not actively worked), `rejected` (kept as historical document, not deleted), `withdrawn` (author-initiated), `replaced` (points to superseding KEP via `superseded-by`) [k8s-kep-template].
- KEPs additionally carry a separate `stage` field (`alpha`/`beta`/`stable`) tracking implementation maturity within a release cycle, distinct from the proposal-status field — two orthogonal maturity axes, not one [k8s-kep-template].
- KEPs are prefixed by their GitHub tracking-issue number and filed into per-SIG subdirectories; a KEP must be "socialized" with a sponsoring SIG before formal submission [k8s-kep-process].
- Rust's formal RFC has exactly two pre-formal venues for half-formed ideas: the official Zulip server, and "pre-RFC" threads on `internals.rust-lang.org` (the discussion forum) — both explicitly upstream of the PR-based RFC repo [rust-rfc-book, rust-internals-pre-rfc].
- The Rust compiler-development guide frames the pre-RFC step as deliberately unstructured: "Your post doesn't have to follow any particular structure, and it doesn't even need to be a cohesive idea" [rust-internals-pre-rfc].
- A former Rust core team member's public critique states the RFC-as-PR format creates an expectation that "most design work is done" by the time of formal submission, which is *why* the community built the informal pre-RFC forum layer outward of the tracker [rust-internals-pre-rfc].
- Every accepted Rust RFC gets exactly one associated GitHub tracking issue for implementation, entering the team's ordinary bug-triage flow rather than a separate RFC-specific process [rust-rfc-book].
- Only "substantial" Rust changes require an RFC at all; changes that "strictly improve objective, numerical quality criteria" go through normal PRs — an explicit escape hatch that keeps small changes off the heavyweight track [rust-rfc-book].
- TC39 stages are Stage 0 (Strawperson, no entrance criteria) → Stage 1 (Proposal: committee commits time, needs a champion + problem/solution prose) → Stage 2 (Draft: committee has chosen a preferred solution space, spec text placeholders acceptable) → Stage 2.7 (Candidate-in-principle: complete spec text, reviewer sign-off) → Stage 3 (Candidate: recommended for implementation, further changes only from web-incompat or implementation feedback) → Stage 4 (Finished: two compatible implementations passing Test262, real shipping experience, PR to spec repo) [tc39-process-doc].
- TC39 requires every proposal from Stage 1 onward to be champion-owned by a registered TC39 delegate; anything not yet formally submitted is by definition Stage 0 ("strawperson"), and only delegates (or non-delegates registered via Ecma International) may submit even a Stage 0 item [tc39-how-we-work].
- TC39 delegates keep committee-level discussion in a separate `tc39/notes` meeting-minutes repository, distinct from each proposal's own issue tracker (which is used "to discuss design issues with the committee and community") — two trackers for two audiences, not one [tc39-how-we-work].
- Python PEPs have three types (Standards Track, Informational, Process) and these statuses: Draft, Accepted, Provisional (accepted but awaiting real-world feedback before Final), Deferred, Rejected, Withdrawn, Final, Superseded, Active (living documents never meant to complete) [pep0001].
- Python's pre-formal venue is the "Ideas" category of Python Discourse; the stated purpose is explicitly to save authors' time by pre-filtering ideas "guaranteed rejection" before anyone drafts a formal PEP [pep0001].
- WHATWG's numbered Stages 0-4 (a shorter analog) are explicitly optional and credited as modeled on TC39: "can advance directly to later stages without going through the earlier stages" — the numbered-ladder pattern is acknowledged even by its adopters as an overlay, not the load-bearing mechanism (prior corpus entry, not re-verified this session) [standards-body-sites/short-credible-change-processes...].

**Tooling for private-working-view-over-public-issues (Q2)**

- GitHub Projects v2 custom fields are historically scoped to a single project board; a maintainer explicitly requested cross-board field sharing so one field wouldn't need recreating between a public-facing board and an internal one — this was an open, unresolved community request for years [gh-projects-v2-fields].
- GitHub's 2026 "Issue Fields" feature (private preview → rolling out) fixes this by moving custom fields to the issue level with a `Public` vs `Organization only` visibility flag: only `Public`-visibility fields surface in public/internal projects, and only users with Triage-or-above repo role can edit issue-field values [gh-issue-fields].
- If an org changes a field from `Public` to `Organization only` while it's already used in a public project view, GitHub auto-removes it from that public view (restorable by flipping visibility back) — a live guardrail against accidental leakage of internal-only fields into a public board [gh-issue-fields].
- SyncLinear (community Linear↔GitHub sync) implements a private/public split via an explicit dual-label gate: a `Public` label on a Linear ticket triggers sync-out to GitHub; issues from GitHub "Core members" sync in automatically, while ordinary community GitHub issues need a `linear` label to be pulled in at all — sync is opt-in in both directions, not automatic mirroring [synclinear].
- Native Linear-GitHub sync restricts bidirectional comment sync to "authorized core members," meaning community comments and core-team comments do not sync symmetrically — a documented asymmetry, not a bug [synclinear].
- Multiple independent homegrown GitHub↔Linear bridges are explicitly two separately-maintained one-way pipes (e.g., one GitHub Action for GitHub→Linear, a separate Vercel/Next.js API for Linear→GitHub) rather than one bidirectional system — teams choose this specifically to avoid full bidirectional complexity, accepting drift risk as the tradeoff [synclinear].
- W3C's cross-spec GitHub label guide documents a horizontal-review label convention (Security/Privacy/Accessibility/Internationalization) plus a `WR-open` / `WR-pending` / `WR-resolved` three-state pipeline specifically for tracking external Wide Review comments through resolution [w3c-github-labels].
- The W3C i18n Working Group's `i18n-tracker` label is explicitly non-blocking ("Issues with this label don't need to be resolved to the satisfaction of the i18n Group before a transition") while `i18n-needs-resolution` is the blocking counterpart that only the i18n group itself may add or remove — a two-tier watch-vs-block label pattern owned by the reviewing group, not the spec editors [w3c-github-labels].
- Node.js TSC governance splits meetings into a public portion and a private portion reserved for personnel/security/confidential matters, with an explicit stated norm to minimize private-portion use; public-portion minutes are posted back via a public PR after every meeting [nodejs-tsc-charter].
- Node.js TSC's default resolution path avoids meetings entirely: a TSC member opens a public GitHub issue, @-mentions the TSC team, and the proposal passes automatically if two-plus TSC approvals accrue with no TSC opposition within 72 hours; a `tsc-agenda` label escalates to a live meeting only if async consensus-seeking fails [nodejs-tsc-charter].

**Prioritization for design questions (Q3)**

- No standards body or spec-adjacent team surfaced in this research uses RICE or an equivalent multiplicative impact/effort/confidence score for design-question prioritization; RICE and similar scoring frameworks are a product-management-team artifact (Intercom's own invention), not something found in KEP, RFC, TC39, PEP, W3C, or Node.js governance material [rice-critique — absence, not presence, is the finding].
- Independent product-management critiques of RICE converge on the same structural complaint even outside standards bodies: RICE inputs are qualitative/ordinal guesses laundered through multiplication into a false-precision number, and a cited real account attributes a shipped-product failure partly to RICE optimizing at the "feature" layer while blind to whether the feature served any real customer problem [rice-critique].
- What actually stuck, across every real spec-team example found, is qualitative/categorical labeling, not numeric scoring: Kubernetes' 5-tier `priority/critical-urgent | important-soon | important-longterm | backlog | awaiting-more-evidence`, Rust's `P-critical | P-high | P-medium | P-low` (each tier is a *process commitment* — "raised at weekly triage," "ignored until someone complains" — not a score), and HashiCorp Nomad's `stage/needs-discussion` (explicitly NOT the same as needing design work) vs `stage/needs-investigation` distinction [k8s-issue-triage-guide, rust-compiler-priorities, nomad-issue-labels].
- Rust's P-critical/P-high/P-medium/P-low tiers are defined entirely by the *cadence of attention* they guarantee (P-critical: raised at every weekly triage meeting and must get an assignee immediately; P-low: "ignored until someone complains or it gets fixed by accident") rather than by a computed score — the tier IS the SLA [rust-compiler-priorities].
- Rust's priority-assignment workflow is bot-mediated: a `triagebot` command (`@triagebot assign-prio <issue> [critical|high|medium|low]`) run from Zulip, following async monitoring by a dedicated "Prioritization WG" — a standing team whose entire job is triage, not scoring [rust-compiler-priorities].
- MLflow's issue-triage doc separates a `needs design` label ("large or tricky enough that we think it warrants a design doc and review before someone begins implementation") from a `needs committer feedback` label (design already exists, needs approach sign-off) — a two-stage needs-design vs needs-decision split matching the requested "needs-decision vs needs-research" pattern [mlflow-issue-triage].
- CSSWG's operative mechanism for surfacing a design question for actual group decision is the `Agenda+` label, applied by any WG member with write access (or requested from an editor) to bring an issue to a live call; issues are then closed with an explicit "per working group resolution" comment linking the decision — the label is a queue-admission ticket, not a priority score [csswg-contributing].
- The W3C Social Web WG and MathML WG both used a single binary "needs group decision / needs resolution" label rather than any graded scale — consensus items get flagged for a synchronous call, and the label is removed with a comment recording the decision once resolved [csswg-contributing pattern, corroborated independently].
- Kubernetes' own effectiveness data is mixed in practice despite this tooling: live Triage Party dashboards for kubectl show new-issue average wait of 334.5 days and average age of 1176 days pending triage, i.e., the labeling taxonomy does not by itself prevent backlog — throughput depends on triage-party staffing, not label design [k8s-triage-party].

## SOURCES

**k8s-kep-process**
URL: https://github.com/kubernetes/enhancements/tree/master/keps
Accessed: 2026-08-29

**k8s-kep-template**
URL: https://github.com/kubernetes/enhancements/blob/master/keps/NNNN-kep-template/kep.yaml
Accessed: 2026-08-29
Quote: "status: provisional|implementable|implemented|deferred|rejected|withdrawn|replaced"

**k8s-issue-triage-guide**
URL: https://www.kubernetes.dev/docs/guide/issue-triage/ ; https://github.com/kubernetes/community/blob/master/contributors/guide/issue-triage.md
Accessed: 2026-08-29
Quote: "priority/critical-urgent, priority/important-soon, priority/important-longterm, priority/backlog, priority/awaiting-more-evidence"

**k8s-triage-party**
URL: https://cli.triage.k8s.io/k/kubernetes ; https://release.triage.k8s.io/
Accessed: 2026-08-29
Quote: kubectl triage board showing new-issue average age 1176.0 days, average wait 334.5 days

**rust-rfc-book**
URL: https://rust-lang.github.io/rfcs/ ; https://github.com/rust-lang/rfcs
Accessed: 2026-08-29
Quote: "Every accepted RFC has an associated issue tracking its implementation in the Rust repository."

**rust-internals-pre-rfc**
URL: https://internals.rust-lang.org/ ; https://rustc-dev-guide.rust-lang.org/walkthrough.html ; https://www.ncameron.org/blog/the-problem-with-rfcs/
Accessed: 2026-08-29
Quote: "Your post doesn't have to follow any particular structure, and it doesn't even need to be a cohesive idea."

**rust-compiler-priorities**
URL: https://forge.rust-lang.org/compiler/prioritization.html ; https://github.com/rust-lang/compiler-team-prioritization/issues/3
Accessed: 2026-08-29
Quote: "P-critical ... highly recommended to be solved before a new compiler release ... raised at the compiler team's triage meeting on a weekly basis." / "P-low ... this is going to be ignored until someone complains or it gets fixed by accident."

**tc39-process-doc**
URL: https://tc39.es/process-document/
Accessed: 2026-08-29
Quote: "Stage 4 (Finished): two compatible implementations passing Test262 tests, significant shipping experience... editor group sign-off."

**tc39-how-we-work**
URL: https://github.com/tc39/how-we-work/blob/main/champion.md ; https://tc39.es/process-document/
Accessed: 2026-08-29
Quote: "Proposals at Stage 1 and beyond must be owned by the committee... any discussion, idea, or proposal not yet submitted formally is considered a strawperson (Stage 0)."

**pep0001**
URL: https://peps.python.org/pep-0001/
Accessed: 2026-08-29
Quote: "Ideas category of the Python Discourse ... meant to save the potential author time" before drafting a formal PEP.

**gh-projects-v2-fields**
URL: https://github.com/orgs/community/discussions/10853
Accessed: 2026-08-29
Quote: request for "custom columns/fields... accessible outside their own project" so a public board and internal board don't need duplicate fields.

**gh-issue-fields**
URL: https://github.com/orgs/community/discussions/175366 ; https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization
Accessed: 2026-08-29
Quote: "only fields with Public visibility are available in public and internal projects, while fields set to Organization only are not displayed."

**synclinear**
URL: https://github.com/calcom/synclinear.com/issues/152 ; https://linear.app/integrations/github ; https://linear.app/changelog/2023-12-14-github-issues-sync
Accessed: 2026-08-29
Quote: "add the label 'Public' to Linear tickets to sync them with GitHub... for community issues you use the label 'linear' on GitHub to send tickets to Linear."

**w3c-github-labels**
URL: https://www.w3.org/guide/github/issue-metadata.html
Accessed: 2026-08-29
Quote: "WR-open: Comment received, not yet processed by the WG; WR-pending: Discussed but pending WG resolution; WR-resolved."

**w3c-issue-labels-wiki**
URL: https://www.w3.org/wiki/Issue_labels ; i18n label docs referenced via public-i18n-archive
Accessed: 2026-08-29
Quote: "i18n-tracker ... Issues with this label don't need to be resolved to the satisfaction of the i18n Group before a transition." / "i18n-needs-resolution ... expects it to be resolved to their satisfaction before a transition."

**csswg-contributing**
URL: https://github.com/w3c/csswg-drafts/blob/main/CONTRIBUTING.md
Accessed: 2026-08-29
Quote: "when issues need WG discussion or approval, WG members should label the issue 'Agenda+' to bring it to the Working Group's attention."

**nodejs-tsc-charter**
URL: https://github.com/nodejs/TSC/blob/main/TSC-Charter.md
Accessed: 2026-08-29
Quote: "the proposal passes if, after 72 hours, there are two or more TSC approvals and no TSC opposition" / "a collaborator may apply the tsc-agenda label" if async consensus fails.

**mlflow-issue-triage**
URL: https://github.com/mlflow/mlflow/blob/master/ISSUE_TRIAGE.rst
Accessed: 2026-08-29
Quote: "needs design: This feature is large or tricky enough that we think it warrants a design doc and review before someone begins implementation."

**nomad-issue-labels**
URL: https://github.com/hashicorp/nomad/blob/v1.2.2/contributing/issue-labels.md
Accessed: 2026-08-29
Quote: "stage/needs-discussion | This topic needs discussion with the larger Nomad maintainers group before committing to it... This doesn't signify that design needs to be discussed."

**rice-critique**
URL: https://michaelgoitein.com/the-one-reason-why-prioritization-frameworks-will-never-work-and-what-to-do-instead/ ; https://swkhan.medium.com/why-you-should-avoid-prioritization-frameworks-779a61c0087
Accessed: 2026-08-29
Quote: "RICE and MoSCoW don't make prioritization objective — they just make your subjectivity look mathematical."

## SYNTHESIS

**Comparison of the four maturity-ladder models.**

| | Ladder shape | Pre-formal home | Who can advance | Gate mechanics |
|---|---|---|---|---|
| Kubernetes KEP | 7 flat states (no ordinal ladder — a state machine, not stages): provisional → implementable → implemented, with deferred/rejected/withdrawn/replaced as side-exits | SIG meetings / Slack (not on GitHub) | Owning SIG + approvers | Two orthogonal fields: `status` (process state) and `stage` (alpha/beta/stable, release maturity) |
| Rust RFC | 2 formal states (proposed → active) plus a distinct post-acceptance tracking-issue lifecycle | `internals.rust-lang.org` "pre-RFC" threads + Zulip | Any community member (pre-RFC); sub-team (FCP/merge) | 10-day Final Comment Period with no substantial objection; countable but not numbered |
| TC39 | 6 ordinal stages (0, 1, 2, 2.7, 3, 4), the only true escalating epistemic ladder of the four | Stage 0 itself (strawperson) — inside the same system, just the lowest rung | Registered delegates only, from Stage 0 onward | Committee consensus vote at each transition; Stage 4 additionally requires 2 independent shipping implementations + Test262 |
| Python PEP | 8-9 named statuses, mostly terminal/parallel rather than sequential (Draft/Accepted/Provisional/Deferred/Rejected/Withdrawn/Final/Active/Superseded) | Python Discourse "Ideas" category | Any community member for Draft; core devs/steering council for Accepted | BDFL-delegate or Steering Council sign-off; Provisional is a real-world-feedback probation period unique to PEP among the four |

The load-bearing distinction is **where pre-formal, non-actionable discussion lives relative to the tracker**: TC39 is the only one of the four that keeps early-stage ideas *inside* its own numbered system (Stage 0 has zero entrance criteria by design); Kubernetes, Rust, and Python all push undefined ideas to a venue structurally *outside* the tracker (Slack/SIG meetings, internals.rust-lang.org, Discourse) and only admit an item to the tracker once it already has a sponsor/champion. TC39's approach works because delegate-gating (only ~50 registered people can even file Stage 0) substitutes for a location boundary; the other three substitute a location boundary because their contributor pools are unbounded. A four-person team closer to TC39's contributor-count than Kubernetes' is the more apt comparison on headcount, but closer to Rust/Python on openness (anyone, including outsiders at a conference, might raise an item) — so the tension between "which model fits" is real and not resolved by this research; it's reported, not decided, per the instruction not to design.

**On tooling (Q2):** the strongest documented pattern is that every "public issues, private working view" tool has a live drift/duplication failure mode, not a solved one. GitHub's own Projects v2 field-scoping bug went undocumented-workaround for years until an issue-level "Issue Fields" visibility flag shipped in 2026 preview. Linear-GitHub sync (native and third-party) universally implements the split as an explicit opt-in label gate in at least one direction (`Public` label to push out, `linear` label to pull in) rather than true mirroring, and even the native integration restricts comment sync by author role — meaning every real system studied treats full bidirectional parity as a non-goal, not an achieved feature. W3C's `i18n-tracker`/`i18n-needs-resolution` pair is the cleanest small-team-adjacent precedent for a light/heavy dual-label split owned by a *specific reviewing party*, not the general triage flow.

**On prioritization (Q3):** the clearest and most surprising finding is a negative one — no primary source from any studied spec/protocol project used RICE, WSJF, or any multiplicative scoring scheme for design-question prioritization. Every real example found instead uses a small number of named categorical tiers whose meaning is an operational commitment (a cadence of attention, a meeting-admission ticket, a blocking-vs-watching distinction) rather than a computed rank. Kubernetes' priority labels and Rust's P-labels are the most mechanically explicit ("P-critical is raised at every weekly meeting"; "P-low is ignored until someone complains"). CSSWG's `Agenda+` and W3C Social/MathML's single binary "needs resolution" label are the closest fit to "needs-decision vs needs-research vs needs-consensus," but none of the sources split those three into separate labels — the working convention collapses "needs research" and "needs discussion" into one generic pre-decision bucket (MLflow's `needs design` / `needs committer feedback` is the one source that cleanly separates a research-stage label from a decision-stage label). Kubernetes' own dashboards (334-day average wait) are direct evidence that a well-specified label taxonomy does not by itself solve throughput — the corpus's `short-credible-change-processes...` entry's finding that "every countable bar beats prose consensus" holds for *deciding*, but says nothing about *staffing* the deciding, which is the actual bottleneck the Kubernetes data exposes.
