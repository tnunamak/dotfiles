This confirms the important fact for the "port" option: the current script only does `sendMessage` — no edit/delete support at all. A raw-Bot-API port (option a-prime) is entirely feasible since Telegram's own Bot API has `editMessageText`/`deleteMessage` — nothing here depends on pi-telegram internals. Now I have everything needed for the report.

## What the refactor does

The stash (`stash@{0}`, 11 modified + 2 new files, ~1,400 insertions in `.pi/extensions/approvals/`) rebuilds the Telegram approval channel from a fire-and-forget shell-out into a stateful, reconciling delivery pipeline. **VERIFIED** via `git stash show -p` diffs:

- **`channels/types.ts`**: adds `ApprovalOutcome`/`ApprovalOutcomeKind` (`approved_once`, `approved_30m`, `denied`, `timeout`, `cancelled`, `error`), widens `ApprovalAuthority`/`provenance` to include `stdin`/`abort`, adds `ApprovalChannel.reportOutcome?()`, and adds `policyExplanation`/`remoteLabel` to `ApprovalRequest`.
- **`channels/telegram.ts`** (the crash site): replaces the old `execFileAsync(PROMPT_SCRIPT, ...)` one-shot send with a `TelegramApprovalChannel` that holds a `TelegramDeliveryPort` (send/edit/delete), tracks `pendingHandles` per request id, and adds `reportOutcome()` — which **edits the original Telegram message in place** to show the terminal outcome (approved/denied/timeout/etc.) instead of leaving stale buttons. It handles partial-success/retry/delete-as-last-resort edge cases from a documented `docs/delivery.md` contract (`commit-unknown` results, `partial` handles, idempotent concurrent `reportOutcome` calls via `inFlightReports`).
- **New `core/presentation.ts`** (410 lines, untracked): presumably the safe-text-formatting layer (`formatApprovalRequest`/`formatApprovalOutcome`, redaction via `safeReason`) referenced throughout telegram.ts.
- **`test-telegram.mjs`**: grew by 883 lines — extensive new tests including a "final-gate P0" adversarial-secret-leak suite and a `fakeDelivery()` test double implementing the same `TelegramDeliveryPort` contract.
- **`core/policy.ts`, `core/log.ts`, `index.ts`, `channels/stdin.ts`**: smaller supporting edits (adding `policyExplanation`, wiring `reportOutcome` calls, log fields).

Net goal: turn a "send a prompt and forget it" approval flow into one where the Telegram message itself becomes a durable, editable record of the final decision — a real product improvement, not a cosmetic refactor. **INFERRED**: the motivation (bidirectional message lifecycle management) is sound engineering; it was just built against an API that doesn't exist yet.

## Missing API surface

| Symbol | Exists in 0.20.6? | Equivalent |
|---|---|---|
| `sendTelegramView` | **No** | No public equivalent. Internally `index.ts` builds an analogous primitive from private `lib/replies.ts` (`sendInteractiveMessage`) + `lib/telegram-api.ts` (`sendMessage`), but neither is exported via `package.json` `exports` (only `.`, `./inbound`, `./outbound`, `./updates`, `./commands`, `./sections`, `./status`, `./voice`, `./keyboard`). |
| `editTelegramView` | **No** | Same story: `editInteractiveMessage`/`editTelegramMessageText` exist only inside `index.ts`'s closure, never exported. |
| `deleteTelegramView` | **No** | `deleteTelegramMessage` (wraps Bot API `deleteMessage`) is likewise internal-only. |
| `TelegramDeliveryHandle` / `TelegramDeliveryResult` / `TelegramDeliveryView` types | **No** | No `delivery.ts` file exists in `api/` or `lib/`; `grep -rl Delivery` across `api/`+`lib/`+`index.ts` returns zero literal `Delivery*` symbol hits (only unrelated English-word "delivery" in comments about voice files, config sync, message routing, etc.). |
| `./delivery` export | **No** | Not present in `package.json` `exports` map. **VERIFIED**. |

**VERIFIED**: `outbound.ts`'s only export, `registerTelegramOutboundHandler`, is a *hook-registration* API (a companion extension registers a handler pi-telegram calls when *it* sends outbound text) — not a send/edit/delete primitive a caller can invoke on demand. It cannot serve the Delivery API's role: there's no way to get a handle back, no edit, no delete.

**Conclusion**: the entire public companion-extension surface of 0.20.6 (`sections`, `commands`, `inbound`, `outbound`, `status`, `voice`, `keyboard`) is oriented around *registering into* pi-telegram's own UI (menus, slash commands, status lines) — not around a third party independently sending/editing/deleting arbitrary messages. **The Delivery API doesn't have a hidden equivalent under a different name — the capability itself doesn't exist in the public interop layer at all.**

## Verdict

**(a) modified: port the refactor's design onto raw Bot API calls, bypassing pi-telegram entirely** — same approach the currently-committed code already uses (`send-telegram-approval-prompt` calls the Bot API directly, not through pi-telegram). This is cheaper and lower-risk than either waiting or abandoning:

