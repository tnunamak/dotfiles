# PDPP owner-problem closeout ledger — 2026-07-03

Status: **durable, single-source closeout ledger** for every concrete
owner-visible problem Tim reported in the pdpp RI Codex session
(`2026-06-08 … 2026-07-03`). This is the artifact Tim explicitly asked for on
2026-07-01 14:32 and which, until now, existed only as ephemeral chat tables
scattered across per-theme docs. See the audit that produced it:
`docs/research/pdpp-ri-codex-gap-audit-2026-07-03.md`.

**The rule Tim set (verbatim):** "anything not proven should stay explicitly
marked 'not proven,' not quietly disappear."

Every row is in exactly **one** of four states:

- **`FIXED+VERIFIED`** — fixed, deployed, and verified (code/live evidence).
- **`FIXED-UNVERIFIED`** — code fix landed, not confirmed on the live instance
  from here.
- **`SCOPED-OPEN`** — understood, correctly surfaced, but not yet solved.
- **`NOT-PROVEN`** — no definitive end-to-end root cause established.

"Owner vs us" = whether the remaining action is Tim's (a decision or a login) or
engineering's. Codebase status verified against `waspflow/sp2-convo` HEAD
`152fc8c59` unless noted; live status is last-known from the transcript (no live
dashboard probe available from this shell).

---

## A. Connector auth / collection

