# Research Recovery Manifest — `docs/research/` (deleted directory audit)

Audit of all 266 unique paths that ever existed under `docs/research/` across the full
history of both remotes (`pdp` = github.com/PDP-Connect/pdpp, `origin` =
github.com/vana-com/pdpp-archive). For each path this records: whether it is still safe
somewhere else (live on a branch tip, or genuinely migrated into the
`~/code/dotfiles/ai/research/` corpus), or whether its exact byte content has been
recovered into `local/research/recovered/<path-with-docs/research/-prefix-stripped>`.

Three deletion events account for all but 15 of the 237 non-bucket-1 paths:

- **`766f4da2ecc7d139d64f5ab28d60c28aed162cfa`** (origin) — "chore(curation): execute LFDT
  disposition manifest — remove archived/deleted material." Deletes 143 files. The commit's
  own message discloses these were held back from the dotfiles migration sweep — i.e. no
  reusable extraction was made. Individually verified (basename + content sweep against the
  full dotfiles corpus): none found. All 143 are RECOVERED.
- **`aff99c9c863e9418d3d454e42a68b845796c5f8e`** (origin) — "chore(corpus): migrate half-A
  reusable research to dotfiles corpus." Deletes 33 `docs/research/*` files (of 55 total
  candidate files touched, the rest under `design-notes/`/`docs/`). Each file individually
  verified against its claimed dotfiles destination by comparing specific claims/sources, not
  just topic. 30 confirmed genuine migrations, 1 substance-fold into a sibling extract
  (recovered as a safety net anyway), 2 have no genuine dotfiles counterpart and are RECOVERED.
- **`a39ff289f13b47a1de2b1189549b1159965f7832`** (origin) — "chore(corpus): migrate p2b
  reusable research to dotfiles corpus." Deletes 53 `docs/research/*` files. Same
  individual-verification method, re-audited after an initial pass under-verified 4 files (see
  "Post-hoc correction" below). 48 confirmed genuine migrations (including 2 corrections to
  the commit's own grouping — `slvp-connector-health-priorart-2026-06-15.md` and
  `owner-console-recovery-and-liveness-prior-art-2026-06-18.md` had been cross-matched to each
  other's dotfiles sibling by shared topic; the actual source_session/claims match was the
  other way around — corrected here), 1 substance-fold (recovered anyway), 4 have no genuine
  dotfiles counterpart and are RECOVERED.

The remaining paths are either alive at `pdp/main` tip (bucket 1, already mirrored to
`local/research/`), alive on a non-main branch on `pdp` or `origin` (still recovered as a
safety net per instructions), or were never touched by any of the three bucket commits and
were individually traced to their own add/delete history.

### Post-hoc correction (owner-run spot-check after first draft)

The first draft of this manifest marked 4 files RECOVERED-only under the `a39ff289f13b` (p2b)
bucket that in fact have genuine, verified dotfiles migrations — a follow-up audit re-checked
every file in the "no dotfiles match found" set with direct content/source_session comparison
and found these 4 false negatives (title-level dotfiles search missed them because the
destination file was retitled around a different framing angle from the same research
session):

- `slvp-ideal-connection-materialization-2026-06-14.md` -> actually migrated to
  `api-contract-design/connection-objects-are-created-by-an-explicit-step-never-as-a-side-effect-of-a-read.md`
  (same `source_session 019d3a01...`, verbatim-overlapping Plaid/Stripe/Nango/Merge/RFC-7231
  claims). Corrected to MIGRATED-DOTFILES.
- `slvp-ideal-connection-reactivation-2026-06-14.md` -> actually migrated to
  `api-contract-design/platforms-repair-a-broken-connection-in-place-preserving-identity-and-history-not-by-recreating-it.md`
  (same session, same `LOGIN_REPAIRED`/`PENDING_EXPIRATION` specifics). Corrected to
  MIGRATED-DOTFILES.
- `explore-unified-personal-timeline-validation-2026-06-19.md` -> actually migrated to
  `data-explorer-ux/personal-data-tools-default-to-a-unified-cross-source-day-grouped-timeline-as-primary-surface.md`
  (same `source_session 019dbc80...`, identical Google Timeline/Rewind/Gyroscope/Daylio/Day One
  example set and verdicts). Corrected to MIGRATED-DOTFILES.
- `explore-visual-feel-prior-art-2026-06-22.md` -> actually migrated to
  `data-explorer-ux/slvp-record-feed-visual-craft-content-first-rows-sans-with-tabular-nums-load-point-feedback-unified-facet-query.md`
  (same `source_session 019d45f8...`, identical Linear/Primer/Sentry/Stripe/Airtable row-anatomy
  and tabular-nums findings). Corrected to MIGRATED-DOTFILES.

All 4 already-recovered copies under `local/research/recovered/` were **left in place**
(never deleted) -- a confirmed dotfiles migration does not make the git-history recovery
wrong to keep; it is redundant-but-harmless insurance, consistent with the zero-deletion
policy applied throughout this audit. The remaining files in the original "no genuine match"
sets for both buckets (`ri-owner-tmux-live-orchestration-2026-06-15.md`,
`slvp-connector-agency-and-silence-2026-06-15.md`,
`slvp-ideal-connector-self-service-setup-2026-06-14.md`,
`sdk-and-ui-seams-prior-art-2026-06-11.md`,
`explore-search-result-set-model-validation-2026-06-19.md`,
`connector-setup-repair-routing-prior-art-2026-07-01.md`, and others) were independently
re-checked against the full dotfiles corpus and confirmed to have no genuine counterpart --
they remain RECOVERED.

## Addendum: 19 paths missed by the original 247-path scrape

A second owner-run integrity check re-derived the full add/delete path list directly from
`git log --all --diff-filter=AD --glob='refs/remotes/pdp/*' --glob='refs/remotes/origin/*' --
'docs/research/*'` and diffed it against this manifest's 247 rows. It found 19 real paths the
original scratch-file scrape (`.audit-all-paths.txt`, generated earlier in the same session)
never captured -- all are legitimate `docs/research/*` files added by commits dated
2026-06-15 through 2026-08-07, sitting on topic branches that were never merged to `pdp/main`
and never deleted anywhere. None of the three commits audited above (`766f4da2e`, `aff99c9c8`,
`a39ff289f`) touch any of these 19 -- they were simply outside the original scrape's window.

All 19 have **zero delete events** on either remote (verified individually) -- they are not
lost, just fragile (alive only on a non-main branch, same risk class as the 5
`ALIVE-ON-BRANCH` files already in the table above). Byte-exact copies of all 19 were written
to `local/research/recovered/` as a safety net. Three of them
(`INDEX.md`, `human-ai-collaborative-slide-deck-editing-2026-08-05.md`,
`spec-register-calibration-2026-08-04.md`) were also found to already exist, byte-identical,
as untracked files directly in the top-level checkout's own `docs/research/` (a different,
unrelated directory from this worktree's now-deleted one) -- diffed and confirmed identical to
the recovered copies, so they carry a doubly-safe disposition.

