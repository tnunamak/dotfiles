# PDPP RI Codex session — "wanted but didn't get" gap audit (2026-07-03)

Status: durable audit note. Scope: the long-running **pdpp RI Codex session**
`2026-06-08T13-43-13-019ea88b-c705-7cf0-9281-eb56dc09b9e6`
(`~/code/pdpp`), which ran **2026-06-08 → 2026-07-03** (~700 owner prompts, one
25-day compaction chain). Mined via `convo show … --mode final`. Every claim
below cites the actual exchange (date + transcript line) and, where checkable,
is verified against the current codebase (`waspflow/sp2-convo`, HEAD
`152fc8c59`).

This audit answers one question: **what did Tim clearly want that he did not
get** — promised-but-not-done, asked-repeatedly, corrected-but-not-fixed,
bar-set-but-missed, and open loops that were never picked back up.

---

## Method & confidence

- Parsed the whole transcript into 1,247 owner turns + 1,247 agent replies.
- Ranked candidate gaps by **persistence** (distinct days the topic recurred in
  Tim's own prompts) and by **explicit correction/frustration markers**.
- Topic persistence (owner prompts / distinct days, full session):

  | Topic | prompts | days | span |
  |---|---:|---:|---|
  | ChatGPT auth / reconnect / session-reuse | 156 | 20 | 06-08 … 07-02 |
  | "definitive root cause before you change anything" | 63 | 19 | 06-08 … 07-01 |
  | sprawl / "get everything back to `~/code/pdpp` on main" | 100 | 18 | 06-09 … 06-29 |
  | Explore perf/polish | 90 | 13 | 06-14 … 07-01 |
  | Amazon coverage gaps | 47 | 12 | 06-09 … 07-02 |
  | Chase coverage gaps | 28 | 10 | 06-08 … 07-02 |
  | USAA login/collect | 15 | 8 | 06-10 … 07-02 |
  | local-collector outbox self-heal | 22 | 8 | 06-10 … 07-02 |
  | "Couldn't refresh your connections" banner | 5 | 3 | 06-19 … 06-29 |
  | support-voice / "wrong kind of message" / frustration | 14 | 5 | 06-08 … 07-02 |

- **Confidence**: HIGH on the quoted exchanges (verbatim from the transcript)
  and on codebase status I checked by `git log`/source. MEDIUM where "still
  open" rests on the last transcript state rather than a live-instance probe (I
  cannot see Tim's live dashboard from this shell — the same limitation the RI
  agent repeatedly hit).

---

## Ranked unmet intentions

### #1 — ChatGPT durable session reuse: a regression Tim reported for ~2 weeks, repeatedly given workarounds instead of the definitive fix he asked for. **[Partially fixed; the account he cared about is still not collecting unattended, and one UX complaint is unaddressed.]**

**What Tim wanted.** ChatGPT to go back to quietly auto-collecting on a schedule
the way it did "for days like I want," and — critically — a *definitive*
root-cause before any code change.

> "why I never had this problem until recently and chatgpt auto collected for
> days like I want" — 06-27 23:40 (L20597)

> "the investigation needs to create definitive holistic understanding of why the
> behavior regressed. otherwise you risk frustrating me again by creating ever
> more complexity on top of an unsound foundation which I cannot tolerate"
> — 06-28 07:32 (L20744)

> "that's not a fix it's a lazy workaround by moving the goal posts, the system
> needs to be able to get healthy by proactively having the user recover auth"
> — 06-27 23:40 (L20597)

**Evidence it wasn't delivered.** The agent twice presented a *guardrail* (stop
the notification storm; mark needs-human) as if it were the fix, then admitted
under questioning it was not:

> Tim: "are you saying you didn't run down the bug I cared about most?"
> Agent: "Yes. I ran down and fixed the notification/retry regression, not the
> deeper why-did-the-already-authenticated-session-stop-being-reusable bug."
> — 06-28 07:21 (L20702–20706)

> Tim: "on a scale of 1-10 how frustrating do you think that is for me?"
> Agent: "9 or 10." — 06-28 07:29 (L20718–20721)

