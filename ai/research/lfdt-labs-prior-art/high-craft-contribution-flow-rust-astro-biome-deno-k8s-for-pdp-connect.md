---
title: "Rust, Astro, Biome, Deno, and Kubernetes converge on light CONTRIBUTING + heavy labels/CI + draft-PR-or-hold for WIP, and two of five now require explicit AI-disclosure on PRs"
date: 2026-07-21
topic: lfdt-labs-prior-art
tags: [contributing, pr-template, issue-template, labels, ci-gates, wip, ai-disclosure, dco, cla, owners-files, pdp-connect]
status: draft
sources: [rust-contributing, rustc-dev-guide-contributing, rust-pr-template, rust-easy-labels, rust-rfc-readme, astro-contributing, astro-pr-template, astro-issue-template, astro-labels, astro-discussions, biome-contributing, biome-agentscan-workflow, deno-pr-template, deno-contributing-page, k8s-community-readme, k8s-pr-template, k8s-owners-example, k8s-owners-api-example, k8s-cla-process, k8s-pr-best-practices]
---

<!--
Format reminder (see README.md):
- CLAIMS = only verifiable statements, each tagged [source-slug]. No narrative.
- SOURCES = per slug: URL + Accessed date + optional verbatim quote.
- SYNTHESIS = your interpretation/conclusions. Skippable. No citations here.
Filename = the claim in kebab-case (greppable), under the matching topic/ dir.
Add one line to INDEX.md when you create this.
-->

## CLAIMS

### Rust (rust-lang/rust)

- Rust's top-level `CONTRIBUTING.md` is short and routes elsewhere rather than being the source of truth: it says "The best way to get started is by asking for help in the [#new members] Zulip stream" and "It is recommended that you read and understand the [rustc-dev-guide] before making a contribution" — it does not itself contain the workflow, labels, or RFC process. [rust-contributing]
- The rustc-dev-guide (a separate site/repo, `rustc-dev-guide.rust-lang.org`) is where the actual mechanics live: "create a #t-compiler thread on Zulip to discuss your proposed changes" before large work, file PRs against `main`, run `./x test tidy --bless`, reviewers are auto-assigned via `@rustbot` with manual override via `r? @username`. [rustc-dev-guide-contributing]
- Rust uses a bot-mediated merge queue, not human-merge-button: after a reviewer approves with `r+`, the common pattern is `@bors r+ rollup`, where "rollup" means the change is batched with other low-risk PRs and the bot ("bors", historically; later "homu"/other tooling referenced in the PR template) runs full cross-platform CI before merge. [rustc-dev-guide-contributing] [rust-pr-template]
- Rust's actual PR template (`.github/pull_request_template.md`) is minimal — four lines of HTML-comment guidance about linking a tracking issue and using `r? <reviewer>` to request a specific reviewer — with no user-facing checklist rendered by default. [rust-pr-template]
- Rust's "good first issue" mechanism is a graded label family, not a single tag: `E-easy` ("Experience needed to fix: Not much. Good first issue."), `E-medium`, `E-hard`, `E-mentor` ("This issue has a mentor. Use #t-compiler/help on Zulip for discussion."), `E-help-wanted`, `E-tedious`, `E-needs-design`, `E-needs-mcve`, `E-needs-bisection`, `E-needs-test`, `E-needs-investigation` — confirmed live on the repo via the GitHub labels API as of 2026-07-21. [rust-easy-labels]
- Rust's RFC process (separate repo `rust-lang/rfcs`) is a formal pre-implementation design-consensus gate, reserved for "substantial" changes (e.g. "Any semantic or syntactic change to the language," "Removing language features"); routine bug fixes and docs skip it entirely. Stages: informal pre-RFC feedback (Zulip/forum) → RFC PR against the rfcs repo → sub-team review → Final Comment Period (FCP) requiring "all members of the subteam must sign off," open "for at least 5 business days" (10 calendar days) → merge/close/postpone. [rust-rfc-readme]