| Original path | Disposition | Surviving location | Source commit |
|---|---|---|---|
| `docs/research/adaptive-backlog-recovery-scheduler-prior-art-2026-07-16.md` | ALIVE-ON-BRANCH-owner/adaptive-recovery-coordinator-0716+RECOVERED | local/research/recovered/adaptive-backlog-recovery-scheduler-prior-art-2026-07-16.md | `5141b387f` |
| `docs/research/b-contract-inventory-2026-07-01.json` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/b-contract-inventory-2026-07-01.json | `924832bae` |
| `docs/research/b-contract-inventory-2026-07-01.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/b-contract-inventory-2026-07-01.md | `924832bae` |
| `docs/research/bug-hunt-pdpp-2026-07-03.md` | ALIVE-ON-BRANCH-waspflow/sp2-bughunt+RECOVERED | local/research/recovered/bug-hunt-pdpp-2026-07-03.md | `c89ee2dd4` |
| `docs/research/cleanup-audit-2026-07-03.md` | ALIVE-ON-BRANCH-waspflow/sp2-cleanup+RECOVERED | local/research/recovered/cleanup-audit-2026-07-03.md | `903f23a06` |
| `docs/research/docs-audit-2026-07-03.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/docs-audit-2026-07-03.md | `d6a13f240` |
| `docs/research/human-ai-collaborative-slide-deck-editing-2026-08-05.md` | ALIVE-ON-BRANCH-waspflow/connector-netflix-export-0807-revise+RECOVERED+ALREADY-IN-TOPLEVEL-WORKTREE | local/research/recovered/human-ai-collaborative-slide-deck-editing-2026-08-05.md (also byte-identical at top-level checkout's docs/research/) | `026a30848` |
| `docs/research/INDEX.md` | ALIVE-ON-BRANCH-waspflow/connector-netflix-export-0807-revise+RECOVERED+ALREADY-IN-TOPLEVEL-WORKTREE | local/research/recovered/INDEX.md (also byte-identical at top-level checkout's docs/research/) | `026a30848` |
| `docs/research/lexical-search-freshness-prior-art-2026-06-15.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/lexical-search-freshness-prior-art-2026-06-15.md | `12ab374d4` |
| `docs/research/lexical-search-ranking-recency-prior-art-2026-06-15.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/lexical-search-ranking-recency-prior-art-2026-06-15.md | `12ab374d4` |
| `docs/research/open-pr-review-2026-07-03.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/open-pr-review-2026-07-03.md | `18534738c` |
| `docs/research/pdpp-ri-codex-gap-audit-2026-07-03.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/pdpp-ri-codex-gap-audit-2026-07-03.md | `5ab30041d` |
| `docs/research/pdpp-ri-owner-problem-closeout-ledger-2026-07-03.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/pdpp-ri-owner-problem-closeout-ledger-2026-07-03.md | `5ab30041d` |
| `docs/research/personal-data-search-ranking-norms-2026-06-15.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/personal-data-search-ranking-norms-2026-06-15.md | `12ab374d4` |
| `docs/research/remote-surface-session-resource-prior-art-2026-07-16.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/remote-surface-session-resource-prior-art-2026-07-16.md | `99e50ef14` |
| `docs/research/search-fanin-truncation-bm25-parity-2026-06-15.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/search-fanin-truncation-bm25-parity-2026-06-15.md | `12ab374d4` |
| `docs/research/security-audit-2026-07-03.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/security-audit-2026-07-03.md | `07c8946b6` |
| `docs/research/spec-register-calibration-2026-08-04.md` | ALIVE-ON-BRANCH-waspflow/connector-netflix-export-0807-revise+RECOVERED+ALREADY-IN-TOPLEVEL-WORKTREE | local/research/recovered/spec-register-calibration-2026-08-04.md (also byte-identical at top-level checkout's docs/research/) | `026a30848` |
| `docs/research/standards-site-ia-prior-art-2026-06-24.md` | ALIVE-ON-BRANCH(unmerged)+RECOVERED | local/research/recovered/standards-site-ia-prior-art-2026-06-24.md | `696dbd618` |

"ALIVE-ON-BRANCH(unmerged)" means the commit exists on at least one non-main branch tip on
`pdp` or `origin` (confirmed via `git branch -a --contains <sha>` for named branches, or
presence in `--all` history for the two not resolving to a currently-named local branch ref)
and has never been deleted; the exact branch name was not pinned down for every row but the
liveness and zero-deletion facts are confirmed for all 19.

These 19 bring the true total of paths ever touched under `docs/research/` across both
remotes to **266**, not 247. The summary counts below are updated to reflect all 266.

## Disposition legend

- **LIVE-ON-MAIN** — present at `pdp/main` tip under `docs/research/`; already mirrored at
  `local/research/<basename>` (untouched by this audit).
- **ALIVE-ON-BRANCH-\<branch\>+ALREADY-LOCAL** — alive on a named branch AND already mirrored
  under `local/research/` (the `data-act-and-pdpp-2026-08-07.md` case).
- **ALIVE-ON-BRANCH-\<branch\>+RECOVERED** — alive on a named non-main branch on `pdp` or
  `origin`; a fresh byte-exact copy was still written to `local/research/recovered/` per
  instructions (never skip recovery just because a branch is fragile).
- **MIGRATED-DOTFILES** — genuinely gone from every branch tip on both remotes, but its
  reusable substance was confirmed (claim-by-claim, not just by topic) to survive in
  `~/code/dotfiles/ai/research/<path>`. No recovery needed; the PDPP-specific
  wiring/decision/code-reference content that did NOT survive is considered acceptably lost
  (that was the sweep's intent — see the commit messages).
- **RECOVERED+FOLDED-INTO-SIBLING** — the file's topic/some claims survive folded into a
  dotfiles file that is really the extraction of a *different*, closely-related source file
  (a companion/sibling doc in the same research session), so the fold is real but not a
  faithful 1:1 substitute. Recovered as a safety net in addition to noting the fold.
- **RECOVERED** — gone from every branch tip on both remotes and no genuine dotfiles
  migration found (individually verified, not assumed). Exact pre-delete byte content written
  to `local/research/recovered/<relpath>`.

## Table (all 247 paths)

| Original path | Disposition | Surviving location | Source commit | Deleting commit |
|---|---|---|---|---|
| `docs/research/acquisition-coverage-profile-prior-art-2026-06-13.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/agentic-context-design/personal-data-import-tools-scope-dedup-per-acquisition-method-and-treat-partial-coverage-as-first-class.md | — | `aff99c9c863e` |
| `docs/research/acquisition-coverage-profile-slvp-evaluation-2026-06-13.md` | RECOVERED | local/research/recovered/acquisition-coverage-profile-slvp-evaluation-2026-06-13.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/aimd-recovery-tuning-theory-2026-06-12.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/feedback-systems/rate-limiter-recovery-should-be-clocked-by-wall-time-since-last-throttle-not-by-successful-requests.md | — | `aff99c9c863e` |
| `docs/research/amazon-chase-live-gap-status-2026-06-29.md` | RECOVERED | local/research/recovered/amazon-chase-live-gap-status-2026-06-29.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/amazon-detail-hydration-rootcause-2026-06-26.md` | RECOVERED | local/research/recovered/amazon-detail-hydration-rootcause-2026-06-26.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/artifacts/owner-spine-static-secret-setup-2026-06-18/desktop.png` | ALIVE-ON-BRANCH-origin/ci-cost-docker-paths-and-validate-arch+RECOVERED | local/research/recovered/artifacts/owner-spine-static-secret-setup-2026-06-18/desktop.png | `bf4bc6acc4a8` | — |
| `docs/research/artifacts/owner-spine-static-secret-setup-2026-06-18/mobile-390.png` | ALIVE-ON-BRANCH-origin/ci-cost-docker-paths-and-validate-arch+RECOVERED | local/research/recovered/artifacts/owner-spine-static-secret-setup-2026-06-18/mobile-390.png | `bf4bc6acc4a8` | — |
| `docs/research/attribution-split-prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/oauth-mcp-auth/consent-surfaces-separate-verified-from-self-declared-claims-but-rarely-mandate-ui-attribution.md | — | `aff99c9c863e` |
| `docs/research/audit-log-retouch-vs-transition-prior-art-2026-06-12.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/audit-logs-emit-per-state-transition-not-per-retouch-with-attempt-count-in-mutable-state.md | — | `aff99c9c863e` |
| `docs/research/blazing-fast-stack-best-practices-2026-06-17.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/web-performance/nextjs-rsc-postgres-sqlite-node-slowness-maps-to-documented-anti-patterns-not-stack-ceilings.md | — | `aff99c9c863e` |
| `docs/research/brand-package-coverage-audit-2026-06-11.md` | RECOVERED | local/research/recovered/brand-package-coverage-audit-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/chatgpt-connector-batch-endpoint-plan-2026-06-19.md` | RECOVERED | local/research/recovered/chatgpt-connector-batch-endpoint-plan-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/chatgpt-connector-improvement-STEER-2026-06-19.md` | RECOVERED | local/research/recovered/chatgpt-connector-improvement-STEER-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/chatgpt-cooldown-and-gap-drain-diagnosis-2026-06-11.md` | RECOVERED | local/research/recovered/chatgpt-cooldown-and-gap-drain-diagnosis-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/chatgpt-session-reuse-regression-closeout-2026-06-29.md` | RECOVERED | local/research/recovered/chatgpt-session-reuse-regression-closeout-2026-06-29.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/claude-dynamic-workflows-and-ri-owner-delegation-2026-06-19.md` | RECOVERED | local/research/recovered/claude-dynamic-workflows-and-ri-owner-delegation-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/client-rate-governance-prior-art-2026-06-10.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/client-side-rate-governance-uses-three-separable-layers-retry-budget-send-governor-backoff.md | — | `aff99c9c863e` |
| `docs/research/collection-governor-generalization-ideal-2026-06-11.md` | RECOVERED | local/research/recovered/collection-governor-generalization-ideal-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/collection-layer-boundary-note.md` | RECOVERED | local/research/recovered/collection-layer-boundary-note.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/collection-method-matrix.md` | RECOVERED | local/research/recovered/collection-method-matrix.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/collection-prior-art-deep-dive.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/data-collection-frameworks-keep-bounded-pull-primary-and-add-thin-push-profiles-sharing-one-message-format.md | — | `aff99c9c863e` |
| `docs/research/congestion-control-theory-for-http-rate-governor-2026-06-10.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/congestion-control-theory-transfers-to-http-scrapers-as-rate-aimd-with-latency-signal-and-hard-ceiling.md | — | `aff99c9c863e` |
| `docs/research/connect-ai-apps-screenshots-2026-06-14/desktop.jpeg` | ALIVE-ON-BRANCH-origin/chore/preserve-agent-work-20260625+RECOVERED | local/research/recovered/connect-ai-apps-screenshots-2026-06-14/desktop.jpeg | `389ec9800fb1` | — |
| `docs/research/connect-ai-apps-screenshots-2026-06-14/mobile-390.jpeg` | ALIVE-ON-BRANCH-origin/chore/preserve-agent-work-20260625+RECOVERED | local/research/recovered/connect-ai-apps-screenshots-2026-06-14/mobile-390.jpeg | `389ec9800fb1` | — |
| `docs/research/connector-authoring-semantics-prior-art-2026-06-24.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/search-filter-relation-and-display-are-separate-authored-axes-not-inferred-from-string-type.md | — | `aff99c9c863e` |
| `docs/research/connector-config-schema-prior-art-2026-06-05.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/connector-config-separates-secrets-from-options-by-per-field-flag-or-separate-object-with-lenient-warn-on-unknown-keys.md | — | `aff99c9c863e` |
| `docs/research/connector-credential-session-repair-prior-art-2026-07-01.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/credential-and-session-repair-is-a-connection-scoped-lifecycle-that-pauses-retries-not-a-failed-run-detail.md | — | `aff99c9c863e` |
| `docs/research/connector-query-affordance-audit-2026-06-26.md` | RECOVERED | local/research/recovered/connector-query-affordance-audit-2026-06-26.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/connector-query-affordance-authoring-2026-06-26.md` | RECOVERED | local/research/recovered/connector-query-affordance-authoring-2026-06-26.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/connector-residual-classification-2026-07-01.md` | RECOVERED | local/research/recovered/connector-residual-classification-2026-07-01.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/connector-setup-repair-routing-prior-art-2026-07-01.md` | RECOVERED | local/research/recovered/connector-setup-repair-routing-prior-art-2026-07-01.md | `aff99c9c863e^` | `aff99c9c863e` |
| `docs/research/connector-token-staleness-audit-2026-06-11.md` | RECOVERED | local/research/recovered/connector-token-staleness-audit-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/console-instance-branding-config-2026-06-22.md` | RECOVERED | local/research/recovered/console-instance-branding-config-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/control-plane-prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-collection-systems/control-plane-uis-pick-one-dominant-object-a-first-class-event-trace-spine-and-cli-api-parity.md | — | `aff99c9c863e` |
| `docs/research/data-act-and-pdpp-2026-08-07.md` | ALIVE-ON-BRANCH-spec/subject-neutrality-data-act-tombstones+ALREADY-LOCAL | local/research/data-act-and-pdpp-2026-08-07.md | — | — |
| `docs/research/deploy-button-parity-prior-art-2026-06-10.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/self-hosted-projects-avoid-one-click-deploy-buttons-and-curl-bash-security-tradeoffs.md | — | `aff99c9c863e` |
| `docs/research/dti-alignment-notes-2026-03-28.md` | RECOVERED | local/research/recovered/dti-alignment-notes-2026-03-28.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/end-to-end-skeptical-audit-2026-06-13.md` | RECOVERED | local/research/recovered/end-to-end-skeptical-audit-2026-06-13.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/ephemeral-runtime-health-separates-control-plane-capability-from-warm-instance-state-2026-07-16.md` | LIVE-ON-MAIN | pdp/main:docs/research/ephemeral-runtime-health-separates-control-plane-capability-from-warm-instance-state-2026-07-16.md (mirrored at local/research/ephemeral-runtime-health-separates-control-plane-capability-from-warm-instance-state-2026-07-16.md) | — | — |
| `docs/research/explore-burst-order-plus-branding-plan-2026-06-22.md` | RECOVERED | local/research/recovered/explore-burst-order-plus-branding-plan-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-burst-ordering-prior-art-2026-06-22.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/high-volume-chronological-feeds-use-day-grouping-burst-collapse-and-snapshot-cursor-n-new-pill.md | — | `aff99c9c863e` |
| `docs/research/explore-canvas-integration-decision-2026-06-19.md` | RECOVERED | local/research/recovered/explore-canvas-integration-decision-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-chatgpt-three-bugs-2026-06-20.md` | RECOVERED | local/research/recovered/explore-chatgpt-three-bugs-2026-06-20.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-cursor-431-diagnosis-2026-06-20.md` | RECOVERED | local/research/recovered/explore-cursor-431-diagnosis-2026-06-20.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/PR-EXTRACTION.md` | RECOVERED | local/research/recovered/explore-design-cells/PR-EXTRACTION.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/RECIPE.md` | RECOVERED | local/research/recovered/explore-design-cells/RECIPE.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/SCREENSHOT-VALIDATION.md` | RECOVERED | local/research/recovered/explore-design-cells/SCREENSHOT-VALIDATION.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/date-controls/design.md` | RECOVERED | local/research/recovered/explore-design-cells/date-controls/design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/date-controls/harness/base.css` | RECOVERED | local/research/recovered/explore-design-cells/date-controls/harness/base.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/date-controls/harness/components.css` | RECOVERED | local/research/recovered/explore-design-cells/date-controls/harness/components.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/date-controls/harness/index.html` | RECOVERED | local/research/recovered/explore-design-cells/date-controls/harness/index.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/date-controls/prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/date-range-controls-merge-presets-and-custom-into-one-control-with-one-representation.md | — | `aff99c9c863e` |
| `docs/research/explore-design-cells/explore-perf-and-polish-plan.md` | RECOVERED | local/research/recovered/explore-design-cells/explore-perf-and-polish-plan.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/foundation-port-files.txt` | RECOVERED | local/research/recovered/explore-design-cells/foundation-port-files.txt | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/honesty-copy/design.md` | RECOVERED | local/research/recovered/explore-design-cells/honesty-copy/design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/honesty-copy/prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/search-result-copy-names-the-ordering-not-the-retrieval-engine.md | — | `aff99c9c863e` |
| `docs/research/explore-design-cells/over-time-chart-perf-prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/time-bucket-histograms-aggregate-server-side-auto-fit-domain-and-adaptive-granularity.md | — | `aff99c9c863e` |
| `docs/research/explore-design-cells/over-time-chart/design.md` | RECOVERED | local/research/recovered/explore-design-cells/over-time-chart/design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/over-time-chart/prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/brush-to-filter-histograms-write-the-existing-time-range-and-bars-must-reconcile-with-the-list.md | — | `aff99c9c863e` |
| `docs/research/explore-design-cells/record-components/design.md` | RECOVERED | local/research/recovered/explore-design-cells/record-components/design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/record-components/harness/base.css` | RECOVERED | local/research/recovered/explore-design-cells/record-components/harness/base.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/record-components/harness/components.css` | RECOVERED | local/research/recovered/explore-design-cells/record-components/harness/components.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/record-components/harness/index.html` | RECOVERED | local/research/recovered/explore-design-cells/record-components/harness/index.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/record-components/prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/one-record-primitive-across-table-feed-and-detail-via-field-type-renderer-registry.md | — | `aff99c9c863e` |
| `docs/research/explore-design-cells/sort/design.md` | RECOVERED | local/research/recovered/explore-design-cells/sort/design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-design-cells/sort/prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/consumer-record-feeds-use-single-key-sort-multi-key-stacked-sort-is-a-power-table-affordance.md | — | `aff99c9c863e` |
| `docs/research/explore-emitted-vs-semantic-date-audit-2026-06-19.md` | RECOVERED | local/research/recovered/explore-emitted-vs-semantic-date-audit-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-escape-ramps-global-search-validation-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/bounded-discovery-feeds-need-an-active-escape-ramp-and-search-ranks-globally-not-per-source-quota.md | — | `aff99c9c863e` |
| `docs/research/explore-experience-feedback-2026-06-21.md` | RECOVERED | local/research/recovered/explore-experience-feedback-2026-06-21.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-feed-interaction-dynamics-prior-art-2026-06-21.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/grouped-feeds-expand-inline-for-small-sets-drill-in-for-large-and-shown-counts-must-be-reachable.md | — | `aff99c9c863e` |
| `docs/research/explore-feedback-corpus-VERBATIM-2026-06-22.md` | RECOVERED | local/research/recovered/explore-feedback-corpus-VERBATIM-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-filter-rail-vs-operator-language-prior-art-2026-06-22.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/filter-rail-and-typed-query-are-one-model-two-surfaces-with-result-scoped-counts.md | — | `aff99c9c863e` |
| `docs/research/explore-full-visibility-spec-2026-06-19.md` | RECOVERED | local/research/recovered/explore-full-visibility-spec-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-future-dated-records-prior-art-2026-06-21.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/future-dated-records-go-in-a-separate-upcoming-section-not-interleaved-in-a-newest-first-feed.md | — | `aff99c9c863e` |
| `docs/research/explore-loading-states-design-2026-06-20.md` | RECOVERED | local/research/recovered/explore-loading-states-design-2026-06-20.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-loadmore-replace-bug-2026-06-20.md` | RECOVERED | local/research/recovered/explore-loadmore-replace-bug-2026-06-20.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-loadmore-snapshot-pin-fix-2026-06-20.md` | RECOVERED | local/research/recovered/explore-loadmore-snapshot-pin-fix-2026-06-20.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-merged-timeline-pagination-prior-art-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/keyset-pagination-does-not-freeze-the-result-set-a-time-boundary-must-be-pinned-into-the-cursor.md | — | `aff99c9c863e` |
| `docs/research/explore-now-boundary-pinning-prior-art-2026-06-21.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/keyset-pagination-does-not-freeze-the-result-set-a-time-boundary-must-be-pinned-into-the-cursor.md | — | `aff99c9c863e` |
| `docs/research/explore-query-filter-ia-prior-art-2026-06-21.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/leading-products-use-one-tokenized-query-surface-with-facets-and-operators-as-one-query-state.md | — | `aff99c9c863e` |
| `docs/research/explore-record-explorer-product-pattern-prior-art-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/products-separate-cross-cutting-discovery-search-from-per-entity-fully-paginated-browse.md | — | `aff99c9c863e` |
| `docs/research/explore-relevance-browse-door-validation-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/products-escape-bounded-relevance-search-via-a-relevance-to-chronological-sort-switch-and-a-browse-door.md | — | `aff99c9c863e` |
| `docs/research/explore-rewalk-audit-2026-06-22.md` | RECOVERED | local/research/recovered/explore-rewalk-audit-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-search-exhaustion-flow-design-2026-06-19.md` | RECOVERED | local/research/recovered/explore-search-exhaustion-flow-design-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-search-pagination-primary-sources-2026-06-19.md` | RECOVERED+FOLDED-INTO-SIBLING | local/research/recovered/explore-search-pagination-primary-sources-2026-06-19.md (substance folded into ~/code/dotfiles/ai/research/data-explorer-ux/relevance-ranked-and-hybrid-vector-search-results-cannot-be-honestly-deep-paginated.md) | `aff99c9c863e^` | `aff99c9c863e` |
| `docs/research/explore-search-relevance-pagination-prior-art-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/relevance-ranked-and-hybrid-vector-search-results-cannot-be-honestly-deep-paginated.md | — | `aff99c9c863e` |
| `docs/research/explore-search-result-set-model-validation-2026-06-19.md` | RECOVERED | local/research/recovered/explore-search-result-set-model-validation-2026-06-19.md | `aff99c9c863e^` | `aff99c9c863e` |
| `docs/research/explore-semantic-time-sort-design-2026-06-20.md` | RECOVERED | local/research/recovered/explore-semantic-time-sort-design-2026-06-20.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-alignment-review-2026-06-21.md` | RECOVERED | local/research/recovered/explore-slvp-alignment-review-2026-06-21.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-consolidated-sweep-plan-2026-06-22.md` | RECOVERED | local/research/recovered/explore-slvp-consolidated-sweep-plan-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-feel-redesign-plan-2026-06-22.md` | RECOVERED | local/research/recovered/explore-slvp-feel-redesign-plan-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-product-mapping-verdict-2026-06-19.md` | RECOVERED | local/research/recovered/explore-slvp-product-mapping-verdict-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-recommendation-synthesis-2026-06-19.md` | RECOVERED | local/research/recovered/explore-slvp-recommendation-synthesis-2026-06-19.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/00-AUTONOMOUS-PLAN.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/00-AUTONOMOUS-PLAN.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/01-benchmark-synthesis-and-rubric.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/01-benchmark-synthesis-and-rubric.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/02-target-design.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/02-target-design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/03-critic-verdict.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/03-critic-verdict.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/04-final-verification.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/04-final-verification.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/05-impl-surface-map.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/05-impl-surface-map.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/06-recomposition-spec.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/06-recomposition-spec.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/07-live-rewalk-score.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/07-live-rewalk-score.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/08-saved-views-design.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/08-saved-views-design.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/STATUS.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/STATUS.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/THE-LENS.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/THE-LENS.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-a-commandbar/index.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-a-commandbar/index.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-a-commandbar/styles.css` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-a-commandbar/styles.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-b-chronology/index.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-b-chronology/index.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-b-chronology/styles.css` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-b-chronology/styles.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-c-filterrail/README.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-c-filterrail/README.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-c-filterrail/index.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-c-filterrail/index.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/concept-c-filterrail/styles.css` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/concept-c-filterrail/styles.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/data-fixture.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/data-fixture.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/final/README.md` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/final/README.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/final/feed-desktop.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/final/feed-desktop.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/final/search-desktop.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/final/search-desktop.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/final/styles.css` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/final/styles.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/final/zero-desktop.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/final/zero-desktop.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/row-calib-harness/base.css` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/row-calib-harness/base.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/row-calib-harness/components.css` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/row-calib-harness/components.css | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-redesign/prototype/row-calib-harness/index.html` | RECOVERED | local/research/recovered/explore-slvp-redesign/prototype/row-calib-harness/index.html | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-slvp-relayout-plan-2026-06-22.md` | RECOVERED | local/research/recovered/explore-slvp-relayout-plan-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-timeline-legibility-stability-validation-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/high-volume-chronological-feeds-use-day-grouping-burst-collapse-and-snapshot-cursor-n-new-pill.md | — | `a39ff289f13b` |
| `docs/research/explore-unified-personal-timeline-validation-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/personal-data-tools-default-to-a-unified-cross-source-day-grouped-timeline-as-primary-surface.md | — | `a39ff289f13b` |
| `docs/research/explore-upcoming-collapse-interaction-problem-2026-06-21.md` | RECOVERED | local/research/recovered/explore-upcoming-collapse-interaction-problem-2026-06-21.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/explore-visual-feel-prior-art-2026-06-22.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/slvp-record-feed-visual-craft-content-first-rows-sans-with-tabular-nums-load-point-feedback-unified-facet-query.md | — | `a39ff289f13b` |
| `docs/research/explorer-workbench-and-access-transparency-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/data-explorer-workbench-is-one-surface-query-facets-histogram-list-detail-and-app-access-transparency-is-list-scope-activity.md | — | `a39ff289f13b` |
| `docs/research/external-tool-connector-adapter-prior-art-2026-07-09.md` | LIVE-ON-MAIN | pdp/main:docs/research/external-tool-connector-adapter-prior-art-2026-07-09.md (mirrored at local/research/external-tool-connector-adapter-prior-art-2026-07-09.md) | — | — |
| `docs/research/force-dynamic-disposition-restoration-2026-06-17.md` | RECOVERED | local/research/recovered/force-dynamic-disposition-restoration-2026-06-17.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/google-maps-data-portability-api-timeline-2026-06-11.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-portability/google-timeline-import-tools-treat-it-as-file-import-with-guided-export-not-oauth.md | — | `a39ff289f13b` |
| `docs/research/google-maps-timeline-setup-ux-prior-art-2026-06-11.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-portability/google-timeline-import-tools-treat-it-as-file-import-with-guided-export-not-oauth.md | — | `a39ff289f13b` |
| `docs/research/headless-ui-engine-slvp-ideal-2026.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/frontend-libraries/headless-react-component-engines-2026-base-ui-vs-radix-vs-react-aria-vs-ark.md | — | `a39ff289f13b` |
| `docs/research/heb-auth-session-and-passive-collection-2026-07-14.md` | LIVE-ON-MAIN | pdp/main:docs/research/heb-auth-session-and-passive-collection-2026-07-14.md (mirrored at local/research/heb-auth-session-and-passive-collection-2026-07-14.md) | — | — |
| `docs/research/heb-site-knowledge-2026-07-14.md` | LIVE-ON-MAIN | pdp/main:docs/research/heb-site-knowledge-2026-07-14.md (mirrored at local/research/heb-site-knowledge-2026-07-14.md) | — | — |
| `docs/research/landing-page-framing-precedents.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/technical-landing-pages-lead-with-one-outcome-claim-and-one-real-artifact-proof-before-topology.md | — | `a39ff289f13b` |
| `docs/research/manifest-role-authoring-guide-2026-06-22.md` | RECOVERED | local/research/recovered/manifest-role-authoring-guide-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-client-read-surface-findings-2026-06-22.md` | RECOVERED | local/research/recovered/mcp-client-read-surface-findings-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-closeout-status-2026-07-01.md` | RECOVERED | local/research/recovered/mcp-closeout-status-2026-07-01.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-content-ladder-slvp-research-2026-06-22.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/mcp-protocol/mcp-large-fields-need-preview-plus-handle-plus-bounded-read-not-inline-dumps.md | — | `a39ff289f13b` |
| `docs/research/mcp-handle-footgun-audit-2026-06-26.md` | RECOVERED | local/research/recovered/mcp-handle-footgun-audit-2026-06-26.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-large-data-surface-patterns-2026-06-22.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/mcp-protocol/successful-mcp-servers-return-focused-context-and-content-must-not-dead-end.md | — | `a39ff289f13b` |
| `docs/research/mcp-oauth-headless-auth-prior-art-2026-06-12.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/oauth-mcp-auth/headless-cli-oauth-uses-device-authorization-grant-not-loopback-callback.md | — | `a39ff289f13b` |
| `docs/research/mcp-read-evidence-architecture-review-findings-2026-06-22.md` | RECOVERED | local/research/recovered/mcp-read-evidence-architecture-review-findings-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-read-evidence-client-review-findings-2026-06-22.md` | RECOVERED | local/research/recovered/mcp-read-evidence-client-review-findings-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-read-evidence-client-smoke-matrix-2026-06-22.md` | RECOVERED | local/research/recovered/mcp-read-evidence-client-smoke-matrix-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-read-evidence-full-ideal-plan-2026-06-23.md` | RECOVERED | local/research/recovered/mcp-read-evidence-full-ideal-plan-2026-06-23.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-read-evidence-live-smoke-2026-06-24.md` | RECOVERED | local/research/recovered/mcp-read-evidence-live-smoke-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-read-evidence-parity-review-findings-2026-06-22.md` | RECOVERED | local/research/recovered/mcp-read-evidence-parity-review-findings-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-read-surface-slvp-assessment-2026-06-22.md` | RECOVERED | local/research/recovered/mcp-read-surface-slvp-assessment-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-slvp-closeout-audit-2026-06-24.md` | RECOVERED | local/research/recovered/mcp-slvp-closeout-audit-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-slvp-closeout-chatgpt-retest-2026-06-24.md` | RECOVERED | local/research/recovered/mcp-slvp-closeout-chatgpt-retest-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-slvp-ideal-live-verification-2026-06-24.md` | RECOVERED | local/research/recovered/mcp-slvp-ideal-live-verification-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-slvp-live-verification-2026-06-24.md` | ALIVE-ON-BRANCH-origin/docs/mcp-slvp-live-verification+RECOVERED | local/research/recovered/mcp-slvp-live-verification-2026-06-24.md | `a35e8a8cfe86` | — |
| `docs/research/mcp-slvp-surface-audit-2026-06-24.md` | RECOVERED | local/research/recovered/mcp-slvp-surface-audit-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/mcp-slvp-surface-finish-2026-06-24.md` | RECOVERED | local/research/recovered/mcp-slvp-surface-finish-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/oauth-build-vs-buy-spike-2026-06-11.md` | RECOVERED+FOLDED-INTO-SIBLING | local/research/recovered/oauth-build-vs-buy-spike-2026-06-11.md (substance folded into ~/code/dotfiles/ai/research/oauth-mcp-auth/node-oidc-provider-rar-support-is-experimental-and-has-no-single-use-token-primitive.md) | `a39ff289f13b^` | `a39ff289f13b` |
| `docs/research/oauth-spike-throwaway/README.md` | RECOVERED | local/research/recovered/oauth-spike-throwaway/README.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/oauth-spike-throwaway/package.json` | RECOVERED | local/research/recovered/oauth-spike-throwaway/package.json | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/oauth-spike-throwaway/spike.mjs` | RECOVERED | local/research/recovered/oauth-spike-throwaway/spike.mjs | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/open-lane-triage-2026-06-22.md` | RECOVERED | local/research/recovered/open-lane-triage-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/opportunistic-collection.md` | RECOVERED | local/research/recovered/opportunistic-collection.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/owner-actionability-prior-art-2026-06-29.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/actionability-is-a-separate-signal-from-status-surface-next-action-not-inferred-from-health-labels.md | — | `a39ff289f13b` |
| `docs/research/owner-console-access-review-grants-clients-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/data-explorer-workbench-is-one-surface-query-facets-histogram-list-detail-and-app-access-transparency-is-list-scope-activity.md | — | `a39ff289f13b` |
| `docs/research/owner-console-add-data-connector-setup-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/connectors/data-connector-setup-declares-modality-and-exact-scopes-up-front-validates-before-success-and-shows-live-first-sync.md | — | `a39ff289f13b` |
| `docs/research/owner-console-copy-and-microcopy-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/ux-writing/product-status-and-error-copy-uses-a-closed-owner-adjective-vocabulary-with-inline-definitions-and-demotes-internal-codes.md | — | `a39ff289f13b` |
| `docs/research/owner-console-evidence-timelines-runs-traces-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/evidence-timelines-are-reached-from-their-subject-render-typed-compact-rows-and-keep-raw-payload-as-the-last-tab.md | — | `a39ff289f13b` |
| `docs/research/owner-console-feedback-synthesis-2026-06-18.md` | RECOVERED | local/research/recovered/owner-console-feedback-synthesis-2026-06-18.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/owner-console-fresh-non-owner-journey-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/onboarding-ux/first-run-setup-journeys-are-staged-per-subject-with-product-observed-status-and-identity-echo-not-a-docs-dump.md | — | `a39ff289f13b` |
| `docs/research/owner-console-mobile-responsive-and-craft-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/mobile-craft-contracts-44px-touch-floor-designed-back-semantics-by-breakpoint-and-motion-that-communicates-state.md | — | `a39ff289f13b` |
| `docs/research/owner-console-operator-prior-art-gaps-2026-07-09.md` | LIVE-ON-MAIN | pdp/main:docs/research/owner-console-operator-prior-art-gaps-2026-07-09.md (mirrored at local/research/owner-console-operator-prior-art-gaps-2026-07-09.md) | — | — |
| `docs/research/owner-console-product-gestalt-and-data-dignity-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/multi-object-admin-consoles-feel-like-one-product-via-naming-discipline-first-class-objects-and-second-person-data-ownership.md | — | `a39ff289f13b` |
| `docs/research/owner-console-record-workbench-explore-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/record-workbench-ux-converges-on-one-query-state-live-scoped-counts-and-shown-of-total.md | — | `a39ff289f13b` |
| `docs/research/owner-console-recovery-and-liveness-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/run-and-issue-liveness-ux-named-states-earned-recovery-pushed-progress-cli-ui-parity.md | — | `a39ff289f13b` |
| `docs/research/owner-console-report-issue-cta-prior-art-2026-06-19.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/feedback-systems/report-issue-ctas-converge-on-prefilled-github-new-issue-url-with-minimal-versioned-body.md | — | `a39ff289f13b` |
| `docs/research/owner-console-slvp-prior-art-index-2026-06-18.md` | RECOVERED | local/research/recovered/owner-console-slvp-prior-art-index-2026-06-18.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/owner-console-source-inventory-and-detail-prior-art-2026-06-18.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/connection-inventory-ux-strict-noun-hierarchy-worded-status-legends-predicate-bound-counts.md | — | `a39ff289f13b` |
| `docs/research/owner-spine-static-secret-setup-evidence-2026-06-18.md` | RECOVERED | local/research/recovered/owner-spine-static-secret-setup-evidence-2026-06-18.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/parallel-audits-rollup-2026-06-11.md` | RECOVERED | local/research/recovered/parallel-audits-rollup-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/pdpp-consent-artifact-persistence-and-sharing-brief-2026-06-23.md` | RECOVERED | local/research/recovered/pdpp-consent-artifact-persistence-and-sharing-brief-2026-06-23.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/pdpp-status-map.md` | RECOVERED | local/research/recovered/pdpp-status-map.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/per-connector-rate-profiles-2026-06-13.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/rate-limiting/documented-api-rate-limits-github-notion-oura-spotify-strava-ynab.md | — | `a39ff289f13b` |
| `docs/research/perceived-and-architectural-perf-2026-06-17.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/web-performance/ppr-plus-skeletons-and-parallel-fetching-are-the-2026-perceived-and-architectural-perf-defaults.md | — | `a39ff289f13b` |
| `docs/research/perf-opportunities-register-2026-06-17.md` | RECOVERED | local/research/recovered/perf-opportunities-register-2026-06-17.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/performance-evaluation-lenses.md` | RECOVERED | local/research/recovered/performance-evaluation-lenses.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/pg-search-bm25-slvp-prior-art-2026-06-17.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/search-infrastructure/paradedb-pg-search-adds-postgres-native-bm25-topk-versus-builtin-fts-candidate-ranking.md | — | `a39ff289f13b` |
| `docs/research/pgvector-filtered-ann-performance-2026-06-17.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/search-infrastructure/pgvector-filtered-ann-needs-btree-first-for-selective-filters-because-hnsw-filters-after-scan.md | — | `a39ff289f13b` |
| `docs/research/prior-art-graveyard-uma-solid-2026-06-24.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-portability/why-user-controlled-personal-data-protocols-failed-to-get-adoption-uma-solid-and-the-dead-pool.md | — | `a39ff289f13b` |
| `docs/research/product-identity-enrichment-boundary-2026-07-15.md` | LIVE-ON-MAIN | pdp/main:docs/research/product-identity-enrichment-boundary-2026-07-15.md (mirrored at local/research/product-identity-enrichment-boundary-2026-07-15.md) | — | — |
| `docs/research/product-leadership-aperture-and-discovery-2026-06-18.md` | RECOVERED | local/research/recovered/product-leadership-aperture-and-discovery-2026-06-18.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/pwa-web-push-notification-setup-prior-art-2026-07-05.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/web-push/web-push-permission-must-be-gesture-gated-and-install-permission-subscription-are-separate-per-device-states.md | — | `a39ff289f13b` |
| `docs/research/rbs-ux-technique-mine-2026-07-06.md` | RECOVERED | local/research/recovered/rbs-ux-technique-mine-2026-07-06.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/record-kind-declared-not-guessed-plan-2026-06-22.md` | RECOVERED | local/research/recovered/record-kind-declared-not-guessed-plan-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/record-presentation-fix-plan-2026-06-22.md` | RECOVERED | local/research/recovered/record-presentation-fix-plan-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/record-presentation-ideal-2026-06-22.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/record-title-selection-is-authored-not-guessed-and-honest-fallback-ranks-by-data-shape-not-field-name.md | — | `a39ff289f13b` |
| `docs/research/record-relationship-navigation-prior-art-2026-06-04.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/api-contract-design/related-record-navigation-uses-id-default-declared-expansion-not-foreign-key-heuristics.md | — | `a39ff289f13b` |
| `docs/research/reference-implementation-ux-prior-art.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/forkable-reference-implementations-separate-docs-samples-cli-and-runtime-over-a-common-substrate.md | — | `a39ff289f13b` |
| `docs/research/regulatory-forcing-functions-2026-06-24.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-portability/regulatory-forcing-functions-for-personal-data-portability-and-how-regulation-couples-to-a-named-standard.md | — | `a39ff289f13b` |
| `docs/research/remote-surface-extraction-plan-2026-07-08.md` | RECOVERED | local/research/recovered/remote-surface-extraction-plan-2026-07-08.md | `14e2d9dd314d` | `73d84cd3fc79` |
| `docs/research/remote-surface-mobile-trusted-input-2026-07-17.md` | LIVE-ON-MAIN | pdp/main:docs/research/remote-surface-mobile-trusted-input-2026-07-17.md (mirrored at local/research/remote-surface-mobile-trusted-input-2026-07-17.md) | — | — |
| `docs/research/remote-surface-standalone-audit-2026-07-06.md` | RECOVERED | local/research/recovered/remote-surface-standalone-audit-2026-07-06.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/remote-surface-ux-onboarding-2026-07-06.md` | RECOVERED | local/research/recovered/remote-surface-ux-onboarding-2026-07-06.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/ri-owner-orchestration-process-design-2026-06-15.md` | RECOVERED | local/research/recovered/ri-owner-orchestration-process-design-2026-06-15.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/ri-owner-tmux-live-orchestration-2026-06-15.md` | RECOVERED | local/research/recovered/ri-owner-tmux-live-orchestration-2026-06-15.md | `a39ff289f13b^` | `a39ff289f13b` |
| `docs/research/ri-sprawl-closeout-status-2026-07-01.md` | RECOVERED | local/research/recovered/ri-sprawl-closeout-status-2026-07-01.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/rs-search-postgres-index-prior-art-2026-06-17.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/search-infrastructure/postgres-full-text-search-uses-gin-with-btree-gin-for-composite-equality-plus-fts.md | — | `a39ff289f13b` |
| `docs/research/sdk-and-ui-seams-prior-art-2026-06-11.md` | RECOVERED | local/research/recovered/sdk-and-ui-seams-prior-art-2026-06-11.md | `a39ff289f13b^` | `a39ff289f13b` |
| `docs/research/shared-read-shaping-package-naming-prior-art-2026-06-24.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/code-quality/mature-npm-ecosystems-name-a-shared-package-after-the-durable-concept-it-owns-core-runtime-util-to-output.md | — | `a39ff289f13b` |
| `docs/research/shippability-audit-2026-06-16.md` | RECOVERED | local/research/recovered/shippability-audit-2026-06-16.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slack-coverage-live-verification-2026-06-29.md` | RECOVERED | local/research/recovered/slack-coverage-live-verification-2026-06-29.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slack-stars-usergroups-reminders-readstate-api-reachability-2026-07-10.md` | LIVE-ON-MAIN | pdp/main:docs/research/slack-stars-usergroups-reminders-readstate-api-reachability-2026-07-10.md (mirrored at local/research/slack-stars-usergroups-reminders-readstate-api-reachability-2026-07-10.md) | — | — |
| `docs/research/slvp-adaptive-collection-ideal-2026-06-11.md` | RECOVERED | local/research/recovered/slvp-adaptive-collection-ideal-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-benchmark-2026-06-23/linear-command-and-filters.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/linear-uses-one-tokenized-command-bar-for-navigation-and-filtering.md | — | `a39ff289f13b` |
| `docs/research/slvp-benchmark-2026-06-23/raycast-stripe-search-and-feed.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/raycast-and-stripe-show-minimal-rows-with-detail-in-a-side-pane-and-zero-results-as-routing.md | — | `a39ff289f13b` |
| `docs/research/slvp-benchmark-2026-06-23/shots/MANIFEST.md` | RECOVERED | local/research/recovered/slvp-benchmark-2026-06-23/shots/MANIFEST.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-benchmark-2026-06-23/shots/pruned/raycast-homepage-hero-desktop.jpeg` | RECOVERED | local/research/recovered/slvp-benchmark-2026-06-23/shots/pruned/raycast-homepage-hero-desktop.jpeg | `7f6a5f1ffb42` | `216b15ff55be` |
| `docs/research/slvp-benchmark-2026-06-23/superhuman-personal-stream-search.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/superhuman-treats-speed-as-the-primary-design-constraint-with-operator-autocomplete-and-a-calm-split-view.md | — | `a39ff289f13b` |
| `docs/research/slvp-benchmark-2026-06-23/things3-chronology-and-beauty.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/things3-partitions-time-into-named-zones-and-earns-calm-through-color-constraint-and-metadata-on-demand.md | — | `a39ff289f13b` |
| `docs/research/slvp-benchmark-2026-06-23/timeline-feed-and-visual-systems.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/data-explorer-ux/heterogeneous-record-feeds-use-one-row-template-with-only-the-leading-glyph-varying.md | — | `a39ff289f13b` |
| `docs/research/slvp-connector-agency-and-silence-2026-06-15.md` | RECOVERED | local/research/recovered/slvp-connector-agency-and-silence-2026-06-15.md | `a39ff289f13b^` | `a39ff289f13b` |
| `docs/research/slvp-connector-health-FINAL-design-2026-06-15.md` | RECOVERED | local/research/recovered/slvp-connector-health-FINAL-design-2026-06-15.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-connector-health-ideal-design-2026-06-15.md` | RECOVERED | local/research/recovered/slvp-connector-health-ideal-design-2026-06-15.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-connector-health-legibility-reflection-2026-06-15.md` | RECOVERED | local/research/recovered/slvp-connector-health-legibility-reflection-2026-06-15.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-connector-health-priorart-2026-06-15.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/feedback-systems/integration-health-ui-converges-on-one-synthesized-verdict-plus-a-typed-required-action-plus-a-self-heal-satisfaction-contract.md | — | `a39ff289f13b` |
| `docs/research/slvp-heuristic-audit-2026-06-22.md` | RECOVERED | local/research/recovered/slvp-heuristic-audit-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-ideal-audit-logging-2026-06-12.md` | RECOVERED | local/research/recovered/slvp-ideal-audit-logging-2026-06-12.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-ideal-browser-device-connector-setup-2026-06-14.md` | RECOVERED | local/research/recovered/slvp-ideal-browser-device-connector-setup-2026-06-14.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-ideal-connection-materialization-2026-06-14.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/api-contract-design/connection-objects-are-created-by-an-explicit-step-never-as-a-side-effect-of-a-read.md | — | `a39ff289f13b` |
| `docs/research/slvp-ideal-connection-reactivation-2026-06-14.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/api-contract-design/platforms-repair-a-broken-connection-in-place-preserving-identity-and-history-not-by-recreating-it.md | — | `a39ff289f13b` |
| `docs/research/slvp-ideal-connector-self-service-setup-2026-06-14.md` | RECOVERED | local/research/recovered/slvp-ideal-connector-self-service-setup-2026-06-14.md | `a39ff289f13b^` | `a39ff289f13b` |
| `docs/research/slvp-ideal-control-system-verdict-2026-06-11.md` | RECOVERED | local/research/recovered/slvp-ideal-control-system-verdict-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-ideal-mobile-master-detail-2026-06-14.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/mobile-list-detail-uses-full-page-push-navigation-not-stacked-panels-or-sheets.md | — | `a39ff289f13b` |
| `docs/research/slvp-ideal-scheduled-human-help-2026-06-12.md` | RECOVERED | local/research/recovered/slvp-ideal-scheduled-human-help-2026-06-12.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-ideal-stuck-run-liveness-2026-06-14.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/distributed-systems/bounding-a-hung-job-uses-heartbeat-plus-wall-clock-timeout-a-startup-reaper-and-fencing-tokens.md | — | `a39ff289f13b` |
| `docs/research/slvp-ideal-whole-system-spec-2026-06-11.md` | RECOVERED | local/research/recovered/slvp-ideal-whole-system-spec-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/slvp-restoration-VERIFIED-package-2026-06-17.md` | RECOVERED | local/research/recovered/slvp-restoration-VERIFIED-package-2026-06-17.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/source-actionability-acceptance-closeout-2026-07-01.md` | RECOVERED | local/research/recovered/source-actionability-acceptance-closeout-2026-07-01.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/source-backed-fulfillment-prior-art-2026-07-09.md` | LIVE-ON-MAIN | pdp/main:docs/research/source-backed-fulfillment-prior-art-2026-07-09.md (mirrored at local/research/source-backed-fulfillment-prior-art-2026-07-09.md) | — | — |
| `docs/research/sources-slvp-redesign-and-data-health-2026-06-11.md` | RECOVERED | local/research/recovered/sources-slvp-redesign-and-data-health-2026-06-11.md | `f77f6e1106a1` | `216b15ff55be` |
| `docs/research/spec-readiness-audit-2026-06-24.md` | RECOVERED | local/research/recovered/spec-readiness-audit-2026-06-24.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/token-staleness-disposition-2026-06-11.md` | RECOVERED | local/research/recovered/token-staleness-disposition-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/trace-surface-patterns.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/product-design/execution-history-surfaces-keep-one-append-only-event-spine-projected-into-operator-and-explainer-views.md | — | `a39ff289f13b` |
| `docs/research/ui-overhaul-current-state-2026-06-10.md` | RECOVERED | local/research/recovered/ui-overhaul-current-state-2026-06-10.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/user-facing-copy-audit-2026-06-11.md` | RECOVERED | local/research/recovered/user-facing-copy-audit-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/wallclock-cap-ideal-verdict-2026-06-11.md` | RECOVERED | local/research/recovered/wallclock-cap-ideal-verdict-2026-06-11.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/webhook-event-envelope-standards-2026-06-11.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/webhooks-events/cloudevents-plus-standard-webhooks-are-the-interoperable-envelope-and-signing-choices-with-thin-payloads-preferred.md | — | `a39ff289f13b` |
| `docs/research/whatsapp-connector-prior-art-2026-06-12.md` | MIGRATED-DOTFILES | ~/code/dotfiles/ai/research/connectors/whatsapp-personal-data-access-official-export-vs-unofficial-web-libraries-vs-backup-tools.md | — | `a39ff289f13b` |
| `docs/research/workstream-research-harvest-2026-06-22.md` | RECOVERED | local/research/recovered/workstream-research-harvest-2026-06-22.md | `766f4da2ecc7^` | `766f4da2ecc7` |
| `docs/research/worktree-harvest-audit-2026-06-29.md` | RECOVERED | local/research/recovered/worktree-harvest-audit-2026-06-29.md | `766f4da2ecc7^` | `766f4da2ecc7` |

## Summary counts

The 247-row table above covers the original scrape; the addendum table covers the 19 paths
found by the follow-up integrity check. Combined:

| Disposition | Count |
|---|---|
| LIVE-ON-MAIN | 9 |
| ALIVE-ON-BRANCH-\*+ALREADY-LOCAL | 1 |
| ALIVE-ON-BRANCH-\*+RECOVERED | 5 |
| ALIVE-ON-BRANCH(unmerged)+RECOVERED | 16 |
| ALIVE-ON-BRANCH+RECOVERED+ALREADY-IN-TOPLEVEL-WORKTREE | 3 |
| MIGRATED-DOTFILES | 78 |
| RECOVERED+FOLDED-INTO-SIBLING | 2 |
| RECOVERED | 152 |
| **Total** | **266** |

182 physical files were written under `local/research/recovered/` (163 from the original
247-path sweep, plus 19 from the addendum; some RECOVERED-category rows map to the same
on-disk binary already counted once — this figure is the actual file count on disk and
matches every row whose disposition contains `RECOVERED`).

**All 266 of 266 paths that ever existed under `docs/research/` across both remotes' full
history (the original 247-path scrape plus the 19-path addendum found by an independent
re-derivation of the same query) are accounted for. Zero unaccounted. Nothing was deleted;
every file whose content was not already safe elsewhere (working tree, a genuinely verified
dotfiles migration, or a still-live branch tip) now has a byte-exact recovered copy under
`local/research/recovered/`.**

### Corrections to the two migration commits' own groupings

Two files were cross-matched to the wrong dotfiles sibling by superficial topic similarity
during initial triage; content verification (source_session id + specific claims) showed the
correct pairing is the other way around:

- `slvp-connector-health-priorart-2026-06-15.md` (Plaid/Stripe/Datadog/GitHub/Vercel/Nango
  "verdict + required-action + self-heal" content, source_session `019d3a01…`) →
  `feedback-systems/integration-health-ui-converges-on-one-synthesized-verdict-plus-a-typed-required-action-plus-a-self-heal-satisfaction-contract.md`
  (same session, same sources).
- `owner-console-recovery-and-liveness-prior-art-2026-06-18.md` (Sentry/Linear/Temporal named
  state-machine content, source_session `019d96dc…`) →
  `product-design/run-and-issue-liveness-ux-named-states-earned-recovery-pushed-progress-cli-ui-parity.md`
  (same session, same sources).

Both are correctly attributed above.

### FOLDED-INTO-SIBLING detail

Two files had their general-prior-art content absorbed into a dotfiles entry that is really
the primary extraction of a closely related sibling source document from the same research
session, not a faithful standalone substitute for this specific file:

- `docs/research/explore-search-pagination-primary-sources-2026-06-19.md` — a primary-source
  verification pass for claims already carried by
  `explore-search-relevance-pagination-prior-art-2026-06-19.md` (its sibling, which migrated
  cleanly to `data-explorer-ux/relevance-ranked-and-hybrid-vector-search-results-cannot-be-honestly-deep-paginated.md`).
  Recovered as a safety net.
- `docs/research/oauth-build-vs-buy-spike-2026-06-11.md` — its generic `node-oidc-provider`
  library findings survive in
  `oauth-mcp-auth/node-oidc-provider-rar-support-is-experimental-and-has-no-single-use-token-primitive.md`,
  but the PDPP-specific decision memo (auth.js decomposition verdict, the 14%-extraction
  estimate, the `single_use` primitive gap) is PDPP-braided and not captured anywhere in
  dotfiles. Recovered in full.

### ALIVE-ON-BRANCH detail

Five files are not on `pdp/main` but are still live at the tip of a named branch on `pdp` or
`origin` (recovered anyway per instructions, since a branch can be deleted at any time):

- `docs/research/artifacts/owner-spine-static-secret-setup-2026-06-18/{desktop,mobile-390}.png`
  — alive on `origin/ci-cost-docker-paths-and-validate-arch`.
- `docs/research/connect-ai-apps-screenshots-2026-06-14/{desktop,mobile-390}.jpeg` — alive on
  `origin/chore/preserve-agent-work-20260625`.
- `docs/research/mcp-slvp-live-verification-2026-06-24.md` — alive on
  `origin/docs/mcp-slvp-live-verification` (this file was never deleted anywhere; it simply
  never made it into `pdp/main`).

All binary recoveries (the 4 PNG/JPEG files above, plus the pruned Raycast screenshot
recovered from the `766f4da2e` bucket) were verified byte-exact via
`git cat-file -s <blob>` vs `stat -c%s <output>`. All text-file recoveries used `git show
<commit>:<path> > <output>` redirection, which is byte-exact for git-tracked text content.