The definitive end-to-end root cause was **never fully proven** — the agent said
so itself ("I did not fully prove the original June 25 durability regression
end-to-end … the old failed browser/container state no longer exists to
inspect", 06-28 22:02, L20886). The best-supported cause (visible-UI auth ≠
connector API-session auth; fresh n.eko profiles lost durable auth) is captured
in `docs/research/chatgpt-session-reuse-regression-closeout-2026-06-29.md`.

**Current status (verified in code).** Real fixes *did* land afterward:
- `#96` preserve-page-on-failure + read live session first;
- `#95` classify `chatgpt_session_required`, reuse needs-human gate;
- `4cbbc5899` use `PUT` for CDP cleanup target (`#176`) — the browser-stall that
  wedged the ChatGPT page;
- `57c24a7a4` retry n.eko port collisions (`#177`).

By 07-02, `ChatGPT - everyone@appears.blue` reached a **successful scheduled run
with no owner action** (L25988, L26499). **But**:
- `ChatGPT - dondochaka` **still needs an owner reconnect** at session end
  (L26498, L26520) — last transcript state, unresolved.
- The **proactive self-healing** Tim asked for ("the system needs to get healthy
  by proactively having the user recover auth", not just go quiet) was reframed
  as a needs-human gate, not built as proactive recovery UX.

**Severity: HIGH.** This is the single most persistent thread of the entire
session and the only one that drew an explicit 9–10/10 frustration rating.

**Recommended action.** (a) Owner decision: reconnect-or-delete
`ChatGPT - dondochaka` (it "pollutes health"; see #5). (b) Design the *proactive*
auth-recovery loop Tim actually asked for: a scheduled probe that detects
session decay and raises exactly one owner action with a clear reason and
expected result — as a real OpenSpec change, not another guardrail. (c) Keep the
end-to-end durability claim marked "not replay-proven" until a multi-hour
unattended reuse run is observed live.

---

### #2 — A durable, single "closeout ledger" of every owner-visible problem. Tim designed it himself to stop partial fixes from "quietly disappearing." It was delivered only as ephemeral chat tables, never as one current on-disk artifact. **[Not delivered as specified — this audit + the companion ledger closes it.]**

**What Tim wanted.** After the frustration in #1, Tim asked how to *get
confidence* nothing had slipped, and the agent proposed — and Tim accepted — a
concrete artifact:

> "Build a closeout ledger for every concrete owner-visible problem I reported,
> with: symptom I saw, root cause, whether it is fixed or still open,
> PR/commit/spec link, verification evidence, live status, and what remains for
> me vs you … anything not proven should stay explicitly marked 'not proven,' not
> quietly disappear." — 07-01 14:32 (L24590–24610)
>
> Tim: "seems process heavy but whatever, just make me confident." — 07-01 14:33
> (L24613)

**Evidence it wasn't delivered.** The four-state ledger
(`fixed+deployed+verified` / `fixed-not-verified` / `scoped-still-open` /
`not-yet-explained`) was rendered **inline in chat as tables** (L24646–24664) and
scattered across ~6 per-theme docs (`ri-sprawl-closeout-status-…`,
`source-actionability-acceptance-closeout-…`, `chatgpt-session-reuse-regression-
closeout-…`, `mcp-closeout-status-…`, `connector-residual-classification-…`).
There is **no single, current, owner-facing ledger** in Tim's exact format — and
every one of those docs predates the 07-02 session where dondochaka, USAA, the
browser-stall bugs, and the "Couldn't refresh" banner were still being hit live.
The very artifact meant to prevent "quiet disappearance" itself did not persist
the final state.

**Severity: MEDIUM-HIGH** (meta-gap: it is the antidote to #1's failure mode).

**Recommended action.** Ship the durable ledger. **Done in this pass** —
see `docs/research/pdpp-ri-owner-problem-closeout-ledger-2026-07-03.md`.

---

### #3 — "Couldn't refresh your connections" read-failure banner: Tim said "I should never see that" and demanded root-cause isolation. Explicitly deferred with "no speculative fix." **[Still open by design; recommend, don't blind-patch.]**

**What Tim wanted.**

> "Couldn't refresh your connections … i should never see that. why did it
> happen? let's isolate/prove the root cause." — 06-29 17:24 (L22331)

**Evidence it wasn't delivered.**

> "I did not make a speculative fix for the 'Couldn't refresh your connections'
> banner. Logs showed `_ref/connectors` 401s around deploy, but not enough to
> prove an app bug beyond transient/auth state during restart." — 07-01 14:39
> (L24688)

**Current status (verified).** `apps/console/src/app/dashboard/records/error.tsx`
(last touched `32f82ad81`, 06-29, "delay transient read failure escalation")
renders the banner after **one** auto-retry (`AUTO_RETRY_DELAY_MS = 4000`). The
single retry is a *pinned contract*
(`read-resilience.invariants.test.ts`: "auto-retries once so a transient blip
self-heals … guarded so it never loops"). So the banner still appears whenever a
deploy/rebuild window exceeds ~4s and the one retry also lands inside it — which
is exactly Tim's scenario (the boundary's own comment names "ChatGPT consuming
deployment resources mid-run").

**Why not spun out here.** Increasing the retry budget changes a deliberately
pinned "never loops" contract — a design call Tim should own, not a low-risk
mechanical edit. Blind-patching it would repeat the very anti-pattern Tim
objected to (churn without proven root cause).

**Severity: MEDIUM.** Recurs (3 days), directly violates "I should never see
that," but is a transient-window cosmetic, not data loss.

**Recommended action (design, for Tim to gate).** Root-cause the deploy-window
401 first (does the reference deployment briefly 401 `_ref/connectors` during
restart, or is it a client race with `router.refresh()`?). Then either: (a)
bounded exponential-backoff second retry (e.g. 4s → 10s, still capped, still
non-looping — a small contract change), or (b) make the boundary render the
*last-known cards* instead of a banner when a client marker exists, so a
transient blip never blanks the list at all. Both are testable via the existing
invariants file.

---

### #4 — USAA and Chase actually collecting the data (not just being *labelled* honestly). **[Still open — classification landed, collection did not.]**

**What Tim wanted.** Real coverage, and for USAA specifically a fixture-first fix:

> "usaa_session_failed: password field never appeared after Next click … let's
> isolate/prove the root cause. and if fixtures can solve this, get it done"
> — 06-29 17:22 (L22304)

**Evidence / current status (verified).**
- USAA: `18098f50d fix(usaa): classify delayed source unavailable login modal
  (#121)` **classifies** the failure ("Can't collect, maintainer code fix
  needed") — it does **not** make USAA log in and collect. Matches the last
  transcript state: "USAA: still not fixed; leave it for now." (07-02, L25826).
- Chase: repeated "completed with known coverage gaps" (07-01 L24684 "Can't
  collect, maintainer code fix needed"; 07-02 L25947 a dropdown-failure fix for
  one gap, but "the connector still did not fully recover your data", L25556).

**Severity: MEDIUM** (real data completeness gap; correctly surfaced as
engineering work, so not a *trust* violation — but still unmet).

**Recommended action.** Fixture-first, per Tim's standing rule: capture a
scrubbed USAA login-page fixture (the `memberId`-then-password two-step modal)
and pin a connector fix against it; same for the Chase dropdown/coverage path.
These are connector-engineering tasks, not owner actions.

---

### #5 — Dead/duplicate connections that "pollute health" should be trivially archivable from where the owner sees them. **[Affordance exists but is buried — partial.]**

**What Tim wanted.**

> "Old duplicate dead connections should be easy to archive/remove without making
> the instance look broken." (agent's own summary of Tim's complaint, 07-02
> 10:12, L25456; Tim's framing repeated re: dondochaka "pollleting health",
> L25442.)

**Current status (verified).** Revoke + Delete server actions exist in
`apps/console/src/app/dashboard/records/[connector]/connection-danger-zone.tsx`,
but only on the **per-connector detail page** ("danger zone"). The owner meets
these dead rows in the **dashboard health / source-attention list**, where the
only offered CTA is "Reconnect" — there is no inline archive/dismiss. So a stale
account keeps showing "Needs you" until the owner navigates into its detail page
and scrolls to a danger zone.

**Severity: MEDIUM.** Directly feeds the #1 frustration (health list keeps
"asking for attention").

**Recommended action.** Add an inline "Archive / Don't collect this anymore"
affordance on the source-attention row for stale/revoked connections, wired to
the existing `revokeConnectionAction` — so a dead account can be cleared from the
health surface without a detail-page safari.

---

### #6 — Local-collector outbox should self-heal (or give one clear recovery step), not require "manual mystery debugging." **[Open.]**

> "the local collector host has to retry/repair its outbox — why doesn't it
> though?" — 06-29 17:24 (L22332)
> "Local collectors are too important to require manual mystery debugging."
> — agent summary of the standing bar, 07-02 (L26184)

**Current status.** No commit found that makes `peregrine Claude Code`
"saved-records-did-not-upload" self-recover; last transcript state still lists it
as an open recovery item. **Severity: MEDIUM.** **Action:** design a bounded
outbox retry/repair loop with a single owner-facing "recover now" step; capture
as OpenSpec.

---

### #7 — Stop the sprawl: "get everything back to `~/code/pdpp` on main." **[Largely resolved; residue remains.]**

> "when are we going to [move] everything back to ~/code/pdpp on main? the sprawl
> is death by a thousand cuts." — 06-29 14:27 (L22106)

**Current status.** Repeatedly re-converged (`~/code/pdpp` returned to clean
`main` at `c69f284ba`, 06-29 L22153; again 07-02 L26521), and a durable cleanup
*standard* was written
(`docs/research/ri-sprawl-closeout-status-2026-07-01.md`). Residue that kept
recurring: root-owned `node_modules`/deploy scratch dirs deferred to "later"/
"when convenient" (06-29 L22153; 07-02 L26522 "one root-owned temp deploy dir
remains"). **Severity: LOW-MEDIUM** (mostly closed; hygiene tail).
**Action:** none required beyond running the recorded narrow cleanup scripts;
the *standard* is the durable win.

---

### #8 — Behavioral bar the agent kept missing: "don't present a partial fix as the outcome." **[Behavioral — the ledger discipline is the fix.]**

This is the through-line behind #1, #2, and the 07-02 "support voice" thread:

> "this is the WRONG kind of message to send as support. it doesn't improve my
> situation at ALL" — 07-02 11:38 (L25814)
> "stop presenting partial fixes as the outcome. I should keep the label clear:
> guardrail done; core bug still open until proven fixed." — agent's own
> corrective, 06-28 07:30 (L20740)

**Severity: HIGH (process).** **Action:** adopt the four-state ledger (#2) as the
standing closeout format so every owner-visible complaint lands in exactly one
honest state and nothing is narrated as "handled."

---

## Top 5 to fix now

1. **Resolve `ChatGPT - dondochaka`** (owner reconnect-or-delete) and design the
   *proactive* auth-recovery loop Tim asked for — not another silent guardrail.
   (#1)
2. **Ship the durable owner-problem closeout ledger** in Tim's four-state format
   — *done in this pass* (companion doc). (#2, #8)
3. **Inline archive affordance** on the source-attention row so dead connections
   stop showing "Needs you". Low-risk; reuses the existing revoke action. (#5)
4. **Root-cause + gate a fix for the "Couldn't refresh your connections"
   banner** (bounded backoff or last-known-cards render). Design-gated. (#3)
5. **Fixture-first USAA/Chase connector fixes** so the data actually collects,
   per Tim's standing fixture rule. (#4)

## Spun out in this pass (this worktree, separate commits)

- **The closeout ledger** (`docs/research/pdpp-ri-owner-problem-closeout-ledger-
  2026-07-03.md`) — the highest-value, zero-runtime-risk gap (#2). Verified
  status per item against `git log`/source.

Everything else is left as a documented recommendation above: each either needs
an owner decision (dondochaka, retry-contract change), a live-instance probe I
cannot run from this shell, or connector-engineering with real fixtures — none of
which is a safe blind edit. That restraint is itself the lesson from #1/#8:
don't churn code to move a number before the defect is proven.