### Astro (withastro/astro)

- Astro's `CONTRIBUTING.md` is a monorepo dev-setup + testing manual, not a policy document: pnpm workspaces (`pnpm install` from repo root only), Node `^>=22.12.0`/pnpm `^10.28.0` pinned, package-context separation (`src/core/` = Node runtime, `src/runtime/server/` = Vite SSR, `src/runtime/client/` = browser) enforced so Node-only APIs don't leak into runtime-agnostic code (Cloudflare Workers compatibility requirement). [astro-contributing]
- New contributors are pointed to a third-party generic guide, not an Astro-specific one: "Take a look at https://github.com/firstcontributions/first-contributions for helpful information on contributing." [astro-contributing]
- Astro's actual PR template (`.github/PULL_REQUEST_TEMPLATE.md`) is three sections — `## Changes` (bullet points, before/after screenshots optional, "Don't forget a changeset! Run `pnpm changeset`"), `## Testing` ("DON'T DELETE THIS SECTION! If no tests added, explain why"), `## Docs` ("DON'T DELETE THIS SECTION! If no docs added, explain why") — short, and structurally forces an explicit reason when a normally-expected artifact (test, doc, changeset) is missing rather than silently allowing its absence. [astro-pr-template]
- Astro's only issue template is a single structured form, `01-bug-report.yml` (YAML issue form, not free-text Markdown); there is no separate feature-request template in `.github/ISSUE_TEMPLATE/`. [astro-issue-template]
- Astro's priority/first-issue labels: `good first issue` ("Good for newcomers. If you need additional guidance, feel free to post in #contribute on Discord"), `help wanted`, and a `P1`–`P5` priority ladder (`P5: urgent` = "Fix build-breaking bugs affecting most users, should be released ASAP" down to `P1: chore` = "Doesn't change code behavior"). [astro-labels]
- As of 2026-07-21, `withastro/astro`'s GitHub Discussions feature returns zero discussion categories via the GitHub GraphQL API (`discussionCategories` empty) — Discussions is not active/used on the main repo; community routing instead happens through GitHub Issues (bug-report form) and Discord (`#contribute` channel referenced directly in the `good first issue` label description). [astro-discussions]
- Astro requires a **changeset** (`pnpm exec changeset` / `pnpm changeset`) for any package-affecting change, which becomes both the release-note source and a forcing function that turns "did you mean to ship this?" into a file the PR either has or doesn't — release automation runs off a bot-maintained `[ci] release` PR that core maintainers merge to publish. [astro-contributing] [astro-pr-template]

### Biome (biomejs/biome)

- Biome's `CONTRIBUTING.md` gates PRs on a `just`-driven local pipeline before submission: `just f` (format), `just l` (lint), conditional codegen (`just gen-analyzer` for linter changes, `just gen-bindings` for workspace changes), and `just ready` as the full pre-PR check; commit messages must follow Conventional Commits; user-facing changes require a changeset via `just new-changeset`. [biome-contributing]
- Biome branch-targets by change type: bugfixes and nursery-rule work target `main`; rule promotions and other user-affecting features target a separate `next` branch — i.e. the branching model itself encodes a stability/maturity gate, not just a merge-queue convention. [biome-contributing]
- **Biome explicitly requires AI-assistance disclosure in every PR**, with an enforced specificity bar, not a checkbox: "If you are using any kind of AI assistance to contribute to Biome, it must be disclosed in the pull request," giving the example phrasing "This PR was written primarily by Claude Code," and separately states "Please do not use AI to write pull request descriptions or contributor communication for this project." [biome-contributing]
- Biome runs an automated GitHub Action, `AgentScan` (`.github/workflows/agent_scan.yml`, using `MatteoGabriele/agentscan-action`), triggered on `pull_request_target: [opened, reopened]` and `issues: [opened]`, with a guard excluding bot-authored PRs (`github.event.pull_request.user.type != 'Bot'`) — i.e. every new human-opened issue and PR is automatically scanned, presumably for low-effort/AI-slop signal, as a standing CI gate rather than a manual maintainer judgment call. [biome-agentscan-workflow]
- Biome's community-tone line in CONTRIBUTING.md doubles as a slop-deterrent norm-setter: "Remember that we are doing this project on our own time. We are humans: we like support, and we expect kindness :)" — paired with the AI-disclosure rule, the message is "contribute like a person talking to people," not "submit polished-looking output." [biome-contributing]