- **Evidence against (b) "wait for upstream"**: `BACKLOG.md`/`CHANGELOG.md` in the installed 0.20.6 package have zero mentions of a "Delivery API," "Activity And Delivery Extension Platform," or `delivery.ts` — only incidental uses of the English word "delivery" (voice file delivery, guest-mode delivery, markdown delivery path). **VERIFIED** by full-text grep. The Vivid-Fish fork's `dev` branch (`git ls-remote` shows commit `d2ea757`) is at package version **0.6.3** — far *behind* main's 0.20.6, not a preview of a future 0.21.0. **VERIFIED** by cloning it. There is no branch anywhere carrying this API. The stashed code's own doc comments (`"staged, not-yet-deployed status as of 2026-07-15"`) describe an aspiration that was apparently never implemented or was abandoned before landing. Waiting has no defined trigger.
- **Against (c) abandon**: the stash's actual value — the reconciling state machine (`pendingHandles`, `reportOutcome`, partial/retry/delete-as-last-resort handling, redaction tests) — depends only on *some* send/edit/delete transport, not specifically on pi-telegram's package internals. The current shell script already proves raw Bot API access works fine for `sendMessage`; `editMessageText`/`deleteMessage` are equally simple, well-documented Bot API methods. Throwing away ~1,400 lines of already-designed reconciliation logic and tests to redo it later would be wasteful.
- Since Vivid-Fish is Tim's own org, shipping the Delivery API upstream *first* was considered as an option per the task brief, but it's the more expensive path here: it requires designing and landing a new public package surface (naming, `commit-unknown`/`partial` semantics, docs) before daisy's approvals extension can even compile — versus directly implementing the same three operations (send/edit/delete) against the Bot API that daisy already talks to successfully today.

## Plan

1. In `channels/telegram.ts`, delete the `import { ... } from "../../../npm/node_modules/@llblab/pi-telegram/api/delivery.ts"` block and the `TelegramDeliveryPort`/`liveDelivery` construction that wraps it.
2. Define a local `TelegramDeliveryPort`-shaped interface (keep the name/shape — it's a good abstraction) backed by three small functions that call the Telegram Bot API directly via `fetch`, using the same token/chat-id resolution the existing `scripts/send-telegram-approval-prompt` uses (`TELEGRAM_BOT_TOKEN` env + `allowedUserId` from `.pi/agent/telegram.json`):
   - `sendTelegramView(view, opts)` → `POST https://api.telegram.org/bot<token>/sendMessage` with `reply_markup` built from `view.replyMarkup`; map the response to `{ ok: true, value: { chatId, messageId } }` / `{ ok: false, reason, message, partial? }`.
   - `editTelegramView(handle, view)` → `POST .../editMessageText` (or `editMessageReplyMarkup` if only buttons change) keyed by `{chat_id, message_id}` from the handle.
   - `deleteTelegramView(handle)` → `POST .../deleteMessage`.
3. Replace the `TelegramDeliveryResult<T>` type (currently imported) with a local equivalent (`{ ok: true, value: T } | { ok: false, reason: string, message: string, partial?: T }`) — the stash's own logic (`reconcileToTerminalView`, `rememberPartial`) only needs `ok`/`partial`/failure-message shape, all reproducible without the upstream package.
4. Keep the entire rest of `telegram.ts` (the class body: `pendingHandles`, `inFlightReports`, `reportOutcomeOnce`, `reconcileToTerminalView`, `deleteBestEffort`, `unreconciled`) — it's transport-agnostic and doesn't reference pi-telegram beyond the deleted import.
5. Update `test-telegram.mjs`'s `fakeDelivery()` to implement the new local port interface (likely a no-op rename since it already fakes the same three methods/shapes).
6. Adjust `channels/telegram.ts`'s module doc comment and `README.md` (already-diffed in the stash) to drop references to "pi-telegram 0.21.0", "`@llblab/pi-telegram/delivery`", and `docs/delivery.md` — replace with a short note that this channel talks to the Bot API directly, same as `scripts/send-telegram-approval-prompt` did.
7. Pop the stash into a scratch branch/worktree (not main) to do this work, run `test-telegram.mjs`/`test-telegram-bun.test.ts`, and manually verify one real approval round-trip (send → approve → confirm message edits in place) before merging — don't restore onto `main`/live daisy until verified.

## Risks

- **Bot API detail parity** (**INFERRED**): pi-telegram's internal `lib/telegram-api.ts` likely has retry/rate-limit/error-normalization logic that a hand-rolled `fetch` wrapper won't have for free. Keep the new port minimal and let the existing `reconcileToTerminalView`/`deleteBestEffort` bounded-retry logic in `telegram.ts` absorb transient failures, same as it's already designed to.
- **Two independent Telegram senders** (**INFERRED**, worth confirming before merging): daisy will now have both pi-telegram's own message pipeline (interactive replies, menus) and this approvals channel talking to the Bot API in parallel outside pi-telegram's lock/thread-ownership machinery (`lockRuntime`, `messageOwnershipStore` in `index.ts`). The current shell-script approach already does this today without apparent issue, so this is likely fine, but worth a quick sanity check that concurrent sends don't race Telegram's per-chat rate limits under heavy approval traffic.
- **Scope creep temptation**: it would be easy to also try to route this through pi-telegram's `outbound` handler registry to "integrate properly." Resist that — the outbound handler system is for pi-telegram-initiated sends, not a fit for a caller-driven send/edit/delete lifecycle, and re-attempting to force-fit it is how the previous 0.21.0-dependent design happened in the first place.
- I have not run `git stash show -p` on `index.ts`, `core/policy.ts`, `core/log.ts`, or `channels/stdin.ts` diffs in full — only the stat and grep hits. There may be additional supporting changes in those files worth reviewing before starting the port (**flagged, not verified**).

Stash left untouched (`stash@{0}` still present, not popped/applied); no files edited; daisy left running on committed HEAD.