| # | Symptom Tim saw | Best-supported root cause | State | Evidence / PR·commit | Remaining — owner vs us |
|---|---|---|---|---|---|
| A1 | ChatGPT stopped auto-collecting; started pinging for approval | Reusable browser/API session lost after fresh n.eko surface + controller restart; visible-UI auth ≠ connector API-session auth; then stored-credential runs turned logout into approval pushes | **FIXED-UNVERIFIED** (mechanism) | `#96` preserve-page + read-session-first; `#95` classify `chatgpt_session_required` + needs-human gate; `4cbbc5899`/`#176` CDP `PUT`; `57c24a7a4`/`#177` port-collision retry; closeout `chatgpt-session-reuse-regression-closeout-2026-06-29.md` | **Us**: observe a multi-hour unattended reuse run live before claiming durable. Original 06-25 durability regression is **NOT-PROVEN end-to-end** (old container state gone) |
| A2 | `ChatGPT - everyone@appears.blue` | — | **FIXED+VERIFIED** | Scheduled run completed with no owner action (transcript 07-02, L25988/L26499) | none |
| A3 | `ChatGPT - dondochaka` still "Needs you / Reconnect" | Old account's last run predates the browser-stall fixes; account itself needs a login | **SCOPED-OPEN** | transcript 07-02 L26498/L26520 | **Owner**: reconnect **or** delete this account (see D2) |
| A4 | Proactive self-healing auth ("system should get healthy by proactively having me recover auth", 06-27 L20597) | Not built; only a passive needs-human gate exists | **SCOPED-OPEN** | needs-human gate `#95`; no proactive-recovery OpenSpec | **Us**: design proactive probe→single-owner-action recovery loop |
| A5 | USAA: `usaa_session_failed: password field never appeared after Next click` | Delayed/unavailable login modal; connector can't complete the two-step login | **SCOPED-OPEN** | `18098f50d` (#121) **classifies only** — does not collect | **Us**: fixture-first connector fix (capture scrubbed login-modal fixture, pin it) |
| A6 | Chase "completed with known coverage gaps" | Dropdown/coverage path fails to recover all transactions | **SCOPED-OPEN** | one dropdown-gap fix 07-02 L25947; still "did not fully recover your data" L25556 | **Us**: fixture-first connector fix for the remaining coverage gap |
| A7 | Amazon retryable gaps | Recoverable per-run gap | **FIXED-UNVERIFIED** | "latest run succeeded today; remaining row is gap/retry cleanup" 07-02 L25748 | **Us**: confirm gap fully cleared |
| A8 | GitHub failing hourly `not_found` on `user_stats` ingest | Transient connectors.github manifest-drift row (missing `user_stats`) aborted whole run | **FIXED+VERIFIED** | `9b80bfabb` (#168) degrades transient manifest-drift 404 to a per-stream gap | none |
| A9 | Reddit first-click read failure ("second click worked", 06-29 L22305) | First-click read race | **SCOPED-OPEN** | not separately fixed; second click succeeds | **Us**: low-priority; confirm or fix first-click path |
| A10 | Local-collector `peregrine` "saved records did not upload" | Outbox does not retry/repair automatically | **SCOPED-OPEN** | no self-heal commit found; transcript 07-02 L26184 | **Us**: bounded outbox retry/repair + one owner "recover now" step |

## B. Owner-console UI truthfulness

| # | Symptom Tim saw | Root cause | State | Evidence / PR·commit | Remaining |
|---|---|---|---|---|---|
| B1 | "3 connections need a look" but page showed more rows | Runs rendered a flat "What's wrong?/What's missing?" stack | **FIXED+VERIFIED** | `#104` groups: Needs you / Worth reviewing / System or connector issue / Checking | none |
| B2 | Amazon/Reddit showed `auth: owner action required` when they only needed refresh/retry | Auth line keyed off wrong state | **FIXED+VERIFIED** | `#143` (`d9527254a`); tests 142/142 | none |
| B3 | ChatGPT paused/stale copy implied it "refreshes on schedule" | Disabled/manual schedule rendered as scheduled | **FIXED+VERIFIED** | `#143` | none |
| B4 | Duplicate buttons ("Refresh now Refresh now") | Verdict action duplicated body + footer CTA | **FIXED+VERIFIED** | `#143` | none |
| B5 | Config stream count ≠ stream-table count | Two different stream lists | **FIXED+VERIFIED** | `#143` | none |
| B6 | Runs/home used a different model than Sources | Un-shared actionability path | **FIXED+VERIFIED** | `#145` (`950337413`) + tests | none |
| B7 | Chase said "Retry now" while coverage was terminal | Stream-level retry erased connection-level terminal | **FIXED+VERIFIED** | `#146` (`9920b78b7`) preserve terminal disposition | none |
| B8 | "Urgent/advisory/retry/gap all look the same" (no color/emphasis) | Classification improved but no visual-design pass | **SCOPED-OPEN** | agent: "Medium confidence; did not do a full visual design pass" 07-01 L24657 | **Us**: visual hierarchy pass (color/placement/emphasis per class) |
| B9 | "Couldn't refresh your connections" banner — "I should never see that" | Transient `_ref/connectors` 401 during deploy/rebuild outlasts the single 4s auto-retry | **NOT-PROVEN** (root cause) / **SCOPED-OPEN** (fix) | `error.tsx` `32f82ad81` delays escalation but still one retry; contract pinned in `read-resilience.invariants.test.ts` | **Us**: prove the deploy-window 401, then bounded-backoff retry **or** render last-known cards (design-gated — changes a pinned contract) |
| B10 | "needs you" shown when `connector_attention_records` has zero open rows | UI/projection/staleness | **SCOPED-OPEN** | flagged 07-02 L25454 | **Us**: verify projection guards zero-row attention state |
| B11 | Reconnect CTA led to a confusing "Update credential" page for an SSO/browser connection | Repair routed by connector static-secret capability, not connection binding | **FIXED+VERIFIED** | `9e747e29e` (#169) connection-binding-first repair selection; `route-credentialless-repair-to-capture` archived; routing in `[connector]/page.tsx:742` + `connection-modality.ts` | none (structural). Residual: dead-account rows still only offer Reconnect (→ D2) |
| B12 | Dead/duplicate connections "pollute health"; hard to archive | Revoke/Delete only on per-connector danger zone, not on the health list | **SCOPED-OPEN** | `connection-danger-zone.tsx` has the actions; no inline archive on attention row | **Us**: inline archive/dismiss on the source-attention row (reuse `revokeConnectionAction`) |

## C. Explore

| # | Symptom | Root cause | State | Evidence |
|---|---|---|---|---|
| C1 | Explore slow first paint | ~38 per-stream `aggregateRecordsByTime` full-table-scans on the critical path (a regression the agent shipped) | **FIXED-UNVERIFIED** | single index-backed server aggregate + off-critical-path chart; plan `explore-perf-and-polish-plan.md`; ongoing OpenSpec `port-explore-timeline-server-foundation`, `redesign-explore-recordset-query-presentation` | **Us**: confirm live |
| C2 | Sparse chart (7300 day-cells over 20yr) | No extent-aware granularity | **FIXED-UNVERIFIED** | auto-granularity in the same plan | **Us**: confirm live |
| C3 | White PWA splash; error-after-backgrounding | Manifest theme + missing scoped error boundary | **FIXED-UNVERIFIED** | dark manifest + `explore/error.tsx` in plan | **Us**: confirm live |

## D. Cross-cutting / process

| # | Item | State | Evidence | Remaining |
|---|---|---|---|---|
| D1 | Sprawl — "back to `~/code/pdpp` on main" | **FIXED+VERIFIED** (standard) | `~/code/pdpp` returned to clean main (06-29 L22153, 07-02 L26521); cleanup standard `ri-sprawl-closeout-status-2026-07-01.md` | Hygiene tail: root-owned deploy scratch dir "when convenient" (07-02 L26522) — run the recorded narrow script |
| D2 | Old duplicate dead connections easy to remove | **SCOPED-OPEN** | see B12/A3 | **Owner** decision + **us** inline affordance |
| D3 | "Don't present a partial fix as the outcome" | **SCOPED-OPEN** (behavioral) | 06-28 L20740; 07-02 L25814 | Adopt this ledger as the standing closeout format |
| D4 | This ledger existing as a durable single artifact | **FIXED+VERIFIED** | this file | none |

---

## Honest open list (nothing hidden)

Still genuinely open at session end, by owner-vs-us:

- **Owner action:** A3/D2 reconnect-or-delete `ChatGPT - dondochaka`.
- **Us — connector engineering (fixture-first):** A5 USAA, A6 Chase, A9 Reddit
  first-click, A10 local-collector outbox self-heal.
- **Us — console:** B8 visual hierarchy pass, B9 "Couldn't refresh" banner
  (design-gated), B10 zero-row attention projection, B12 inline archive.
- **Us — design (Tim's #1 want):** A4 proactive auth-recovery loop.
- **Us — verify-live:** A1/A7 durability, C1–C3 Explore.

Explicitly **NOT-PROVEN** (kept visible, per Tim's rule): the original 2026-06-25
ChatGPT durability regression end-to-end (A1); the deploy-window 401 that fires
the read-failure banner (B9).