### Deno (denoland/deno)

- Deno's `.github/PULL_REQUEST_TEMPLATE.md` opens with an AI-disclosure requirement stated as a rejection condition, stronger in tone than Biome's: "IMPORTANT: If you used AI tools (e.g. Copilot, ChatGPT, Claude, Cursor, etc.) to help write this PR, you MUST disclose it in the PR description. PRs will be rejected if there is suspicion of undisclosed AI usage." The same warning repeats as checklist item 6. [deno-pr-template]
- Deno's PR template is an 8-item HTML-comment checklist covering: descriptive Conventional-Commits-style title (with explicit good/bad examples, e.g. good: `fix(ext/net): fix race condition in TCP listener`; bad: `fix #7123`), a linked issue, test coverage, `./x fmt` passing, `./x lint` passing, AI disclosure, and item 7 is the WIP mechanism: **"Open as a draft PR if your work is still in progress. The CI won't run all steps, but you can add '[ci]' to a commit message to force it to."** Item 8 covers opting into benchmark CI via a `ci-bench` label. [deno-pr-template]
- Deno's contributing guidance (hosted at `docs.deno.com/runtime/contributing/`, referenced from the PR template) separates repos by technical depth for routing purposes — e.g. flagging `rusty_v8` as "Very technical and low-level" — so a newcomer self-selects which of Deno's ~8 repos matches their skill level rather than being funneled into one monolithic contributing doc. [deno-contributing-page]
- Deno's code-of-conduct expectation is explicitly borrowed rather than authored fresh: "following Rust's code of conduct" is the stated bar, and the guide discourages performance regressions and encourages discussing significant features before implementation "to avoid rejected work." [deno-contributing-page]

### Kubernetes (kubernetes/community)

- The `kubernetes/community` repo's contributor guide states its own scope explicitly: "This document is the single source of truth for how to contribute to the code base" — i.e. Kubernetes centralizes contribution process documentation in a dedicated governance repo separate from the code repos themselves, rather than duplicating a CONTRIBUTING.md per code repo. [k8s-community-readme]
- Kubernetes gates code contribution on a **CLA (Contributor License Agreement)**, administered by the Linux Foundation's EasyCLA via CNCF — not a DCO — with a six-step bot-mediated flow: open a PR → `linux-foundation-easycla` bot responds with a signing link → corporate contributors link a company email → grant EasyCLA read-only GitHub access → choose Individual or Corporate Contributor → complete via DocuSign → comment `/easycla` to re-check status. "Kubernetes can only accept original source code from CLA signatories" (excepting `third_party`/`vendor` dirs). [k8s-cla-process]
- Kubernetes' `OWNERS` files are structured YAML with per-path `filters` (regex-keyed) distinguishing `reviewers` from `approvers`, plus `emeritus_approvers` (a durable historical-credit list) and per-path `labels` that auto-apply on matching file changes — e.g. the root `kubernetes/kubernetes` `OWNERS` auto-labels any `go.mod`/`go.sum` change `area/dependency` and routes it to `dep-approvers`/`dep-reviewers`, and any `metrics.go` change gets `sig/instrumentation`. A sub-package `OWNERS` can set `no_parent_owners: true` to fully override inheritance from the parent directory's file. [k8s-owners-example] [k8s-owners-api-example]
- Kubernetes' PR template requires a `/kind <bug|feature|cleanup|...>` self-classification comment-command, a linked issue (or explicit `N/A`), and a **mandatory structured release-note block** (```release-note ... ``` fenced, or the literal string `NONE`) — the release-note requirement is enforced by template structure, not by a separate manual changelog step. [k8s-pr-template]
- Kubernetes' WIP mechanism is comment-commands plus title convention, not GitHub's native draft-PR feature: `/hold` and `/hold cancel` toggle a `do-not-merge/hold` label; adding/removing a `WIP`/`[WIP]` prefix in the PR title toggles `do-not-merge/work-in-progress` (both bot-applied). "While either label is present, your pull request will not be considered for merging." Fast-review guidance separately emphasizes small, single-purpose PRs: "Small commits and small pull requests get reviewed faster and are more likely to be correct than big ones." [k8s-pr-best-practices]

## SOURCES

**rust-contributing**
URL: https://raw.githubusercontent.com/rust-lang/rust/master/CONTRIBUTING.md
Accessed: 2026-07-21
Quote: "The best way to get started is by asking for help in the #new members Zulip stream." / "It is recommended that you read and understand the rustc-dev-guide before making a contribution."

**rustc-dev-guide-contributing**
URL: https://rustc-dev-guide.rust-lang.org/contributing.html
Accessed: 2026-07-21
Quote: "create a #t-compiler thread on Zulip to discuss your proposed changes." / "All pull requests should be filed against the `main` branch, unless you know for sure that you should target a different branch." / "@bors r+ rollup"

**rust-pr-template**
URL: https://github.com/rust-lang/rust/blob/master/.github/pull_request_template.md (fetched via `gh api repos/rust-lang/rust/contents/.github/pull_request_template.md`)
Accessed: 2026-07-21
Quote: "This PR will get automatically assigned to a reviewer. In case you would like a specific user to review your work, you can assign it to them by using `r? <reviewer name>`"

**rust-easy-labels**
URL: https://api.github.com/repos/rust-lang/rust/labels (via `gh api repos/rust-lang/rust/labels --paginate`)
Accessed: 2026-07-21
Quote: `E-easy` — "Call for participation: Easy difficulty. Experience needed to fix: Not much. Good first issue." `E-mentor` — "Call for participation: This issue has a mentor. Use #t-compiler/help on Zulip for discussion."

**rust-rfc-readme**
URL: https://github.com/rust-lang/rfcs/blob/master/README.md
Accessed: 2026-07-21
Quote: "all members of the subteam must sign off" / FCP "lasts ten calendar days, so that it is open for at least 5 business days"

**astro-contributing**
URL: https://raw.githubusercontent.com/withastro/astro/main/CONTRIBUTING.md
Accessed: 2026-07-21
Quote: "Astro uses pnpm workspaces, so you should always run `pnpm install` from the top-level project directory." / "Take a look at https://github.com/firstcontributions/first-contributions for helpful information on contributing."

**astro-pr-template**
URL: https://github.com/withastro/astro/blob/main/.github/PULL_REQUEST_TEMPLATE.md (via `gh api repos/withastro/astro/contents/.github/PULL_REQUEST_TEMPLATE.md`)
Accessed: 2026-07-21
Quote: "Don't forget a changeset! Run `pnpm changeset`." / "DON'T DELETE THIS SECTION! If no tests added, explain why." / "DON'T DELETE THIS SECTION! If no docs added, explain why."

**astro-issue-template**
URL: https://github.com/withastro/astro/tree/main/.github/ISSUE_TEMPLATE (via `gh api repos/withastro/astro/contents/.github/ISSUE_TEMPLATE`)
Accessed: 2026-07-21
Quote: Directory listing = `01-bug-report.yml`, `config.yml` only.

**astro-labels**
URL: https://api.github.com/repos/withastro/astro/labels (via `gh api repos/withastro/astro/labels --paginate`)
Accessed: 2026-07-21
Quote: `good first issue` — "Good for newcomers. If you need additional guidance, feel free to post in #contribute on Discord" / `P5: urgent` — "Fix build-breaking bugs affecting most users, should be released ASAP (priority)"

**astro-discussions**
URL: GitHub GraphQL API, `repository(owner:"withastro", name:"astro") { discussionCategories }`
Accessed: 2026-07-21
Quote: `{"data":{"repository":{"discussionCategories":{"nodes":[]}}}}` — empty category list.

**biome-contributing**
URL: https://raw.githubusercontent.com/biomejs/biome/main/CONTRIBUTING.md
Accessed: 2026-07-21
Quote: "If you are using any kind of AI assistance to contribute to Biome, it must be disclosed in the pull request." / "Please do not use AI to write pull request descriptions or contributor communication for this project." / "Remember that we are doing this project on our own time. We are humans: we like support, and we expect kindness :)"

**biome-agentscan-workflow**
URL: https://github.com/biomejs/biome/blob/main/.github/workflows/agent_scan.yml (via `gh api repos/biomejs/biome/contents/.github/workflows/agent_scan.yml`)
Accessed: 2026-07-21
Quote: full workflow — `on: pull_request_target: {types: [opened, reopened]}, issues: {types: [opened]}` ... `if: github.event_name != 'pull_request_target' || github.event.pull_request.user.type != 'Bot'` ... `uses: MatteoGabriele/agentscan-action@...`

**deno-pr-template**
URL: https://github.com/denoland/deno/blob/main/.github/PULL_REQUEST_TEMPLATE.md (via `gh api repos/denoland/deno/contents/.github/PULL_REQUEST_TEMPLATE.md`)
Accessed: 2026-07-21
Quote: "IMPORTANT: If you used AI tools (e.g. Copilot, ChatGPT, Claude, Cursor, etc.) to help write this PR, you MUST disclose it in the PR description. PRs will be rejected if there is suspicion of undisclosed AI usage." / "Open as a draft PR if your work is still in progress. The CI won't run all steps, but you can add '[ci]' to a commit message to force it to."

**deno-contributing-page**
URL: https://docs.deno.com/runtime/contributing/
Accessed: 2026-07-21
Quote: `rusty_v8` described as "Very technical and low-level"; code of conduct stated as "following Rust's code of conduct."

**k8s-community-readme**
URL: https://raw.githubusercontent.com/kubernetes/community/master/contributors/guide/README.md
Accessed: 2026-07-21
Quote: "This document is the single source of truth for how to contribute to the code base."

**k8s-pr-template**
URL: https://github.com/kubernetes/kubernetes/blob/master/.github/PULL_REQUEST_TEMPLATE.md (via `gh api repos/kubernetes/kubernetes/contents/.github/PULL_REQUEST_TEMPLATE.md`)
Accessed: 2026-07-21
Quote: "If the PR is unfinished, see how to mark it: https://git.k8s.io/community/contributors/guide/pull-requests.md#marking-unfinished-pull-requests" / mandatory ` ```release-note ... ``` ` fenced block.

**k8s-owners-example**
URL: https://github.com/kubernetes/kubernetes/blob/master/OWNERS (via `gh api repos/kubernetes/kubernetes/contents/OWNERS`)
Accessed: 2026-07-21
Quote: root `OWNERS` filters `"go\\.(mod|sum|work|work\\.sum)$"` → `approvers: [dep-approvers]`, `labels: [area/dependency]`; `"metrics\\.go$"` → `labels: [sig/instrumentation]`.

**k8s-owners-api-example**
URL: https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/api/OWNERS (via `gh api repos/kubernetes/kubernetes/contents/staging/src/k8s.io/api/OWNERS`)
Accessed: 2026-07-21
Quote: "options: no_parent_owners: true" — sub-path OWNERS file disabling inheritance from parent.

**k8s-cla-process**
URL: https://github.com/kubernetes/community/blob/master/CLA.md
Accessed: 2026-07-21
Quote: "Kubernetes can only accept original source code from CLA signatories." Six-step EasyCLA/DocuSign flow administered via CNCF/Linux Foundation.

**k8s-pr-best-practices**
URL: https://raw.githubusercontent.com/kubernetes/community/master/contributors/guide/pull-requests.md
Accessed: 2026-07-21
Quote: "The GitHub robots will add and remove the `do-not-merge/hold` label as you use the comment commands and the `do-not-merge/work-in-progress` label as you edit your title." / "While either label is present, your pull request will not be considered for merging." / "Small commits and small pull requests get reviewed faster and are more likely to be correct than big ones."

## SYNTHESIS

**The pattern across all five, regardless of governance weight.** CONTRIBUTING.md itself is never the quality mechanism — in every project studied it is short and mostly a *router* (to a dev guide, to Discord, to a separate governance repo, to `just`/`x` task-runner commands). The actual bar is enforced by three things living outside prose: (1) a **PR template that forces an explicit answer**, not a silent default, for the artifacts that are easy to skip (tests, docs, changeset, release-note, AI disclosure); (2) **CI gates that run the same commands the template tells you to run locally** (`./x fmt`/`./x lint` for Deno, `just f`/`just l`/`just ready` for Biome, `x test tidy --bless` for Rust) so there's no gap between "what the doc says" and "what's actually checked"; (3) a **label taxonomy that does the triage work a human would otherwise have to do in every issue thread** (Rust's `E-easy`/`E-mentor` graded-difficulty family, Astro's `P1`–`P5` + `good first issue`, Kubernetes' path-scoped auto-labels from `OWNERS`).

**The AI-disclosure finding is the most directly load-bearing one for the "AI-slop optics" worry.** Two of five projects — Biome and Deno, both modern (2023+), both high-craft, both intentionally welcoming — now have an *explicit, prominent, rejection-backed* AI-disclosure requirement baked into the PR template itself, not a CONTRIBUTING.md footnote:
- Deno: "PRs will be rejected if there is suspicion of undisclosed AI usage," stated twice in the template (banner + checklist item 6).
- Biome: requires disclosure with specificity ("This PR was written primarily by Claude Code"), separately bans AI-written PR *descriptions/communication* even when AI wrote the code, and backs it with a standing CI bot (`AgentScan`) that scans every new issue and PR automatically.

This is strong, current (2026) prior art that the *problem PDP-Connect is worried about is already a solved, normalized pattern* in exactly the kind of high-craft young project it should emulate — not something to route around with vague "keep it clean" language. The mechanism that works is: (a) require disclosure in the template with a concrete example phrasing so contributors know what compliance looks like, (b) separately gate *quality*, not *authorship* — none of these projects reject AI-assisted code on principle, they reject undisclosed AI assistance and AI-written human communication (PR descriptions, issue text) specifically, because that's the part that reads as slop. Biome's automated scanner shows this can be partially mechanized rather than resting entirely on maintainer vigilance.

**WIP handling: draft PR is now the default answer, /hold is the fallback for process-heavy orgs.** Deno's template explicitly names GitHub draft PRs as the WIP mechanism ("Open as a draft PR if your work is still in progress"), and ties it to a real CI behavior difference (draft = reduced CI, `[ci]` in commit message force-runs full suite). Kubernetes, being older and pre-dating GitHub draft PRs as a mature feature, uses bot-driven `/hold` + `WIP`-prefix-in-title instead — heavier, more explicit, arguably more robust to a large bot-mediated merge-queue system, but strictly more moving parts than "click Draft PR." For a young lab, Deno's answer (draft PR + a documented reduced-CI convention) is the right-sized one; Kubernetes' `/hold` comment-command system is solving a problem (bot-mediated queue coordination across dozens of SIGs) PDP-Connect doesn't have yet.

**Rust's split between CONTRIBUTING.md (light) and rustc-dev-guide (heavy) is the scaling pattern to imitate structurally, not textually.** The insight worth taking is the *separation of concerns*, not the specific weight: a top-level CONTRIBUTING.md that's a 30-second router (where to ask, what to read first) plus a deeper, versioned, separately-maintained guide for anyone going past a first PR. This scales down cleanly — PDP-Connect doesn't need a `rustc-dev-guide`-sized doc, but it should resist the temptation to cram architecture explanation into CONTRIBUTING.md itself; that's a `docs/` or dev-guide problem, and keeping CONTRIBUTING.md short is itself part of what makes Rust's onboarding feel non-intimidating despite the project's enormous actual complexity.

**Kubernetes' machinery is the "worth copying vs overkill" line drawn sharply.** Worth copying even for a young lab: **OWNERS-style path-scoped auto-labeling** (Kubernetes' `OWNERS` regex-filter → auto-`labels` pattern is a cheap, mechanical way to route a PR touching `packages/data-connectors/heb/` to the right reviewer and label without a human triaging every PR) and the **mandatory structured release-note block** (forces "does this need a changelog entry" to be answered inline, same spirit as Astro's changeset requirement). Overkill for PDP-Connect's stage: CLA/EasyCLA (a DCO sign-off, which LFDT already mandates per prior corpus entries on LFDT governance, is the lighter-weight equivalent and is already the right choice — don't add a second legal gate); the `/kind`+`/hold` comment-command bot layer (solves multi-SIG scale coordination PDP-Connect doesn't have); and a dedicated `kubernetes/community`-style separate governance repo (Rust's dev-guide split is the same idea at a size that fits a young lab better — one extra doc, not an entire second repo with its own OWNERS).

**Concrete recommendation for PDP-Connect (github.com/PDP-Connect/{pdpp,data-connect,data-connectors}), right-sized for a young lab:**

1. **CONTRIBUTING.md** — keep it under ~1 page, structured like Rust's: (a) where to ask before starting (a Discussions category or a labeled "question" issue type — Astro's Discord-channel-in-label-description pattern is a cheap version of this if PDP-Connect doesn't want to stand up Discord), (b) link out to a `docs/` dev guide for anything architectural, (c) the exact local commands CI will also run (mirrors Deno/Biome's `./x fmt && ./x lint` pattern — whatever pdpp's `pnpm` equivalents are), (d) one explicit line on AI-assistance disclosure modeled on Deno/Biome's wording, since this directly answers the owner's slop-optics worry with proven, current (2026) prior art rather than an invented policy.
2. **PR template** — three to five sections max, each with a "must explain if skipped" instruction (Astro's `## Changes` / `## Testing` / `## Docs` pattern is the right size): what changed, how it was tested (or why not), docs impact (or why not), and an AI-disclosure line up top (Deno's banner style — short, unmissable, states the consequence).
3. **Issue templates** — one structured bug-report YAML form (Astro's model: a single well-designed form beats three loosely-maintained Markdown templates) plus a `config.yml` that points elsewhere for questions (Discussions or Discord) rather than accepting them as issues.
4. **Labels** — a graded difficulty family for newcomers (`good first issue` + a `help wanted`, Astro-style, is sufficient at this scale; Rust's full `E-*` ladder is more than needed yet) and a small priority ladder (3–4 levels, not Astro's full P1–P5, is plenty for a young connector-count). If/when `data-connectors` grows enough per-connector maintainers, borrow Kubernetes' `OWNERS` path-filter-to-label pattern to auto-route PRs by connector directory — cheap to add later, no need to build it now.
5. **CI gates** — enforce exactly what CONTRIBUTING.md tells contributors to run locally (format, lint, typecheck, test) as required checks; add nothing PDP-Connect doesn't already run in CI today.
6. **WIP handling** — standardize on GitHub draft PRs (Deno's model), stated explicitly in CONTRIBUTING.md/PR template: draft = "still in progress, don't review yet," ready-for-review = "please look." This directly answers the "WIP optics" half of the owner's worry with zero new tooling — it's a checkbox GitHub already provides, not a bot to build.
7. **DCO, not CLA** — already the LFDT-standard choice per existing corpus entries; Kubernetes' CLA/EasyCLA is the heavier alternative used by a project with corporate-contribution-liability concerns PDP-Connect doesn't need to solve at this stage.
